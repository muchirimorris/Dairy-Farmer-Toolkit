import 'package:hive/hive.dart';
import '../models/financial_record_model.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class FinanceRepository {
  final ApiService _apiService = ApiService();
  final Box<FinancialRecordModel> _financeBox = Hive.box<FinancialRecordModel>('financial_records');

  Stream<List<FinancialRecordModel>> getFinancialRecordsStream(String farmerId) async* {
    yield _financeBox.values.where((item) => item.farmerId == farmerId).toList();
    await for (final _ in _financeBox.watch()) {
      yield _financeBox.values.where((item) => item.farmerId == farmerId).toList();
    }
  }

  Future<void> syncFinances(String farmerId) async {
    try {
      final List<dynamic> response = await _apiService.get('/financial-records/');
      for (var item in response) {
        final record = FinancialRecordModel(
          id: item['id'],
          farmerId: farmerId,
          type: item['type'],
          amount: item['amount'],
          category: item['category'],
          date: DateTime.parse(item['date']),
          animalId: item['animal'],
          description: item['description'],
        );
        await _financeBox.put(record.id, record);
      }
    } catch (e) {
      debugPrint("Finance sync failed: $e");
    }
  }

  Future<String> addRecord(FinancialRecordModel record) async {
    try {
      final response = await _apiService.post('/financial-records/', {
        'type': record.type,
        'amount': record.amount,
        'category': record.category,
        'date': record.date.toIso8601String(),
        'animal': record.animalId,
        'description': record.description,
      });

      final newRecord = FinancialRecordModel(
        id: response['id'],
        farmerId: record.farmerId,
        type: response['type'],
        amount: response['amount'],
        category: response['category'],
        date: DateTime.parse(response['date']),
        animalId: response['animal'],
        description: response['description'],
      );
      
      await _financeBox.put(newRecord.id, newRecord);
      return newRecord.id;
    } catch (e) {
      debugPrint("Error adding finance record to API: $e");
      rethrow;
    }
  }

  Future<void> deleteRecord(String recordId) async {
    await _financeBox.delete(recordId);
    try {
      await _apiService.delete('/financial-records/$recordId/');
    } catch (e) {
      debugPrint("Error deleting finance record in API: $e");
      rethrow;
    }
  }
}
