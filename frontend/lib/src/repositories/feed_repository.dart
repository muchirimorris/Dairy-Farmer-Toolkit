import 'package:hive/hive.dart';
import '../models/feed_inventory_model.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class FeedRepository {
  final ApiService _apiService = ApiService();
  final Box<FeedInventoryModel> _feedBox = Hive.box<FeedInventoryModel>('feed_inventory');

  Stream<List<FeedInventoryModel>> getFeedInventoryStream(String farmerId) async* {
    yield _feedBox.values.where((item) => item.farmerId == farmerId).toList();
    await for (final _ in _feedBox.watch()) {
      yield _feedBox.values.where((item) => item.farmerId == farmerId).toList();
    }
  }

  Future<void> syncFeed(String farmerId) async {
    try {
      final List<dynamic> response = await _apiService.get('/feed-inventory/');
      for (var item in response) {
        final feedItem = FeedInventoryModel(
          id: item['id'],
          farmerId: farmerId,
          type: item['type'],
          name: item['name'],
          quantity: item['quantity'],
          unit: item['unit'],
          cost: item['cost'],
          purchaseDate: DateTime.parse(item['purchase_date']),
          threshold: item['threshold'],
        );
        await _feedBox.put(feedItem.id, feedItem);
      }
    } catch (e) {
      debugPrint("Feed sync failed: $e");
    }
  }

  Future<String> addFeedItem(FeedInventoryModel item) async {
    try {
      final response = await _apiService.post('/feed-inventory/', {
        'type': item.type,
        'name': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'cost': item.cost,
        'purchase_date': item.purchaseDate.toIso8601String(),
        'threshold': item.threshold,
      });

      final newItem = FeedInventoryModel(
        id: response['id'],
        farmerId: item.farmerId,
        type: response['type'],
        name: response['name'],
        quantity: response['quantity'],
        unit: response['unit'],
        cost: response['cost'],
        purchaseDate: DateTime.parse(response['purchase_date']),
        threshold: response['threshold'],
      );
      
      await _feedBox.put(newItem.id, newItem);
      return newItem.id;
    } catch (e) {
      debugPrint("Error adding feed to API: $e");
      rethrow;
    }
  }

  Future<void> updateFeedItem(FeedInventoryModel item) async {
    await _feedBox.put(item.id, item);
    try {
      await _apiService.put('/feed-inventory/${item.id}/', {
        'type': item.type,
        'name': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'cost': item.cost,
        'purchase_date': item.purchaseDate.toIso8601String(),
        'threshold': item.threshold,
      });
    } catch (e) {
      debugPrint("Error updating feed in API: $e");
      rethrow;
    }
  }

  Future<void> deleteFeedItem(String itemId) async {
    await _feedBox.delete(itemId);
    try {
      await _apiService.delete('/feed-inventory/$itemId/');
    } catch (e) {
      debugPrint("Error deleting feed in API: $e");
      rethrow;
    }
  }
}
