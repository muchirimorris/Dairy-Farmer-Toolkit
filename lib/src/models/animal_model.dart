import 'package:hive/hive.dart';

part 'animal_model.g.dart';

@HiveType(typeId: 0)
class AnimalModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tagNumber;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String breed;

  @HiveField(4)
  final int age;

  @HiveField(5)
  final String productionStatus;

  @HiveField(6)
  final String reproductiveStatus;

  @HiveField(7)
  final String? lastCalvingDate;

  @HiveField(8)
  final String? imageUrl;

  @HiveField(9)
  final String farmerId;

  AnimalModel({
    required this.id,
    required this.tagNumber,
    required this.name,
    required this.breed,
    required this.age,
    required this.productionStatus,
    required this.reproductiveStatus,
    this.lastCalvingDate,
    this.imageUrl,
    required this.farmerId,
  });

  factory AnimalModel.fromMap(String id, Map<String, dynamic> map) {
    return AnimalModel(
      id: id,
      tagNumber: map['tagNumber'] ?? 'No Tag',
      name: map['name'] ?? 'Unnamed',
      breed: map['breed'] ?? 'Unknown',
      age: map['age']?.toInt() ?? 0,
      productionStatus: map['productionStatus'] ?? 'Unknown',
      reproductiveStatus: map['reproductiveStatus'] ?? 'Unknown',
      lastCalvingDate: map['lastCalvingDate'],
      imageUrl: map['imageUrl'],
      farmerId: map['farmerId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tagNumber': tagNumber,
      'name': name,
      'breed': breed,
      'age': age,
      'productionStatus': productionStatus,
      'reproductiveStatus': reproductiveStatus,
      'lastCalvingDate': lastCalvingDate,
      'imageUrl': imageUrl,
      'farmerId': farmerId,
    };
  }
}
