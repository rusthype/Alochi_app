import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
}
