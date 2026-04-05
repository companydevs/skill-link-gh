import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_link_gh/services/backend_api_service.dart';

/// Singleton provider for the Spring Boot backend API service.
final backendApiServiceProvider = Provider<BackendApiService>((ref) {
  return BackendApiService();
});
