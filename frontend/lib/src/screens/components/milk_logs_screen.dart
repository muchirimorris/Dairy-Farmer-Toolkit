import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:dairy_farmer_toolkit/src/navigation/main_layout.dart';
import 'package:intl/intl.dart';

import '../../models/milk_log_model.dart';
import '../../models/animal_model.dart';
import '../../repositories/milk_log_repository.dart';
import '../../repositories/animal_repository.dart';

class MilkLogsScreen extends StatefulWidget {
  const MilkLogsScreen({super.key});

  @override
  State<MilkLogsScreen> createState() => _MilkLogsScreenState();
}

class _MilkLogsScreenState extends State<MilkLogsScreen> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final MilkLogRepository _milkLogRepo = MilkLogRepository();
  final AnimalRepository _animalRepo = AnimalRepository();

  String? _selectedAnimalId;
  String? _selectedAnimalName;
  List<AnimalModel> _animals = [];
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isInitialized = false;

  late Stream<List<MilkLogModel>> _milkLogsStream;
  late Stream<List<AnimalModel>> _animalsStream;
  // ignore: cancel_subscriptions
  dynamic _animalsSub;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      _milkLogRepo.syncMilkLogs(user.id);
      _animalRepo.syncAnimals(user.id);
      _milkLogsStream = _milkLogRepo
          .getMilkLogsStream(user.id)
          .asBroadcastStream();
      _animalsStream = _animalRepo
          .getAnimalsStream(user.id)
          .asBroadcastStream();
      _fetchRegisteredAnimals();
    }
  }

  @override
  void dispose() {
    _animalsSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _updateDateTimeControllers();
      _isInitialized = true;
    }
  }

  void _updateDateTimeControllers() {
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _timeController.text = _selectedTime.format(context);
  }

  void _fetchRegisteredAnimals() {
    _animalsSub = _animalsStream.listen((animals) {
      if (mounted) {
        setState(() {
          _animals = animals;
        });
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDateTimeControllers();
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _updateDateTimeControllers();
      });
    }
  }

  void _resetForm() {
    _quantityController.clear();
    _selectedAnimalId = null;
    _selectedAnimalName = null;
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _updateDateTimeControllers();
  }

  void _openAddLogForm(
    BuildContext context, {
    String? docId,
    MilkLogModel? currentData,
  }) {
    TextEditingController quantityController = TextEditingController();
    String? selectedAnimalId;
    String? selectedAnimalName;
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    if (currentData != null) {
      selectedAnimalId = currentData.animalId;
      selectedAnimalName = currentData.animalName;
      quantityController.text = currentData.quantity.toString();

      final date = currentData.date;
      selectedDate = date;
      selectedTime = TimeOfDay.fromDateTime(date);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          TextEditingController dateController = TextEditingController(
            text: DateFormat('yyyy-MM-dd').format(selectedDate),
          );
          TextEditingController timeController = TextEditingController(
            text: selectedTime.format(context),
          );

          Future<void> selectDate() async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null && picked != selectedDate) {
              setModalState(() {
                selectedDate = picked;
                dateController.text = DateFormat(
                  'yyyy-MM-dd',
                ).format(selectedDate);
              });
            }
          }

          Future<void> selectTime() async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: selectedTime,
            );
            if (picked != null && picked != selectedTime) {
              setModalState(() {
                selectedTime = picked;
                timeController.text = selectedTime.format(context);
              });
            }
          }

          Future<void> saveMilkLog() async {
            if (selectedAnimalId == null || quantityController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Please fill all required fields"),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final user = Provider.of<AuthService>(context, listen: false).currentUser;
            if (user == null) return;

            final logDateTime = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            );

            final logModel = MilkLogModel(
              id: docId ?? '',
              animalId: selectedAnimalId!,
              animalName: selectedAnimalName ?? "Unknown",
              farmerId: user.id,
              quantity: double.tryParse(quantityController.text) ?? 0,
              date: logDateTime,
            );

            try {
              if (docId == null) {
                await _milkLogRepo.addMilkLog(logModel);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("✅ Milk log saved for $selectedAnimalName"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                await _milkLogRepo.updateMilkLog(logModel);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("✅ Milk log updated for $selectedAnimalName"),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              }

              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("❌ Error saving milk log: $e"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    docId == null ? "➕ Add Milk Log" : "✏️ Edit Milk Log",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),

                  StreamBuilder<List<AnimalModel>>(
                    stream: _animalsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Loading animals...",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.pets),
                          ),
                          items: const [],
                          onChanged: null,
                        );
                      }

                      if (snapshot.hasError) {
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Error loading animals",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.error),
                          ),
                          items: const [],
                          onChanged: null,
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "No animals found",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.warning),
                          ),
                          items: const [],
                          onChanged: null,
                        );
                      }

                      final animals = snapshot.data!;

                      final milkingAnimals = animals
                          .where(
                            (animal) => (animal.productionStatus)
                                .toLowerCase()
                                .contains("milking"),
                          )
                          .toList();

                      if (milkingAnimals.isEmpty) {
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "No milking animals found",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.warning),
                          ),
                          items: const [],
                          onChanged: null,
                        );
                      }

                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Select Animal *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pets),
                        ),
                        initialValue: selectedAnimalId,
                        items: milkingAnimals.map<DropdownMenuItem<String>>((
                          animal,
                        ) {
                          final animalName = animal.name;
                          final tagNumber = animal.tagNumber;
                          final hasTagNumber = tagNumber.isNotEmpty;

                          return DropdownMenuItem<String>(
                            value: animal.id,
                            child: SizedBox(
                              height: 40,
                              child: hasTagNumber
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                animalName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                "Tag: $tagNumber",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        animalName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? val) {
                          setModalState(() {
                            selectedAnimalId = val;
                            if (val != null) {
                              final selectedAnimal = milkingAnimals.firstWhere(
                                (a) => a.id == val,
                              );
                              selectedAnimalName = selectedAnimal.name;
                            }
                          });
                        },
                        selectedItemBuilder: (BuildContext context) {
                          return milkingAnimals.map<Widget>((animal) {
                            final animalName = animal.name;
                            final tagNumber = animal.tagNumber;
                            final hasTagNumber = tagNumber.isNotEmpty;

                            return Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                hasTagNumber
                                    ? "$animalName (Tag: $tagNumber)"
                                    : animalName,
                                style: const TextStyle(fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Milk Quantity (Liters) *",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_drink),
                      hintText: "e.g., 12.5",
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dateController,
                          decoration: const InputDecoration(
                            labelText: "Date",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () => selectDate(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: timeController,
                          decoration: const InputDecoration(
                            labelText: "Time",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          readOnly: true,
                          onTap: () => selectTime(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: saveMilkLog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            docId == null ? "Save Log" : "Update Log",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _calculateDailyTotal(List<MilkLogModel> logs) {
    final today = DateTime.now();
    return logs
        .where((log) {
          final date = log.date;
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        })
        .fold(0.0, (sum, log) => sum + log.quantity);
  }

  double _calculateWeeklyTotal(List<MilkLogModel> logs) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return logs
        .where((log) {
          final date = log.date;
          return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              date.isBefore(now.add(const Duration(days: 1)));
        })
        .fold(0.0, (sum, log) => sum + log.quantity);
  }

  double _calculateMonthlyTotal(List<MilkLogModel> logs) {
    final now = DateTime.now();
    return logs
        .where((log) {
          final date = log.date;
          return date.month == now.month && date.year == now.year;
        })
        .fold(0.0, (sum, log) => sum + log.quantity);
  }

  Widget _buildSummaryCard(
    String title,
    double value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${value.toStringAsFixed(1)} L",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    return MainLayout(
      selectedIndex: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Text(
            "🥛 Milk Production",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.bar_chart,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Analytics feature coming soon!"),
                  ),
                );
              },
              tooltip: "View Analytics",
            ),
          ],
        ),
        body: user == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Please log in to view milk logs",
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : StreamBuilder<List<MilkLogModel>>(
                stream: _milkLogsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Error loading milk logs: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final logs = snapshot.data!;

                  final dailyTotal = _calculateDailyTotal(logs);
                  final weeklyTotal = _calculateWeeklyTotal(logs);
                  final monthlyTotal = _calculateMonthlyTotal(logs);

                  final Map<String, List<MilkLogModel>> groupedLogs = {};
                  for (var log in logs) {
                    final animalName = log.animalName;
                    groupedLogs.putIfAbsent(animalName, () => []).add(log);
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          _buildSummaryCard(
                            "Today",
                            dailyTotal,
                            Icons.today,
                            Colors.green,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            "This Week",
                            weeklyTotal,
                            Icons.calendar_view_week,
                            Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            "This Month",
                            monthlyTotal,
                            Icons.calendar_today,
                            Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "📈 Quick Stats",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildStatRow(
                                "Total Animals Milking",
                                _animals
                                    .where(
                                      (a) => (a.productionStatus)
                                          .toLowerCase()
                                          .contains("milking"),
                                    )
                                    .length
                                    .toString(),
                              ),
                              _buildStatRow(
                                "Total Logs Today",
                                logs
                                    .where((log) {
                                      final date = log.date;
                                      final today = DateTime.now();
                                      return date.year == today.year &&
                                          date.month == today.month &&
                                          date.day == today.day;
                                    })
                                    .length
                                    .toString(),
                              ),
                              _buildStatRow(
                                "Average Daily",
                                "${(dailyTotal / 7).toStringAsFixed(1)} L",
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "🐄 Animal Milk Records",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...groupedLogs.entries.map((entry) {
                        final animalName = entry.key;
                        final animalLogs = entry.value;
                        final totalAnimalMilk = animalLogs.fold(
                          0.0,
                          (sum, log) => sum + log.quantity,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ExpansionTile(
                            leading: const Icon(
                              Icons.pets,
                              color: Colors.green,
                            ),
                            title: Text(
                              animalName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              "Total: ${totalAnimalMilk.toStringAsFixed(1)} L • ${animalLogs.length} records",
                              style: const TextStyle(fontSize: 12),
                            ),
                            children: animalLogs.map((log) {
                              final quantity = log.quantity.toString();
                              final date = log.date;

                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.local_drink,
                                    color: Colors.blueAccent,
                                  ),
                                  title: Text(
                                    "$quantity Liters",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    DateFormat(
                                      "MMM dd, yyyy 'at' hh:mm a",
                                    ).format(date),
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == "edit") {
                                        _openAddLogForm(
                                          context,
                                          docId: log.id,
                                          currentData: log,
                                        );
                                      } else if (value == "delete") {
                                        await _showDeleteConfirmation(
                                          context,
                                          log.id,
                                          animalName,
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: "edit",
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 20),
                                            SizedBox(width: 8),
                                            Text("Edit"),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: "delete",
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Delete",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openAddLogForm(context),
          backgroundColor: Colors.green,
          child: const Icon(Icons.add, size: 36, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_drink,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            "No Milk Logs Yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the + button to add your first milk log",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _openAddLogForm(context),
            icon: const Icon(Icons.add),
            label: const Text("Add First Log"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    String docId,
    String animalName,
  ) async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Milk Log"),
        content: Text(
          "Are you sure you want to delete this milk log for $animalName?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _milkLogRepo.deleteMilkLog(docId);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Milk log for $animalName deleted"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
