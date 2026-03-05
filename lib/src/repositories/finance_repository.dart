import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/financial_record_model.dart';
import 'package:flutter/foundation.dart';

class FinanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Box<FinancialRecordModel> _financeBox = Hive.box<FinancialRecordModel>('financial_records');

  Stream<List<FinancialRecordModel>> getFinancialRecordsStream(String farmerId) async* {
    // 1. Yield initial data from Hive
    yield _financeBox.values.toList();

    // 2. Yield updates as they happen locally
    await for (final _ in _financeBox.watch()) {
      yield _financeBox.values.toList();
    }
  }

  Future<void> syncFinancialRecords(String farmerId) async {
    try {
      final snapshot = await _firestore
          .collection('farmers')
          .doc(farmerId)
          .collection('financial_records')
          .orderBy("date", descending: true)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final record = FinancialRecordModel.fromMap(data, doc.id);
        await _financeBox.put(doc.id, record);
      }
    } catch (e) {
      debugPrint("Background sync failed for financial records: $e");
    }
  }

  Future<String> addFinancialRecord(String farmerId, FinancialRecordModel record) async {
    try {
      final docRef = await _firestore
          .collection('farmers')
          .doc(farmerId)
          .collection('financial_records')
          .add({
            ...record.toMap(),
            "timestamp": FieldValue.serverTimestamp(),
          });
      
      final newRecord = record.copyWith(id: docRef.id);
      await _financeBox.put(docRef.id, newRecord);
      return docRef.id;
    } catch (e) {
      debugPrint("Error adding financial record to Firestore: $e");
      rethrow;
    }
  }

  Future<void> updateFinancialRecord(String farmerId, FinancialRecordModel record) async {
    await _financeBox.put(record.id, record);

    try {
      await _firestore
          .collection('farmers')
          .doc(farmerId)
          .collection('financial_records')
          .doc(record.id)
          .update({
             ...record.toMap(),
             "timestamp": FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Error updating financial record in Firestore: $e");
      rethrow;
    }
  }

  Future<void> deleteFinancialRecord(String farmerId, String recordId) async {
    await _financeBox.delete(recordId);

    try {
       await _firestore
           .collection('farmers')
           .doc(farmerId)
           .collection('financial_records')
           .doc(recordId)
           .delete();
    } catch (e) {
      debugPrint("Error deleting financial record in Firestore: $e");
      rethrow;
    }
  }
}
