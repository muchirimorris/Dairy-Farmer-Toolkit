import 'package:hive/hive.dart';
import '../models/milk_log_model.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class MilkLogRepository {
  final ApiService _apiService = ApiService();
  final Box<MilkLogModel> _milkBox = Hive.box<MilkLogModel>('milk_logs');

  Stream<List<MilkLogModel>> getMilkLogsStream(String farmerId) async* {
    yield _milkBox.values.where((item) => item.farmerId == farmerId).toList();
    await for (final _ in _milkBox.watch()) {
      yield _milkBox.values.where((item) => item.farmerId == farmerId).toList();
    }
  }

  Future<void> syncMilkLogs(String farmerId) async {
    try {
      final List<dynamic> response = await _apiService.get('/milk-logs/');
      for (var item in response) {
        final log = MilkLogModel(
          id: item['id'],
          animalId: item['animal'],
          farmerId: farmerId,
          date: DateTime.parse(item['date']),
          quantity: item['liters'],
          animalName: 'Unknown', // Need to fetch from Animal repository or API
        );
        await _milkBox.put(log.id, log);
      }
    } catch (e) {
      debugPrint("Milk log sync failed: $e");
    }
  }

  Future<String> addMilkLog(MilkLogModel log) async {
    try {
      final response = await _apiService.post('/milk-logs/', {
        'animal': log.animalId,
        'date': log.date.toIso8601String(),
        'liters': log.quantity,
      });

      final newLog = MilkLogModel(
        id: response['id'],
        animalId: response['animal'],
        farmerId: log.farmerId,
        date: DateTime.parse(response['date']),
        quantity: response['liters'],
        animalName: log.animalName,
      );
      
      await _milkBox.put(newLog.id, newLog);
      return newLog.id;
    } catch (e) {
      debugPrint("Error adding milk log to API: $e");
      rethrow;
    }
  }

  Future<void> deleteMilkLog(String logId) async {
    await _milkBox.delete(logId);
    try {
      await _apiService.delete('/milk-logs/$logId/');
    } catch (e) {
      debugPrint("Error deleting milk log in API: $e");
      rethrow;
    }
  }

  Future<void> updateMilkLog(MilkLogModel log) async {
    try {
      final response = await _apiService.put('/milk-logs/${log.id}/', {
        'animal': log.animalId,
        'date': log.date.toIso8601String(),
        'liters': log.quantity,
      });

      final updatedLog = MilkLogModel(
        id: response['id'],
        animalId: response['animal'],
        farmerId: log.farmerId,
        date: DateTime.parse(response['date']),
        quantity: response['liters'],
        animalName: log.animalName,
      );
      
      await _milkBox.put(updatedLog.id, updatedLog);
    } catch (e) {
      debugPrint("Error updating milk log in API: $e");
      rethrow;
    }
  }
}
