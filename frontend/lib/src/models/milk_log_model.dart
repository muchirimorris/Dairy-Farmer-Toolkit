import 'package:hive/hive.dart';

part 'milk_log_model.g.dart';

@HiveType(typeId: 1)
class MilkLogModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String animalId;

  @HiveField(2)
  final String animalName;

  @HiveField(3)
  final double quantity;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String farmerId;

  MilkLogModel({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.quantity,
    required this.date,
    this.farmerId = '',
  });

  factory MilkLogModel.fromMap(String id, Map<String, dynamic> map) {
    return MilkLogModel(
      id: id,
      animalId: map['animalId'] ?? '',
      animalName: map['animalName'] ?? 'Unknown',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null 
          ? DateTime.parse(map['date']) 
          : DateTime.now(),
      farmerId: map['farmerId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'animalId': animalId,
      'animalName': animalName,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'farmerId': farmerId,
    };
  }
}
