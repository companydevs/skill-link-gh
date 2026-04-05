import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:skill_link_gh/data/repository/reels_repositoty.dart';
import 'package:skill_link_gh/domain/models/reel_model.dart';
import 'package:skill_link_gh/notifier/reels_notifier.dart';
import 'package:skill_link_gh/provider/backend_provider.dart';

final reelsRepositoryProvider = Provider<ReelsRepository>((ref) {
  return ReelsRepository();
});

final reelsNotifierProvider =
    StateNotifierProvider<ReelsNotifier, AsyncValue<List<Reel>>>((ref) {
      final repository = ref.watch(reelsRepositoryProvider);
      final backend = ref.watch(backendApiServiceProvider);
      return ReelsNotifier(repository, backend);
    });
