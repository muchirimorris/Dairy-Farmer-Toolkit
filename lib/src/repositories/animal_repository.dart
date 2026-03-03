import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/animal_model.dart';
import 'package:flutter/foundation.dart'; // for debugPrint

class AnimalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Box<AnimalModel> _animalBox = Hive.box<AnimalModel>('animals');

  // Stream that yields immediate local data from Hive, then optionally updates when Firestore fetches
  Stream<List<AnimalModel>> getAnimalsStream(String farmerId) async* {
    // 1. Yield initial data from Hive
    yield _animalBox.values
        .where((animal) => animal.farmerId == farmerId)
        .toList();

    // 2. Yield updates as they happen locally
    await for (final _ in _animalBox.watch()) {
      yield _animalBox.values
          .where((animal) => animal.farmerId == farmerId)
          .toList();
    }
  }

  // Method to sync without returning stream (can be called in background)
  Future<void> syncAnimals(String farmerId) async {
    try {
      final snapshot = await _firestore
          .collection('animals')
          .where('farmerId', isEqualTo: farmerId)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final animal = AnimalModel.fromMap(doc.id, data);
        await _animalBox.put(doc.id, animal);
      }
    } catch (e) {
      debugPrint("Background sync failed: $e");
    }
  }

  // Add a new animal
  Future<String> addAnimal(AnimalModel animal) async {
    // Optimistic offline update: save to Hive first
    // Note: If no internet, we might need a separate queue.
    // Assuming simple optimistic update here.
    
    // Add to Firestore
    try {
      final docRef = await _firestore.collection('animals').add(animal.toMap());
      
      // Now update Hive with the generated ID
      final newAnimal = AnimalModel(
        id: docRef.id,
        tagNumber: animal.tagNumber,
        name: animal.name,
        breed: animal.breed,
        age: animal.age,
        productionStatus: animal.productionStatus,
        reproductiveStatus: animal.reproductiveStatus,
        lastCalvingDate: animal.lastCalvingDate,
        imageUrl: animal.imageUrl,
        farmerId: animal.farmerId,
      );
      
      await _animalBox.put(docRef.id, newAnimal);
      return docRef.id;
    } catch (e) {
      debugPrint("Error adding animal to Firestore: $e");
      // Fallback for full offline write queue is complex, 
      // but we can at least throw or handle basic offline write issues here.
      rethrow;
    }
  }

  // Update existing animal
  Future<void> updateAnimal(AnimalModel animal) async {
    // 1. Update local immediately
    await _animalBox.put(animal.id, animal);

    // 2. Update remote
    try {
      await _firestore.collection('animals').doc(animal.id).update(animal.toMap());
    } catch (e) {
      debugPrint("Error updating animal in Firestore: $e");
      rethrow;
    }
  }

  // Delete animal
  Future<void> deleteAnimal(String animalId) async {
    // 1. Delete local
    await _animalBox.delete(animalId);

    // 2. Delete remote
    try {
       await _firestore.collection('animals').doc(animalId).delete();
    } catch (e) {
      debugPrint("Error deleting animal in Firestore: $e");
      rethrow;
    }
  }
}
