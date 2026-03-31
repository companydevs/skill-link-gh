import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_link_gh/data/repository/profile_repository.dart';

// Repository Provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

class ProfileState {
  final Map<String, dynamic>? profileData;
  final List<Map<String, dynamic>> portfolioImages;
  final List<Map<String, dynamic>> reviews;
  final List<Map<String, dynamic>> services;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isLoading;
  final String? error;

  ProfileState({
    this.profileData,
    this.portfolioImages = const [],
    this.reviews = const [],
    this.services = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    Map<String, dynamic>? profileData,
    List<Map<String, dynamic>>? portfolioImages,
    List<Map<String, dynamic>>? reviews,
    List<Map<String, dynamic>>? services,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profileData: profileData ?? this.profileData,
      portfolioImages: portfolioImages ?? this.portfolioImages,
      reviews: reviews ?? this.reviews,
      services: services ?? this.services,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  ProfileState build() {
    Future.microtask(() => loadProfile());
    return ProfileState(isLoading: true);
  }

  Future<void> loadProfile() async {
    // Keep existing data visible while refreshing — only show loading if no data yet
    state = state.copyWith(isLoading: true, error: null);

    try {
      final profileData = await _repository.getCurrentUserProfile();

      if (profileData == null) {
        state = state.copyWith(isLoading: false, error: 'Profile not found');
        return;
      }

      final userId = profileData['id'] as String;

      final results = await Future.wait([
        _repository.getPortfolioImages(userId),
        _repository.getReviews(userId),
        _repository.getServices(userId),
      ]);

      final socialCounts = await _repository.getSocialCounts(userId);

      state = ProfileState(
        profileData: profileData,
        portfolioImages: results[0],
        reviews: results[1],
        services: results[2],
        followersCount: socialCounts['followers'] ?? 0,
        followingCount: socialCounts['following'] ?? 0,
        postsCount: socialCounts['posts'] ?? 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshProfile() async {
    await loadProfile();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _repository.updateProfile(data);
      await loadProfile(); // Reload to get updated data
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
