import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dairy_farmer_toolkit/src/navigation/main_layout.dart';
import 'package:intl/intl.dart';

class MilkLogsScreen extends StatefulWidget {
  const MilkLogsScreen({super.key});

  @override
  State<MilkLogsScreen> createState() => _MilkLogsScreenState();
}

class _MilkLogsScreenState extends State<MilkLogsScreen> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String? _selectedAnimalId;
  String? _selectedAnimalName;
  List<Map<String, dynamic>> _animals = [];
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _fetchRegisteredAnimals();
    // Don't call _updateDateTimeControllers here - wait for context
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
    _timeController.text = _selectedTime.format(context); // Now context is available
  }

  Future<void> _fetchRegisteredAnimals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection("animals")
        .where("farmerId", isEqualTo: user.uid)
        .get();

    setState(() {
      _animals = snapshot.docs
          .map((doc) => {
                "id": doc.id,
                "name": doc['name'] as String,
                "tagNumber": doc['tagNumber'] ?? 'No Tag',
                "productionStatus": doc['productionStatus'] ?? 'Unknown',
              })
          .toList();
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

  Future<void> _saveMilkLog({String? docId}) async {
    if (_selectedAnimalId == null || _quantityController.text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Combine date and time
    final logDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final logData = {
      "animalId": _selectedAnimalId,
      "animalName": _selectedAnimalName ?? "Unknown",
      "quantity": double.tryParse(_quantityController.text) ?? 0,
      "date": logDateTime,
      "timestamp": FieldValue.serverTimestamp(),
    };

    final logsRef = FirebaseFirestore.instance
        .collection("farmers")
        .doc(user.uid)
        .collection("milk_logs");

    try {
      if (docId == null) {
        await logsRef.add(logData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Milk log saved for $_selectedAnimalName"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await logsRef.doc(docId).update(logData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Milk log updated for $_selectedAnimalName"),
            backgroundColor: Colors.blue,
          ),
        );
      }

      _resetForm();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error saving milk log: $e"),
          backgroundColor: Colors.red,
        ),
      );
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

  void _openAddLogForm(BuildContext context,
      {String? docId, Map<String, dynamic>? currentData}) {
    if (currentData != null) {
      _selectedAnimalId = currentData["animalId"];
      _selectedAnimalName = currentData["animalName"];
      _quantityController.text = currentData["quantity"].toString();
      
      final date = (currentData["date"] as Timestamp).toDate();
      _selectedDate = date;
      _selectedTime = TimeOfDay.fromDateTime(date);
      _updateDateTimeControllers();
    } else {
      _resetForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SingleChildScrollView(
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

              // Animal Selection
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Select Animal *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                value: _selectedAnimalId,
                items: _buildAnimalDropdownItems(),
                onChanged: (String? val) {
                  setState(() {
                    _selectedAnimalId = val;
                    if (val != null) {
                      final selectedAnimal = _animals.firstWhere((a) => a["id"] == val);
                      _selectedAnimalName = selectedAnimal["name"].toString();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Quantity Input
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Milk Quantity (Liters) *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_drink),
                  hintText: "e.g., 12.5",
                ),
              ),
              const SizedBox(height: 16),

              // Date and Time Selection
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: "Date",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        labelText: "Time",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: () => _selectTime(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _resetForm();
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
                      onPressed: () {
                        if (_selectedAnimalId == null || _quantityController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please fill all required fields"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        _saveMilkLog(docId: docId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        docId == null ? "Save Log" : "Update Log",
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildAnimalDropdownItems() {
    // Filter only milking animals
    final milkingAnimals = _animals.where((animal) => 
        (animal["productionStatus"] ?? "").toString().toLowerCase() == "milking");

    return milkingAnimals.map<DropdownMenuItem<String>>((animal) {
      return DropdownMenuItem<String>(
        value: animal["id"],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(animal["name"] ?? "Unknown"),
            Text(
              "Tag: ${animal["tagNumber"]}",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // 🟢 Helpers to calculate totals
  double _calculateDailyTotal(List<QueryDocumentSnapshot> logs) {
    final today = DateTime.now();
    return logs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .where((data) {
          final date = (data["date"] as Timestamp).toDate();
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        })
        .fold(0.0, (sum, data) => sum + (data["quantity"] as num).toDouble());
  }

  double _calculateWeeklyTotal(List<QueryDocumentSnapshot> logs) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return logs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .where((data) {
          final date = (data["date"] as Timestamp).toDate();
          return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              date.isBefore(now.add(const Duration(days: 1)));
        })
        .fold(0.0, (sum, data) => sum + (data["quantity"] as num).toDouble());
  }

  double _calculateMonthlyTotal(List<QueryDocumentSnapshot> logs) {
    final now = DateTime.now();
    return logs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .where((data) {
          final date = (data["date"] as Timestamp).toDate();
          return date.month == now.month && date.year == now.year;
        })
        .fold(0.0, (sum, data) => sum + (data["quantity"] as num).toDouble());
  }

  Widget _buildSummaryCard(String title, double value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
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
    final user = FirebaseAuth.instance.currentUser;

    return MainLayout(
      selectedIndex: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[700],
          elevation: 0,
          title: const Text(
            "🥛 Milk Production",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Analytics feature coming soon!")),
                );
              },
              tooltip: "View Analytics",
            ),
          ],
        ),
        body: user == null
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "Please log in to view milk logs",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("farmers")
                    .doc(user.uid)
                    .collection("milk_logs")
                    .orderBy("date", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
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

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final logs = snapshot.data!.docs;

                  // ✅ Calculate totals
                  final dailyTotal = _calculateDailyTotal(logs);
                  final weeklyTotal = _calculateWeeklyTotal(logs);
                  final monthlyTotal = _calculateMonthlyTotal(logs);

                  // ✅ Group logs by animal
                  final Map<String, List<QueryDocumentSnapshot>> groupedLogs = {};
                  for (var doc in logs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final animalName = data["animalName"] ?? "Unknown Animal";
                    groupedLogs.putIfAbsent(animalName, () => []).add(doc);
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Summary Cards
                      Row(
                        children: [
                          _buildSummaryCard("Today", dailyTotal, Icons.today, Colors.green),
                          const SizedBox(width: 12),
                          _buildSummaryCard("This Week", weeklyTotal, Icons.calendar_view_week, Colors.blue),
                          const SizedBox(width: 12),
                          _buildSummaryCard("This Month", monthlyTotal, Icons.calendar_today, Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Quick Stats
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
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
                              _buildStatRow("Total Animals Milking", 
                                  _animals.where((a) => (a["productionStatus"] ?? "").toString().toLowerCase() == "milking").length.toString()),
                              _buildStatRow("Total Logs Today", 
                                  logs.where((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final date = (data["date"] as Timestamp).toDate();
                                    final today = DateTime.now();
                                    return date.year == today.year &&
                                        date.month == today.month &&
                                        date.day == today.day;
                                  }).length.toString()),
                              _buildStatRow("Average Daily", "${(dailyTotal / 7).toStringAsFixed(1)} L"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Animal logs
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
                            0.0, (sum, doc) => sum + ((doc.data() as Map<String, dynamic>)["quantity"] as num).toDouble());

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 3,
                          child: ExpansionTile(
                            leading: const Icon(Icons.pets, color: Colors.green),
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
                            children: animalLogs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final quantity = data["quantity"].toString();
                              final date = (data["date"] as Timestamp).toDate();

                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.grey.shade200),
                                  ),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.local_drink, color: Colors.blueAccent),
                                  title: Text(
                                    "$quantity Liters",
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(
                                    DateFormat("MMM dd, yyyy 'at' hh:mm a").format(date),
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == "edit") {
                                        _openAddLogForm(context,
                                            docId: doc.id, currentData: data);
                                      } else if (value == "delete") {
                                        await _showDeleteConfirmation(context, doc.id, animalName);
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
                                            Icon(Icons.delete, size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text("Delete", style: TextStyle(color: Colors.red)),
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
          Icon(Icons.local_drink, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No Milk Logs Yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tap the + button to add your first milk log",
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _openAddLogForm(context),
            icon: const Icon(Icons.add),
            label: const Text("Add First Log"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
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
          Text(value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, String docId, String animalName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Milk Log"),
        content: Text("Are you sure you want to delete this milk log for $animalName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("farmers")
                  .doc(user.uid)
                  .collection("milk_logs")
                  .doc(docId)
                  .delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Milk log for $animalName deleted"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}