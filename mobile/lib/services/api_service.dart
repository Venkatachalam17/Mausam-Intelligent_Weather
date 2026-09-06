import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class ApiService {
  // 🧭 Set this to TRUE if you want to test your live Render cloud URL while debugging!
  // Set it to FALSE if you want to use your local machine backend.
  static const bool _forceCloudInDebug = false;

  static String get _baseUrl {
    if (kDebugMode && !_forceCloudInDebug) {
      if (kIsWeb) {
        return 'http://127.0.0.1:8000';
      } else if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000'; // Android Emulator local IP
      } else {
        return 'http://127.0.0.1:8000';
      }
    }
    // Automatically uses Render when in release mode or if forced
    return 'https://mausam-intelligent-weather.onrender.com';
  }

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await dio.get('/health');
      return response.data;
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }
}
