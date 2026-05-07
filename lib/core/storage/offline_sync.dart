import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../api/api_client.dart';

/// Offline operations that are stored when the device is offline.
class PendingOperation {
  final String id;
  final String type; // 'attendance'|'grade'|'homework'
  final String endpoint; // '/teacher/attendance/mark/'
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retryCount;

  PendingOperation({
    required this.id,
    required this.type,
    required this.endpoint,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'endpoint': endpoint,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory PendingOperation.fromMap(Map<dynamic, dynamic> map) {
    return PendingOperation(
      id: map['id'] as String,
      type: map['type'] as String,
      endpoint: map['endpoint'] as String,
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      createdAt: DateTime.parse(map['createdAt'] as String),
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Service to handle offline data synchronization.
class OfflineSyncService {
  static const _boxName = 'pending_ops';

  /// Adds a new operation to the persistent offline queue.
  static Future<void> enqueue({
    required String type,
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    final box = await Hive.openBox(_boxName);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final op = PendingOperation(
      id: id,
      type: type,
      endpoint: endpoint,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await box.put(id, op.toMap());
    debugPrint('OfflineSync: Navbatga qo\'shildi: $type. Jami: ${box.length}');
  }

  /// Attempts to send all pending operations to the server.
  static Future<void> flushQueue(ApiClient client) async {
    if (!await Hive.boxExists(_boxName)) return;
    
    final box = await Hive.openBox(_boxName);
    if (box.isEmpty) return;

    debugPrint('OfflineSync: ${box.length} ta kutilayotgan amal yuborilmoqda...');
    
    // Convert keys to list to avoid concurrent modification issues
    final keys = box.keys.toList();

    for (final key in keys) {
      final map = box.get(key);
      if (map == null) continue;
      
      final op = PendingOperation.fromMap(map as Map);

      try {
        await client.post(op.endpoint, data: op.payload);
        await box.delete(key);
        debugPrint('OfflineSync: Muvaffaqiyatli sinxronlandi: ${op.type}');
      } catch (e) {
        op.retryCount++;
        if (op.retryCount >= 3) {
          await box.delete(key);
          debugPrint('OfflineSync: 3 marta xatolikdan so\'ng o\'chirildi: ${op.type}');
        } else {
          await box.put(key, op.toMap());
          debugPrint('OfflineSync: Xatolik ${op.type} (urinish: ${op.retryCount})');
        }
        // Order is important for many operations, so we stop on first error
        break; 
      }
    }
  }

  /// Returns the number of pending operations.
  static Future<int> get pendingCount async {
    final box = await Hive.openBox(_boxName);
    return box.length;
  }
}
