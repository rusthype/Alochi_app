import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'app/app.dart';
import 'core/services/fcm_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Keep splash screen until app is ready
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // Initialize Firebase (safely)
    await Firebase.initializeApp();
    // Initialize FCM Service
    await FCMService().initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // App continues without FCM
  }

  runApp(
    const ProviderScope(
      child: AlochiApp(),
    ),
  );

  // Remove splash screen after first frame
  FlutterNativeSplash.remove();
}
