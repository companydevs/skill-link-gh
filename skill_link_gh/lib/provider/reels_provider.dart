// core/providers.dart or lib/data/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:skill_link_gh/data/repository/reels_repositoty.dart';
import 'package:skill_link_gh/domain/models/reel_model.dart';
import 'package:skill_link_gh/notifier/reels_notifier.dart';

// Repository Provider (singleton)
final reelsRepositoryProvider = Provider<ReelsRepository>((ref) {
  return ReelsRepository();
});

// Reels State Notifier Provider
final reelsNotifierProvider = StateNotifierProvider<ReelsNotifier, AsyncValue<List<Reel>>>((ref) {
  final repository = ref.watch(reelsRepositoryProvider);
  return ReelsNotifier(repository);
});