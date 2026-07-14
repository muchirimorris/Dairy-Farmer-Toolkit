import 'package:hive/hive.dart';

part 'financial_record_model.g.dart';

@HiveType(typeId: 3)
class FinancialRecordModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // 'income' or 'expense'

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String category; // 'milk_sale', 'feed', 'veterinary', 'labor', 'equipment', 'other'

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String? animalId;

  @HiveField(6)
  final String? description;

  @HiveField(7)
  final bool isSynced;

  @HiveField(8)
  final String farmerId;

  FinancialRecordModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    this.animalId,
    this.description,
    this.isSynced = false,
    this.farmerId = '',
  });

  factory FinancialRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return FinancialRecordModel(
      id: id,
      type: map['type'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      animalId: map['animalId'],
      description: map['description'],
      isSynced: true, // From Firestore implies it's synced
      farmerId: map['farmerId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'animalId': animalId,
      'description': description,
      'farmerId': farmerId,
    };
  }

  FinancialRecordModel copyWith({
    String? id,
    String? type,
    double? amount,
    String? category,
    DateTime? date,
    String? animalId,
    String? description,
    bool? isSynced,
  }) {
    return FinancialRecordModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      animalId: animalId ?? this.animalId,
      description: description ?? this.description,
      isSynced: isSynced ?? this.isSynced,
      farmerId: farmerId ?? this.farmerId,
    );
  }
}
