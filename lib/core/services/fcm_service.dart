import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../api/teacher_api.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  static bool _firebaseAvailable = false;
  FirebaseMessaging? _messaging;

  bool get isAvailable => _firebaseAvailable;

  Future<void> initialize() async {
    if (kIsWeb) return; // V1.1 is Android-only

    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        // We don't initialize here to keep main.dart clean, 
        // but we check availability.
        debugPrint('FCM: Firebase not initialized in main.dart');
        return;
      }

      _firebaseAvailable = true;
      _messaging = FirebaseMessaging.instance;

      // Request permission (Android 13+)
      await _messaging?.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      debugPrint('FCM: Initialized successfully');
    } catch (e) {
      debugPrint('FCM: Initialization error: $e');
      _firebaseAvailable = false;
    }
  }

  Future<String?> getToken() async {
    if (!_firebaseAvailable || _messaging == null) return null;
    try {
      return await _messaging?.getToken();
    } catch (e) {
      debugPrint('FCM: Get token error: $e');
      return null;
    }
  }

  Future<void> registerToken(TeacherApi api) async {
    if (!_firebaseAvailable) return;
    try {
      final token = await getToken();
      if (token == null) {
        debugPrint('FCM: No token available for registration');
        return;
      }
      await api.registerFCMToken(token);
      debugPrint('FCM: Token registered with backend');
    } catch (e) {
      debugPrint('FCM: Register error: $e');
    }
  }

  Future<void> unregisterToken(TeacherApi api) async {
    if (!_firebaseAvailable || _messaging == null) return;
    try {
      final token = await getToken();
      if (token != null) {
        await api.unregisterFCMToken(token);
      }
      await _messaging?.deleteToken();
      debugPrint('FCM: Token unregistered from backend');
    } catch (e) {
      debugPrint('FCM: Unregister error: $e');
    }
  }
}
