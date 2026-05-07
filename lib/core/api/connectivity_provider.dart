import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that tracks the internet connectivity status.
/// In a real app, this would use connectivity_plus or a similar package.
/// For now, we default to true.
final isOnlineProvider = Provider<bool>((ref) {
  return true;
});
