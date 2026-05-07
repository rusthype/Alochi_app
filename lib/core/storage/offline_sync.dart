import 'package:flutter/foundation.dart';

/// Offline Sync Skeleton for A'lochi Teacher v1.1.
/// Handles queueing of API requests when offline and replaying them when online.
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final List<OfflineOp> _queue = [];

  /// Adds a operation to the queue.
  /// If [isOnline] is true, it might attempt immediate execution.
  Future<void> queueOp(OfflineOp op) async {
    _queue.add(op);
    debugPrint('OfflineSync: Queued ${op.type} for ${op.path}');
    // In a real implementation, we would save this to Hive/sqflite here.
  }

  /// Attempts to sync all pending operations.
  Future<void> sync() async {
    if (_queue.isEmpty) return;
    debugPrint('OfflineSync: Starting sync of ${_queue.length} operations');
    
    final items = List<OfflineOp>.from(_queue);
    for (final op in items) {
      try {
        await _executeOp(op);
        _queue.remove(op);
      } catch (e) {
        debugPrint('OfflineSync: Failed to sync ${op.type}: $e');
        // Stop sync on first error to preserve order
        break;
      }
    }
  }

  Future<void> _executeOp(OfflineOp op) async {
    // In real implementation, this would use ApiClient to replay the request
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('OfflineSync: Successfully executed ${op.type}');
  }

  int get pendingCount => _queue.length;
}

enum OfflineOpType { post, put, delete, patch }

class OfflineOp {
  final OfflineOpType type;
  final String path;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  OfflineOp({
    required this.type,
    required this.path,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
