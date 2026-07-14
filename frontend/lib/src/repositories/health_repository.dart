import 'package:hive/hive.dart';
import '../models/health_record_model.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class HealthRepository {
  final ApiService _apiService = ApiService();
  final Box<HealthRecordModel> _healthBox = Hive.box<HealthRecordModel>('health_records');

  Stream<List<HealthRecordModel>> getHealthRecordsStream(String farmerId) async* {
    yield _healthBox.values.where((item) => item.farmerId == farmerId).toList();
    await for (final _ in _healthBox.watch()) {
      yield _healthBox.values.where((item) => item.farmerId == farmerId).toList();
    }
  }

  Future<void> syncHealthRecords(String farmerId) async {
    try {
      final List<dynamic> response = await _apiService.get('/health-records/');
      for (var item in response) {
        final record = HealthRecordModel(
          id: item['id'],
          animalId: item['animal'],
          farmerId: farmerId,
          type: item['type'],
          date: DateTime.parse(item['date']),
          description: item['description'],
          medicineUsed: item['medicine_used'],
          cost: item['cost'],
          nextFollowUp: item['next_follow_up'] != null ? DateTime.parse(item['next_follow_up']) : null,
        );
        await _healthBox.put(record.id, record);
      }
    } catch (e) {
      debugPrint("Health sync failed: $e");
    }
  }

  Future<String> addHealthRecord(HealthRecordModel record) async {
    try {
      final response = await _apiService.post('/health-records/', {
        'animal': record.animalId,
        'type': record.type,
        'date': record.date.toIso8601String(),
        'description': record.description,
        'medicine_used': record.medicineUsed,
        'cost': record.cost,
        'next_follow_up': record.nextFollowUp?.toIso8601String(),
      });

      final newRecord = HealthRecordModel(
        id: response['id'],
        animalId: response['animal'],
        farmerId: record.farmerId,
        type: response['type'],
        date: DateTime.parse(response['date']),
        description: response['description'],
        medicineUsed: response['medicine_used'],
        cost: response['cost'],
        nextFollowUp: response['next_follow_up'] != null ? DateTime.parse(response['next_follow_up']) : null,
      );
      
      await _healthBox.put(newRecord.id, newRecord);
      return newRecord.id;
    } catch (e) {
      debugPrint("Error adding health record to API: $e");
      rethrow;
    }
  }

  Future<void> deleteHealthRecord(String recordId) async {
    await _healthBox.delete(recordId);
    try {
      await _apiService.delete('/health-records/$recordId/');
    } catch (e) {
      debugPrint("Error deleting health record in API: $e");
      rethrow;
    }
  }
}
