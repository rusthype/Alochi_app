import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kAvatarKey = 'local_avatar_b64';
const _storage = FlutterSecureStorage();

/// Provider for local avatar base64 — persists across restarts.
final localAvatarProvider =
    AsyncNotifierProvider<LocalAvatarNotifier, String?>(() {
  return LocalAvatarNotifier();
});

class LocalAvatarNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return _storage.read(key: _kAvatarKey);
  }

  Future<bool> pickAndSave() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (file == null) return false;

    final bytes = await File(file.path).readAsBytes();
    final b64 = base64Encode(bytes);
    await _storage.write(key: _kAvatarKey, value: b64);
    state = AsyncValue.data(b64);
    return true;
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAvatarKey);
    state = const AsyncValue.data(null);
  }
}

/// Displays avatar with local override support.
/// If local b64 is set, shows it. Otherwise falls back to initials.
class AlochiAvatarWithUpload extends ConsumerWidget {
  final String name;
  final double size;
  final bool editable;
  final VoidCallback? onTap;

  const AlochiAvatarWithUpload({
    super.key,
    required this.name,
    this.size = 80,
    this.editable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarAsync = ref.watch(localAvatarProvider);
    final b64 = avatarAsync.valueOrNull;

    Widget avatar;
    if (b64 != null && b64.isNotEmpty) {
      try {
        final bytes = base64Decode(b64);
        avatar = CircleAvatar(
          radius: size / 2,
          backgroundImage: MemoryImage(bytes),
          backgroundColor: const Color(0xFF1F6F65),
        );
      } catch (_) {
        avatar = _initialsAvatar(name, size);
      }
    } else {
      avatar = _initialsAvatar(name, size);
    }

    if (!editable) return avatar;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: BoxDecoration(
                color: const Color(0xFF1F6F65),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: size * 0.18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _initialsAvatar(String name, double size) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : 'U';

    final hash = name.codeUnits.fold(0, (a, b) => a + b);
    final colors = [
      const Color(0xFF1F6F65),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
    ];

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colors[hash % colors.length],
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
