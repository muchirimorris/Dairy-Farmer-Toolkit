import 'package:hive/hive.dart';

part 'health_record_model.g.dart';

@HiveType(typeId: 5)
class HealthRecordModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String animalId;

  @HiveField(2)
  final String type; // 'vaccination', 'disease', 'treatment', 'vet_visit'

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final String? medicineUsed;

  @HiveField(6)
  final double? cost;

  @HiveField(7)
  final DateTime? nextFollowUp;

  @HiveField(8)
  final bool isSynced;

  HealthRecordModel({
    required this.id,
    required this.animalId,
    required this.type,
    required this.date,
    required this.description,
    this.medicineUsed,
    this.cost,
    this.nextFollowUp,
    this.isSynced = false,
  });

  factory HealthRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return HealthRecordModel(
      id: id,
      animalId: map['animalId'] ?? '',
      type: map['type'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      description: map['description'] ?? '',
      medicineUsed: map['medicineUsed'],
      cost: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
      nextFollowUp: map['nextFollowUp'] != null ? DateTime.parse(map['nextFollowUp']) : null,
      isSynced: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'animalId': animalId,
      'type': type,
      'date': date.toIso8601String(),
      'description': description,
      'medicineUsed': medicineUsed,
      'cost': cost,
      'nextFollowUp': nextFollowUp?.toIso8601String(),
    };
  }

  HealthRecordModel copyWith({
    String? id,
    String? animalId,
    String? type,
    DateTime? date,
    String? description,
    String? medicineUsed,
    double? cost,
    DateTime? nextFollowUp,
    bool? isSynced,
  }) {
    return HealthRecordModel(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      type: type ?? this.type,
      date: date ?? this.date,
      description: description ?? this.description,
      medicineUsed: medicineUsed ?? this.medicineUsed,
      cost: cost ?? this.cost,
      nextFollowUp: nextFollowUp ?? this.nextFollowUp,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
