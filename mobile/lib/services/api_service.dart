import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    // Use your local FastAPI URL (if testing on Chrome, localhost works perfectly)
    baseUrl: 'http://127.0.0.1:8000',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.data;
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }
}