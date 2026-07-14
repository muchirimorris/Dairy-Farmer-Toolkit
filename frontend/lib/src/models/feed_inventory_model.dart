import 'package:hive/hive.dart';

part 'feed_inventory_model.g.dart';

@HiveType(typeId: 4)
class FeedInventoryModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // 'Hay', 'Silage', 'Concentrate', 'Minerals'

  @HiveField(2)
  final String name;

  @HiveField(3)
  final double quantity;

  @HiveField(4)
  final String unit;

  @HiveField(5)
  final double cost;

  @HiveField(6)
  final DateTime purchaseDate;

  @HiveField(7)
  final double threshold;

  @HiveField(8)
  final bool isSynced;

  @HiveField(9)
  final String farmerId;

  FeedInventoryModel({
    required this.id,
    required this.type,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.cost,
    required this.purchaseDate,
    required this.threshold,
    this.isSynced = false,
    this.farmerId = '',
  });

  factory FeedInventoryModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedInventoryModel(
      id: id,
      type: map['type'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'kg',
      cost: (map['cost'] ?? 0.0).toDouble(),
      purchaseDate: map['purchaseDate'] != null ? DateTime.parse(map['purchaseDate']) : DateTime.now(),
      threshold: (map['threshold'] ?? 0.0).toDouble(),
      isSynced: true,
      farmerId: map['farmerId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'cost': cost,
      'purchaseDate': purchaseDate.toIso8601String(),
      'threshold': threshold,
      'farmerId': farmerId,
    };
  }
  
  FeedInventoryModel copyWith({
    String? id,
    String? type,
    String? name,
    double? quantity,
    String? unit,
    double? cost,
    DateTime? purchaseDate,
    double? threshold,
    bool? isSynced,
  }) {
    return FeedInventoryModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      cost: cost ?? this.cost,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      threshold: threshold ?? this.threshold,
      isSynced: isSynced ?? this.isSynced,
      farmerId: farmerId ?? this.farmerId,
    );
  }
}
