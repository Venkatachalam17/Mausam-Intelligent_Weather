import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

class ApiService {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    } else if (Platform.isAndroid) {
      return 'http://192.168.0.101:8000'; // 🚀 Local Wi-Fi IPv4 address!
    } else {
      return 'http://127.0.0.1:8000';
    }
  }

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(
        seconds: 30,
      ), // 🚀 Increased to 30s so Gemini has time to respond
      receiveTimeout: const Duration(
        seconds: 30,
      ), // 🚀 Increased to 30s so it doesn't abort mid-stream
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
