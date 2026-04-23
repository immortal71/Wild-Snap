import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Update this to your production API URL (use HTTPS in production)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );
  static const String _tokenKey = 'auth_token';

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ── Auth ──────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    try {
      final response = await _dio.post('/auth/google', data: {'id_token': idToken});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/refresh', data: {'refresh_token': refreshToken});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Users ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/users/me');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/users/me', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Animals ───────────────────────────────────────────

  Future<Map<String, dynamic>> getAnimals({
    int page = 1,
    int limit = 20,
    String? category,
    String? rarity,
  }) async {
    try {
      final response = await _dio.get('/animals', queryParameters: {
        'page': page,
        'limit': limit,
        if (category != null) 'category': category,
        if (rarity != null) 'rarity': rarity,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> searchAnimals(String query) async {
    try {
      final response = await _dio.get('/animals/search', queryParameters: {'q': query});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getNearbyAnimals(double lat, double lng) async {
    try {
      final response = await _dio.get('/animals/nearby', queryParameters: {
        'lat': lat,
        'lng': lng,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAnimalById(String id) async {
    try {
      final response = await _dio.get('/animals/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Sightings ─────────────────────────────────────────

  Future<Map<String, dynamic>> submitSighting({
    required String imagePath,
    required double latitude,
    required double longitude,
    required DateTime capturedAt,
    String? notes,
  }) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(imagePath, filename: 'sighting.jpg'),
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'captured_at': capturedAt.toIso8601String(),
        if (notes != null) 'notes': notes,
      });
      final response = await _dio.post('/sightings', data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMySightings({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get('/sightings/my', queryParameters: {
        'page': page,
        'limit': limit,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMyCollection() async {
    try {
      final response = await _dio.get('/sightings/collection');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Leaderboard ───────────────────────────────────────

  Future<Map<String, dynamic>> getGlobalLeaderboard({
    String period = 'alltime',
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get('/leaderboard/global', queryParameters: {
        'period': period,
        'limit': limit,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCountryLeaderboard({
    required String country,
    String period = 'alltime',
  }) async {
    try {
      final response = await _dio.get('/leaderboard/country/$country', queryParameters: {
        'period': period,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data['error'] != null) {
        return data['error'].toString();
      }
      return 'Server error: ${e.response!.statusCode}';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your internet connection.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Unable to connect to server.';
    }
    return e.message ?? 'An unexpected error occurred.';
  }
}
