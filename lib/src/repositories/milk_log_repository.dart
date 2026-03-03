import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/milk_log_model.dart';
import 'package:flutter/foundation.dart';

class MilkLogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Box<MilkLogModel> _milkLogBox = Hive.box<MilkLogModel>('milk_logs');

  // Stream that yields immediate local data from Hive, then optionally updates when Firestore fetches
  Stream<List<MilkLogModel>> getMilkLogsStream(String farmerId) async* {
    // 1. Yield initial data from Hive
    yield _milkLogBox.values.toList();

    // 2. Yield updates as they happen locally
    await for (final _ in _milkLogBox.watch()) {
      yield _milkLogBox.values.toList();
    }
  }

  // Method to sync without returning stream (can be called in background)
  Future<void> syncMilkLogs(String farmerId) async {
    try {
      final snapshot = await _firestore
          .collection('farmers')
          .doc(farmerId)
          .collection('milk_logs')
          .orderBy("date", descending: true)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final log = MilkLogModel.fromMap(doc.id, data);
        await _milkLogBox.put(doc.id, log);
      }
    } catch (e) {
      debugPrint("Background sync failed: $e");
    }
  }

  // Add a new milk log
  Future<String> addMilkLog(String farmerId, MilkLogModel log) async {
    try {
      final docRef = await _firestore
          .collection('farmers')
          .doc(farmerId)
          .collection('milk_logs')
          .add({
            ...log.toMap(),
            "timestamp": FieldValue.serverTimestamp(),
          });
      
      // Update Hive with the generated ID
      final newLog = MilkLogModel(
        id: docRef.id,
        animalId: log.animalId,
        animalName: log.animalName,
        quantity: log.quantity,
        date: log.date,
      );
      
      await _milkLogBox.put(docRef.id, newLog);
      return docRef.id;
    } catch (e) {
      debugPrint("Error adding milk log to Firestore: $e");
      rethrow;
    }
  }

  // Update existing milk log
  Future<void> updateMilkLog(String farmerId, MilkLogModel log) async {
    await _milkLogBox.put(log.id, log);

    try {
      await _firestore
          .collection('farmers')
          .doc(farmerId)
          .collection('milk_logs')
          .doc(log.id)
          .update({
             ...log.toMap(),
             "timestamp": FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Error updating milk log in Firestore: $e");
      rethrow;
    }
  }

  // Delete milk log
  Future<void> deleteMilkLog(String farmerId, String logId) async {
    await _milkLogBox.delete(logId);

    try {
       await _firestore
           .collection('farmers')
           .doc(farmerId)
           .collection('milk_logs')
           .doc(logId)
           .delete();
    } catch (e) {
      debugPrint("Error deleting milk log in Firestore: $e");
      rethrow;
    }
  }
}
