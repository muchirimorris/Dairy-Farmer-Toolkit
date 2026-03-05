import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/feed_inventory_model.dart';
import 'package:flutter/foundation.dart';

class FeedRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Box<FeedInventoryModel> _feedBox = Hive.box<FeedInventoryModel>('feed_inventory');

  Stream<List<FeedInventoryModel>> getFeedInventoryStream(String farmerId) async* {
    yield _feedBox.values.toList();

    await for (final _ in _feedBox.watch()) {
      yield _feedBox.values.toList();
    }
  }

  Future<void> syncFeedInventory(String farmerId) async {
    try {
      final snapshot = await _firestore
          .collection('farmers')
          .doc(farmerId)
          .collection('feed_inventory')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final item = FeedInventoryModel.fromMap(data, doc.id);
        await _feedBox.put(doc.id, item);
      }
    } catch (e) {
      debugPrint("Background sync failed for feed inventory: $e");
    }
  }

  Future<String> addFeedItem(String farmerId, FeedInventoryModel item) async {
    try {
      final docRef = await _firestore
          .collection('farmers')
          .doc(farmerId)
          .collection('feed_inventory')
          .add({
            ...item.toMap(),
            "timestamp": FieldValue.serverTimestamp(),
          });
      
      final newItem = item.copyWith(id: docRef.id);
      await _feedBox.put(docRef.id, newItem);
      return docRef.id;
    } catch (e) {
      debugPrint("Error adding feed item to Firestore: $e");
      rethrow;
    }
  }

  Future<void> updateFeedItem(String farmerId, FeedInventoryModel item) async {
    await _feedBox.put(item.id, item);

    try {
      await _firestore
          .collection('farmers')
          .doc(farmerId)
          .collection('feed_inventory')
          .doc(item.id)
          .update({
             ...item.toMap(),
             "timestamp": FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Error updating feed item in Firestore: $e");
      rethrow;
    }
  }

  Future<void> deleteFeedItem(String farmerId, String itemId) async {
    await _feedBox.delete(itemId);

    try {
       await _firestore
           .collection('farmers')
           .doc(farmerId)
           .collection('feed_inventory')
           .doc(itemId)
           .delete();
    } catch (e) {
      debugPrint("Error deleting feed item in Firestore: $e");
      rethrow;
    }
  }
}
