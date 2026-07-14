import 'package:hive/hive.dart';
import '../models/animal_model.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AnimalRepository {
  final ApiService _apiService = ApiService();
  final Box<AnimalModel> _animalBox = Hive.box<AnimalModel>('animals');

  // Stream that yields immediate local data from Hive
  Stream<List<AnimalModel>> getAnimalsStream(String farmerId) async* {
    yield _animalBox.values.where((animal) => animal.farmerId == farmerId).toList();

    await for (final _ in _animalBox.watch()) {
      yield _animalBox.values.where((animal) => animal.farmerId == farmerId).toList();
    }
  }

  // Method to sync without returning stream (can be called in background)
  Future<void> syncAnimals(String farmerId) async {
    try {
      final List<dynamic> response = await _apiService.get('/animals/');
      
      for (var item in response) {
        final animal = AnimalModel(
          id: item['id'],
          farmerId: farmerId,
          tagNumber: item['tag_number'],
          name: item['name'],
          breed: item['breed'],
          age: item['age'],
          productionStatus: item['production_status'],
          reproductiveStatus: item['reproductive_status'],
          lastCalvingDate: item['last_calving_date'],
          imageUrl: item['image_url'],
        );
        await _animalBox.put(animal.id, animal);
      }
    } catch (e) {
      debugPrint("Background sync failed: $e");
    }
  }

  // Add a new animal
  Future<String> addAnimal(AnimalModel animal) async {
    try {
      final response = await _apiService.post('/animals/', {
        'tag_number': animal.tagNumber,
        'name': animal.name,
        'breed': animal.breed,
        'age': animal.age,
        'production_status': animal.productionStatus,
        'reproductive_status': animal.reproductiveStatus,
        'last_calving_date': animal.lastCalvingDate,
        'image_url': animal.imageUrl,
      });
      
      final newAnimal = AnimalModel(
        id: response['id'],
        tagNumber: response['tag_number'],
        name: response['name'],
        breed: response['breed'],
        age: response['age'],
        productionStatus: response['production_status'],
        reproductiveStatus: response['reproductive_status'],
        lastCalvingDate: response['last_calving_date'],
        imageUrl: response['image_url'],
        farmerId: animal.farmerId,
      );
      
      await _animalBox.put(newAnimal.id, newAnimal);
      return newAnimal.id;
    } catch (e) {
      debugPrint("Error adding animal to Django API: $e");
      rethrow;
    }
  }

  // Update existing animal
  Future<void> updateAnimal(AnimalModel animal) async {
    await _animalBox.put(animal.id, animal);

    try {
      await _apiService.put('/animals/${animal.id}/', {
        'tag_number': animal.tagNumber,
        'name': animal.name,
        'breed': animal.breed,
        'age': animal.age,
        'production_status': animal.productionStatus,
        'reproductive_status': animal.reproductiveStatus,
        'last_calving_date': animal.lastCalvingDate,
        'image_url': animal.imageUrl,
      });
    } catch (e) {
      debugPrint("Error updating animal in Django API: $e");
      rethrow;
    }
  }

  // Delete animal
  Future<void> deleteAnimal(String animalId) async {
    await _animalBox.delete(animalId);

    try {
       await _apiService.delete('/animals/$animalId/');
    } catch (e) {
      debugPrint("Error deleting animal in Django API: $e");
      rethrow;
    }
  }
}
