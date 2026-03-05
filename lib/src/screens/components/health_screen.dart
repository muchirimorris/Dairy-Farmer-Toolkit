import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/health_record_model.dart';
import '../../models/animal_model.dart';
import '../../repositories/health_repository.dart';
import '../../repositories/animal_repository.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final HealthRepository _healthRepo = HealthRepository();
  final AnimalRepository _animalRepo = AnimalRepository();

  late Stream<List<HealthRecordModel>> _healthStream;
  late Stream<List<AnimalModel>> _animalStream;
  List<AnimalModel> _animals = [];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _healthRepo.syncHealthRecords(user.uid);
      _animalRepo.syncAnimals(user.uid);
      
      _healthStream = _healthRepo.getHealthRecordsStream(user.uid).asBroadcastStream();
      _animalStream = _animalRepo.getAnimalsStream(user.uid).asBroadcastStream();
      
      _animalStream.listen((animals) {
        if (mounted) {
          setState(() {
            _animals = animals;
          });
        }
      });
    }
  }

  String _getAnimalName(String animalId) {
    try {
      return _animals.firstWhere((a) => a.id == animalId).name;
    } catch (e) {
      return "Unknown Animal";
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("🩺 Health Records", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white),
            onPressed: () => _showAddRecordDialog(context, user?.uid),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text("Please login to manage health records."))
          : _buildRecordsList(user.uid),
    );
  }

  Widget _buildRecordsList(String farmerId) {
    return StreamBuilder<List<HealthRecordModel>>(
      stream: _healthStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_services, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text("No Health Records", style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        final records = snapshot.data!.toList()..sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final color = _getRecordTypeColor(record.type);
            final icon = _getRecordTypeIcon(record.type);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(icon, color: color),
                ),
                title: Text(_getAnimalName(record.animalId), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${record.type.toUpperCase()} • ${DateFormat('MMM dd, yyyy').format(record.date)}"),
                    const SizedBox(height: 4),
                    Text(record.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteRecord(context, farmerId, record.id),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Color _getRecordTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'vaccination':
        return Colors.blue;
      case 'treatment':
        return Colors.orange;
      case 'disease':
        return Colors.red;
      case 'vet_visit':
      default:
        return Colors.green;
    }
  }

  IconData _getRecordTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'vaccination':
        return Icons.vaccines;
      case 'treatment':
        return Icons.healing;
      case 'disease':
        return Icons.coronavirus;
      case 'vet_visit':
      default:
        return Icons.medical_services;
    }
  }

  void _showAddRecordDialog(BuildContext context, String? farmerId) {
    if (farmerId == null) return;
    
    if (_animals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add an animal first!")));
      return;
    }

    String? selectedAnimalId = _animals.first.id;
    String type = 'Vet_Visit';
    final descController = TextEditingController();
    final medController = TextEditingController();
    final costController = TextEditingController();
    DateTime date = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add Health Record"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedAnimalId,
                  decoration: const InputDecoration(labelText: "Select Animal"),
                  items: _animals.map((a) => DropdownMenuItem(value: a.id, child: Text("${a.name} (${a.tagNumber})"))).toList(),
                  onChanged: (v) => setState(() => selectedAnimalId = v),
                ),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: "Record Type"),
                  items: ['Vaccination', 'Treatment', 'Disease', 'Vet_Visit'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => type = v!),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Description / Notes", hintText: "e.g., Routine checkup"),
                  maxLines: 2,
                ),
                TextField(
                  controller: medController,
                  decoration: const InputDecoration(labelText: "Medicines Used (Optional)"),
                ),
                TextField(
                  controller: costController,
                  decoration: const InputDecoration(labelText: "Cost (Optional)", prefixText: "\$"),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (selectedAnimalId == null || descController.text.isEmpty) return;

                final record = HealthRecordModel(
                  id: '',
                  animalId: selectedAnimalId!,
                  type: type,
                  date: date,
                  description: descController.text,
                  medicineUsed: medController.text.isEmpty ? null : medController.text,
                  cost: double.tryParse(costController.text),
                );

                await _healthRepo.addHealthRecord(farmerId, record);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteRecord(BuildContext context, String farmerId, String recordId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Record?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _healthRepo.deleteHealthRecord(farmerId, recordId);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
