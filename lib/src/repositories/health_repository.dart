import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/health_record_model.dart';
import 'package:flutter/foundation.dart';

class HealthRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Box<HealthRecordModel> _healthBox = Hive.box<HealthRecordModel>('health_records');

  Stream<List<HealthRecordModel>> getHealthRecordsStream(String farmerId) async* {
    yield _healthBox.values.toList();

    await for (final _ in _healthBox.watch()) {
      yield _healthBox.values.toList();
    }
  }

  Future<void> syncHealthRecords(String farmerId) async {
    try {
      final snapshot = await _firestore
          .collection('farmers')
          .doc(farmerId)
          .collection('health_records')
          .orderBy("date", descending: true)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final record = HealthRecordModel.fromMap(data, doc.id);
        await _healthBox.put(doc.id, record);
      }
    } catch (e) {
      debugPrint("Background sync failed for health records: $e");
    }
  }

  Future<String> addHealthRecord(String farmerId, HealthRecordModel record) async {
    try {
      final docRef = await _firestore
          .collection('farmers')
          .doc(farmerId)
          .collection('health_records')
          .add({
            ...record.toMap(),
            "timestamp": FieldValue.serverTimestamp(),
          });
      
      final newRecord = record.copyWith(id: docRef.id);
      await _healthBox.put(docRef.id, newRecord);
      return docRef.id;
    } catch (e) {
      debugPrint("Error adding health record to Firestore: $e");
      rethrow;
    }
  }

  Future<void> updateHealthRecord(String farmerId, HealthRecordModel record) async {
    await _healthBox.put(record.id, record);

    try {
      await _firestore
          .collection('farmers')
          .doc(farmerId)
          .collection('health_records')
          .doc(record.id)
          .update({
             ...record.toMap(),
             "timestamp": FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Error updating health record in Firestore: $e");
      rethrow;
    }
  }

  Future<void> deleteHealthRecord(String farmerId, String recordId) async {
    await _healthBox.delete(recordId);

    try {
       await _firestore
           .collection('farmers')
           .doc(farmerId)
           .collection('health_records')
           .doc(recordId)
           .delete();
    } catch (e) {
      debugPrint("Error deleting health record in Firestore: $e");
      rethrow;
    }
  }
}
