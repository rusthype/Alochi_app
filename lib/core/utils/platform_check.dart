import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

bool get isWeb => kIsWeb;
bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
bool get isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
bool get isTablet => isMobile && _isTabletSize();

bool _isTabletSize() {
  final views = WidgetsBinding.instance.platformDispatcher.views;
  if (views.isEmpty) return false;
  final view = views.first;
  final size = view.physicalSize / view.devicePixelRatio;
  return size.shortestSide >= 600;
}
