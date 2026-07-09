import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BreedingScreen extends StatefulWidget {
  const BreedingScreen({super.key});

  @override
  State<BreedingScreen> createState() => _BreedingScreenState();
}

class _BreedingScreenState extends State<BreedingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedAnimalId;
  String? _selectedAnimalName;
  String? _selectedEventType;
  String? _selectedOutcome;

  // Event types for dropdown
  final List<String> _eventTypes = [
    'Heat Detection',
    'Insemination (AI)',
    'Natural Mating',
    'Pregnancy Check',
    'Calving',
    'Abortion',
    'Dry-off',
    'Vet Check',
    'Other',
  ];

  // Outcome types for AI events
  final List<String> _outcomeTypes = [
    'Pending',
    'Pregnancy Confirmed',
    'Failed',
    'Aborted',
  ];

  User? get user => FirebaseAuth.instance.currentUser;

  /// Calculate predicted dates based on event type
  Map<String, dynamic> _calculatePredictions(
    String eventType,
    DateTime eventDate,
  ) {
    final predictions = <String, dynamic>{};

    if (eventType.toLowerCase().contains('insemination') ||
        eventType.toLowerCase().contains('ai') ||
        eventType.toLowerCase().contains('mating')) {
      // Calving prediction: +280 days from AI/Mating
      final calvingDate = eventDate.add(const Duration(days: 280));
      predictions['predictedCalving'] = calvingDate;

      // Pregnancy check reminder: +45 days
      final pregnancyCheckDate = eventDate.add(const Duration(days: 45));
      predictions['pregnancyCheckDue'] = pregnancyCheckDate;

      // Early pregnancy check: +21 days
      final earlyCheckDate = eventDate.add(const Duration(days: 21));
      predictions['earlyPregnancyCheck'] = earlyCheckDate;
    }

    if (eventType.toLowerCase().contains('heat')) {
      // Next heat prediction: +21 days from current heat
      final nextHeatDate = eventDate.add(const Duration(days: 21));
      predictions['predictedNextHeat'] = nextHeatDate;
    }

    return predictions;
  }

  /// Save record to Firestore with predictions
  Future<void> _saveBreedingRecord() async {
    if (user == null) return;

    if (_formKey.currentState!.validate() &&
        _selectedAnimalId != null &&
        _selectedDate != null &&
        _selectedEventType != null) {
      final predictions = _calculatePredictions(
        _selectedEventType!,
        _selectedDate!,
      );

      final recordData = {
        "animalId": _selectedAnimalId,
        "animalName": _selectedAnimalName ?? "Unknown",
        "eventType": _selectedEventType,
        "outcome": _selectedOutcome ?? 'Pending',
        "date": _selectedDate,
        "notes": _notesController.text.trim(),
        "timestamp": FieldValue.serverTimestamp(),
        ...predictions,
      };

      await FirebaseFirestore.instance
          .collection("farmers")
          .doc(user!.uid)
          .collection("breeding_records")
          .add(recordData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Breeding record saved with smart predictions"),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      _resetForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Reset form
  void _resetForm() {
    _notesController.clear();
    setState(() {
      _selectedAnimalId = null;
      _selectedAnimalName = null;
      _selectedDate = null;
      _selectedEventType = null;
      _selectedOutcome = null;
    });
  }

  /// Pick date
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Update outcome of existing record
  Future<void> _updateOutcome(String docId, String newOutcome) async {
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("farmers")
        .doc(user!.uid)
        .collection("breeding_records")
        .doc(docId)
        .update({
          "outcome": newOutcome,
          "updatedAt": FieldValue.serverTimestamp(),
        });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Outcome updated to: $newOutcome'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Delete breeding record
  Future<void> _deleteRecord(String docId, String animalName) async {
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Breeding Record"),
        content: Text(
          "Are you sure you want to delete this breeding record for $animalName?",
        ),
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
                  .doc(user!.uid)
                  .collection("breeding_records")
                  .doc(docId)
                  .delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Breeding record for $animalName deleted"),
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

  /// Get upcoming reminders
  Widget _buildUpcomingReminders(QuerySnapshot snapshot) {
    final now = DateTime.now();
    final upcomingRecords = <QueryDocumentSnapshot>[];

    for (final doc in snapshot.docs) {
      final record = doc.data() as Map<String, dynamic>;

      // Check for upcoming calving
      if (record.containsKey('predictedCalving')) {
        final calvingDate = (record['predictedCalving'] as Timestamp).toDate();
        final daysUntilCalving = calvingDate.difference(now).inDays;
        if (daysUntilCalving >= 0 && daysUntilCalving <= 30) {
          upcomingRecords.add(doc);
        }
      }

      // Check for upcoming heat
      if (record.containsKey('predictedNextHeat')) {
        final heatDate = (record['predictedNextHeat'] as Timestamp).toDate();
        final daysUntilHeat = heatDate.difference(now).inDays;
        if (daysUntilHeat >= 0 && daysUntilHeat <= 7) {
          upcomingRecords.add(doc);
        }
      }

      // Check for pregnancy check due
      if (record.containsKey('pregnancyCheckDue')) {
        final checkDate = (record['pregnancyCheckDue'] as Timestamp).toDate();
        final daysUntilCheck = checkDate.difference(now).inDays;
        if (daysUntilCheck >= 0 && daysUntilCheck <= 14) {
          upcomingRecords.add(doc);
        }
      }

      // Check for early pregnancy check
      if (record.containsKey('earlyPregnancyCheck')) {
        final earlyCheckDate = (record['earlyPregnancyCheck'] as Timestamp)
            .toDate();
        final daysUntilEarlyCheck = earlyCheckDate.difference(now).inDays;
        if (daysUntilEarlyCheck >= 0 && daysUntilEarlyCheck <= 7) {
          upcomingRecords.add(doc);
        }
      }
    }

    if (upcomingRecords.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.notifications_none,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                "No Upcoming Reminders",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "All breeding events are on track!",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "🔔 Smart Reminders",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Your breeding assistant will remind you of important events:",
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...upcomingRecords.map((doc) {
              final record = doc.data() as Map<String, dynamic>;
              final animalName = record["animalName"] ?? "Unknown Animal";

              List<Widget> reminders = [];

              // Calving reminder
              if (record.containsKey('predictedCalving')) {
                final calvingDate = (record['predictedCalving'] as Timestamp)
                    .toDate();
                final daysUntilCalving = calvingDate.difference(now).inDays;

                if (daysUntilCalving >= 0 && daysUntilCalving <= 30) {
                  String urgency = daysUntilCalving <= 7
                      ? "🚨 URGENT"
                      : "📅 Upcoming";
                  reminders.add(
                    _buildReminderCard(
                      icon: Icons.pregnant_woman,
                      color: daysUntilCalving <= 7 ? Colors.red : Colors.green,
                      title: "$urgency: Expected Calving",
                      subtitle:
                          "$animalName - ${DateFormat('MMM dd, yyyy').format(calvingDate)} (in $daysUntilCalving days)",
                      type: "Calving",
                    ),
                  );
                }
              }

              // Heat reminder
              if (record.containsKey('predictedNextHeat')) {
                final heatDate = (record['predictedNextHeat'] as Timestamp)
                    .toDate();
                final daysUntilHeat = heatDate.difference(now).inDays;

                if (daysUntilHeat >= 0 && daysUntilHeat <= 7) {
                  reminders.add(
                    _buildReminderCard(
                      icon: Icons.favorite,
                      color: Colors.orange,
                      title: "Next Heat Expected",
                      subtitle:
                          "$animalName - ${DateFormat('MMM dd, yyyy').format(heatDate)} (in $daysUntilHeat days)",
                      type: "Heat",
                    ),
                  );
                }
              }

              // Pregnancy check reminder
              if (record.containsKey('pregnancyCheckDue')) {
                final checkDate = (record['pregnancyCheckDue'] as Timestamp)
                    .toDate();
                final daysUntilCheck = checkDate.difference(now).inDays;

                if (daysUntilCheck >= 0 && daysUntilCheck <= 14) {
                  reminders.add(
                    _buildReminderCard(
                      icon: Icons.medical_services,
                      color: Colors.blue,
                      title: "Pregnancy Check Due",
                      subtitle:
                          "$animalName - ${DateFormat('MMM dd, yyyy').format(checkDate)} (in $daysUntilCheck days)",
                      type: "Check",
                    ),
                  );
                }
              }

              // Early pregnancy check reminder
              if (record.containsKey('earlyPregnancyCheck')) {
                final earlyCheckDate =
                    (record['earlyPregnancyCheck'] as Timestamp).toDate();
                final daysUntilEarlyCheck = earlyCheckDate
                    .difference(now)
                    .inDays;

                if (daysUntilEarlyCheck >= 0 && daysUntilEarlyCheck <= 7) {
                  reminders.add(
                    _buildReminderCard(
                      icon: Icons.health_and_safety,
                      color: Colors.purple,
                      title: "Early Pregnancy Check",
                      subtitle:
                          "$animalName - ${DateFormat('MMM dd, yyyy').format(earlyCheckDate)} (in $daysUntilEarlyCheck days)",
                      type: "Early Check",
                    ),
                  );
                }
              }

              return Column(
                children: [
                  ...reminders,
                  if (upcomingRecords.indexOf(doc) !=
                          upcomingRecords.length - 1 &&
                      reminders.isNotEmpty)
                    const SizedBox(height: 8),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String type,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build analytics section
  Widget _buildAnalyticsSection(QuerySnapshot snapshot) {
    final records = snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    // Calculate basic analytics
    final heatEvents = records
        .where((r) => r['eventType'] == 'Heat Detection')
        .length;
    final aiEvents = records
        .where((r) => r['eventType'] == 'Insemination (AI)')
        .length;
    final successfulPregnancies = records
        .where((r) => r['outcome'] == 'Pregnancy Confirmed')
        .length;
    final calvingEvents = records
        .where((r) => r['eventType'] == 'Calving')
        .length;

    final successRate = aiEvents > 0
        ? (successfulPregnancies / aiEvents * 100)
        : 0;
    final avgCalvingInterval = _calculateAverageCalvingInterval(records);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  "📊 Breeding Analytics",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildAnalyticsCard(
                  title: "Heat Events",
                  value: heatEvents.toString(),
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildAnalyticsCard(
                  title: "AI Events",
                  value: aiEvents.toString(),
                  color: Colors.pink,
                ),
                const SizedBox(width: 8),
                _buildAnalyticsCard(
                  title: "Success Rate",
                  value: "${successRate.toStringAsFixed(1)}%",
                  color: successRate >= 50 ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildAnalyticsCard(
                  title: "Calvings",
                  value: calvingEvents.toString(),
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildAnalyticsCard(
                  title: "Avg Interval",
                  value: avgCalvingInterval > 0
                      ? "${avgCalvingInterval.toStringAsFixed(0)} days"
                      : "N/A",
                  color: Colors.purple,
                ),
                const SizedBox(width: 8),
                _buildAnalyticsCard(
                  title: "Active Preg",
                  value: successfulPregnancies.toString(),
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAverageCalvingInterval(List<Map<String, dynamic>> records) {
    final calvingEvents = records
        .where((r) => r['eventType'] == 'Calving')
        .toList();
    if (calvingEvents.length < 2) return 0;

    // Sort calving events by date
    calvingEvents.sort(
      (a, b) => (a['date'] as Timestamp).compareTo(b['date'] as Timestamp),
    );

    double totalInterval = 0;
    int intervalCount = 0;

    for (int i = 1; i < calvingEvents.length; i++) {
      final previousDate = (calvingEvents[i - 1]['date'] as Timestamp).toDate();
      final currentDate = (calvingEvents[i]['date'] as Timestamp).toDate();
      final interval = currentDate.difference(previousDate).inDays;
      totalInterval += interval;
      intervalCount++;
    }

    return totalInterval / intervalCount;
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🐄 Smart Breeding Assistant"),
        backgroundColor: Colors.purple[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Detailed analytics with charts coming soon!"),
                ),
              );
            },
            tooltip: "View Detailed Analytics",
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
                    "Please log in to access smart breeding features",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upcoming Reminders Section
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("farmers")
                        .doc(user!.uid)
                        .collection("breeding_records")
                        .orderBy("date", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        return Column(
                          children: [
                            _buildUpcomingReminders(snapshot.data!),
                            const SizedBox(height: 20),
                          ],
                        );
                      }
                      return const SizedBox();
                    },
                  ),

                  // Analytics Section
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("farmers")
                        .doc(user!.uid)
                        .collection("breeding_records")
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        return Column(
                          children: [
                            _buildAnalyticsSection(snapshot.data!),
                            const SizedBox(height: 20),
                          ],
                        );
                      }
                      return const SizedBox();
                    },
                  ),

                  // Add Breeding Record Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "➕ Add Breeding Record",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "🤖 Smart predictions: AI/Mating → Calving (+280d), Pregnancy Check (+45d)\nHeat → Next Heat (+21d)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Animal Selection Dropdown
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection("animals")
                                      .where("farmerId", isEqualTo: user!.uid)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
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

                                    if (!snapshot.hasData ||
                                        snapshot.data!.docs.isEmpty) {
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

                                    final animals = snapshot.data!.docs.map((
                                      doc,
                                    ) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final tagNumber = data['tagNumber'];
                                      final hasTagNumber =
                                          tagNumber != null &&
                                          tagNumber
                                              .toString()
                                              .trim()
                                              .isNotEmpty;

                                      return {
                                        "id": doc.id,
                                        "name":
                                            data['name'] as String? ??
                                            'Unknown',
                                        "tagNumber": hasTagNumber
                                            ? tagNumber.toString().trim()
                                            : null,
                                        "gender":
                                            data['gender'] as String? ??
                                            'Unknown',
                                      };
                                    }).toList();

                                    return DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: "Select Animal *",
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.pets),
                                      ),
                                      value: _selectedAnimalId,
                                      items: animals
                                          .map<DropdownMenuItem<String>>((
                                            animal,
                                          ) {
                                            final animalName =
                                                animal["name"] as String? ??
                                                'Unknown';
                                            final tagNumber =
                                                animal["tagNumber"] as String?;
                                            final hasTagNumber =
                                                tagNumber != null &&
                                                tagNumber.isNotEmpty;
                                            final gender =
                                                animal["gender"] as String? ??
                                                'Unknown';

                                            // Create compact display text
                                            String displayText = animalName;
                                            if (hasTagNumber) {
                                              displayText += " ($tagNumber)";
                                            }
                                            displayText += " • $gender";

                                            return DropdownMenuItem<String>(
                                              value: animal["id"] as String,
                                              child: Text(
                                                displayText,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          })
                                          .toList(),
                                      onChanged: (String? val) {
                                        setState(() {
                                          _selectedAnimalId = val;
                                          if (val != null) {
                                            final selectedAnimal = animals
                                                .firstWhere(
                                                  (a) => a["id"] == val,
                                                  orElse: () => {
                                                    "name": "Unknown",
                                                  },
                                                );
                                            _selectedAnimalName =
                                                selectedAnimal["name"]
                                                    as String? ??
                                                "Unknown";
                                          }
                                        });
                                      },
                                      validator: (value) => value == null
                                          ? "Please select an animal"
                                          : null,
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Event Type Dropdown
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: "Event Type *",
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.event),
                                  ),
                                  value: _selectedEventType,
                                  items: _eventTypes.map((String type) {
                                    return DropdownMenuItem<String>(
                                      value: type,
                                      child: Text(
                                        type,
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? val) {
                                    setState(() {
                                      _selectedEventType = val;
                                      // Reset outcome when event type changes
                                      _selectedOutcome = null;
                                    });
                                  },
                                  validator: (value) => value == null
                                      ? "Please select event type"
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // Outcome Dropdown (for AI events)
                                if (_selectedEventType == 'Insemination (AI)')
                                  Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          labelText: "Outcome",
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.outlined_flag),
                                          hintText:
                                              "Select outcome (can be updated later)",
                                        ),
                                        value: _selectedOutcome,
                                        items: _outcomeTypes.map((
                                          String outcome,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: outcome,
                                            child: Text(
                                              outcome,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (String? val) {
                                          setState(() {
                                            _selectedOutcome = val;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),

                                // Date Selection
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        readOnly: true,
                                        decoration: const InputDecoration(
                                          labelText: "Event Date *",
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(
                                            Icons.calendar_today,
                                          ),
                                        ),
                                        controller: TextEditingController(
                                          text: _selectedDate == null
                                              ? ""
                                              : DateFormat(
                                                  'yyyy-MM-dd',
                                                ).format(_selectedDate!),
                                        ),
                                        validator: (value) =>
                                            _selectedDate == null
                                            ? "Please select a date"
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      onPressed: _pickDate,
                                      icon: const Icon(Icons.calendar_month),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.all(16),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Notes
                                TextFormField(
                                  controller: _notesController,
                                  decoration: const InputDecoration(
                                    labelText: "Notes (Optional)",
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.notes),
                                    hintText:
                                        "Additional observations, vet notes, etc...",
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 20),

                                // Save Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _saveBreedingRecord,
                                    icon: const Icon(Icons.save),
                                    label: const Text("Save Breeding Record"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Breeding History Section
                  const Text(
                    "📋 Breeding History & Predictions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("farmers")
                        .doc(user!.uid)
                        .collection("breeding_records")
                        .orderBy("date", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Error loading records: ${snapshot.error}",
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.pregnant_woman,
                                  size: 64,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No Breeding Records Yet",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Add your first breeding record to unlock smart predictions",
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: snapshot.data!.docs.map((doc) {
                          final record = doc.data() as Map<String, dynamic>;
                          final date = (record["date"] as Timestamp).toDate();
                          final animalName =
                              record["animalName"] ?? "Unknown Animal";
                          final eventType =
                              record["eventType"] ?? "Unknown Event";
                          final outcome = record["outcome"] ?? "Pending";
                          final notes = record["notes"] ?? "";

                          // Color coding based on event type
                          Color eventColor = Colors.purple;
                          IconData eventIcon = Icons.pets;

                          if (eventType.toLowerCase().contains('heat')) {
                            eventColor = Colors.orange;
                            eventIcon = Icons.favorite;
                          } else if (eventType.toLowerCase().contains(
                            'pregnant',
                          )) {
                            eventColor = Colors.green;
                            eventIcon = Icons.pregnant_woman;
                          } else if (eventType.toLowerCase().contains(
                            'calving',
                          )) {
                            eventColor = Colors.blue;
                            eventIcon = Icons.celebration;
                          } else if (eventType.toLowerCase().contains('ai') ||
                              eventType.toLowerCase().contains(
                                'insemination',
                              )) {
                            eventColor = Colors.pink;
                            eventIcon = Icons.insights;
                          } else if (eventType.toLowerCase().contains('vet')) {
                            eventColor = Colors.red;
                            eventIcon = Icons.medical_services;
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: Icon(eventIcon, color: eventColor),
                              title: Text(
                                animalName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          eventType,
                                          style: TextStyle(
                                            color: eventColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (outcome != 'Pending')
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                outcome == 'Pregnancy Confirmed'
                                                ? Colors.green.withOpacity(0.2)
                                                : outcome == 'Failed'
                                                ? Colors.red.withOpacity(0.2)
                                                : Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            outcome,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color:
                                                  outcome ==
                                                      'Pregnancy Confirmed'
                                                  ? Colors.green
                                                  : outcome == 'Failed'
                                                  ? Colors.red
                                                  : Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    DateFormat("MMM dd, yyyy").format(date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (notes.isNotEmpty)
                                    Text(
                                      "Notes: $notes",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  // Show predictions if available
                                  if (record.containsKey('predictedCalving'))
                                    Text(
                                      "🐄 Calving: ${DateFormat('MMM dd, yyyy').format((record['predictedCalving'] as Timestamp).toDate())}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.green,
                                      ),
                                    ),
                                  if (record.containsKey('predictedNextHeat'))
                                    Text(
                                      "❤️ Next Heat: ${DateFormat('MMM dd, yyyy').format((record['predictedNextHeat'] as Timestamp).toDate())}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  if (record.containsKey('pregnancyCheckDue'))
                                    Text(
                                      "🩺 Pregnancy Check: ${DateFormat('MMM dd, yyyy').format((record['pregnancyCheckDue'] as Timestamp).toDate())}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  if (record.containsKey('earlyPregnancyCheck'))
                                    Text(
                                      "🔍 Early Check: ${DateFormat('MMM dd, yyyy').format((record['earlyPregnancyCheck'] as Timestamp).toDate())}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.purple,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == "delete") {
                                    _deleteRecord(doc.id, animalName);
                                  } else if (value == "update_outcome" &&
                                      eventType == 'Insemination (AI)') {
                                    _showOutcomeUpdateDialog(doc.id, outcome);
                                  }
                                },
                                itemBuilder: (context) {
                                  final items = <PopupMenuEntry<String>>[
                                    if (eventType == 'Insemination (AI)')
                                      const PopupMenuItem(
                                        value: "update_outcome",
                                        child: Row(
                                          children: [
                                            Icon(Icons.outlined_flag, size: 20),
                                            SizedBox(width: 8),
                                            Text("Update Outcome"),
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
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ];
                                  return items;
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  void _showOutcomeUpdateDialog(String docId, String currentOutcome) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update AI Outcome"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select the outcome for this AI event:"),
            const SizedBox(height: 16),
            ..._outcomeTypes.map((outcome) {
              return ListTile(
                leading: Radio<String>(
                  value: outcome,
                  groupValue: currentOutcome,
                  onChanged: (value) {
                    _updateOutcome(docId, value!);
                    Navigator.pop(context);
                  },
                ),
                title: Text(outcome),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
