import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:skill_link_gh/data/repository/comments_repository.dart';
import 'package:skill_link_gh/domain/models/comment_model.dart';
import 'package:skill_link_gh/notifier/comments_notifier.dart';

// Repository Provider
final commentsRepositoryProvider = Provider<CommentsRepository>((ref) {
  return CommentsRepository();
});

// Comments Notifier Provider Factory
final commentsNotifierProvider =
    StateNotifierProvider.family<
      CommentsNotifier,
      AsyncValue<List<Comment>>,
      String
    >((ref, reelId) {
      final repository = ref.watch(commentsRepositoryProvider);
      return CommentsNotifier(repository, reelId);
    });
