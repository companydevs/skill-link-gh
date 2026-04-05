import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Central service for all calls to the Spring Boot recommendation backend.
/// Base URL should point to your backend — update for production deployment.
class BackendApiService {
  static const String _baseUrl = 'http://10.0.2.2:8080'; // Android emulator
  // static const String _baseUrl = 'http://localhost:8080'; // iOS simulator
  // static const String _baseUrl = 'https://your-production-url.com'; // prod

  late final Dio _dio;

  BackendApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    // Attach Firebase ID token to every request automatically
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await FirebaseAuth.instance.currentUser?.getIdToken(
              false,
            ); // false = use cached token
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            log('BackendApiService: failed to get Firebase token: $e');
          }
          handler.next(options);
        },
        onError: (error, handler) {
          log(
            'BackendApiService error: ${error.response?.statusCode} ${error.message}',
          );
          return handler.next(error);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Feed endpoints
  // ---------------------------------------------------------------------------

  /// Fetch personalised ranked posts from the recommendation engine.
  /// Returns raw JSON list — mapped by the caller.
  Future<List<Map<String, dynamic>>> getRecommendedPosts({
    double? lat,
    double? lng,
    double? radiusKm,
    String? lastContentId,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/api/feed/posts',
        queryParameters: {
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (radiusKm != null) 'radiusKm': radiusKm,
          if (lastContentId != null) 'lastContentId': lastContentId,
          'pageSize': pageSize,
        },
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      log('getRecommendedPosts failed: $e');
      return []; // fall back to Firestore feed
    }
  }

  /// Fetch personalised ranked reels from the recommendation engine.
  Future<List<Map<String, dynamic>>> getRecommendedReels({
    double? lat,
    double? lng,
    double? radiusKm,
    String? lastContentId,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/api/feed/reels',
        queryParameters: {
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (radiusKm != null) 'radiusKm': radiusKm,
          if (lastContentId != null) 'lastContentId': lastContentId,
          'pageSize': pageSize,
        },
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      log('getRecommendedReels failed: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Interaction tracking
  // ---------------------------------------------------------------------------

  /// Record a user interaction — fires and forgets (non-blocking).
  void trackInteraction({
    required String contentId,
    required String contentType, // 'POST' or 'REEL'
    required String interactionType, // 'LIKE','VIEW','SKIP','SAVE','BOOK', etc.
    int? watchSeconds,
  }) {
    _dio
        .post(
          '/api/interactions',
          data: {
            'contentId': contentId,
            'contentType': contentType,
            'interactionType': interactionType,
            if (watchSeconds != null) 'watchSeconds': watchSeconds,
          },
        )
        .catchError((e) {
          log('trackInteraction failed (non-fatal): $e');
        });
  }
}
