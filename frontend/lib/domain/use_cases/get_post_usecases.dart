

import 'package:skill_link_gh/data/repository/post_repository.dart';
import 'package:skill_link_gh/domain/models/post_model.dart';

class GetPostsUseCase {
  final PostRepository repository;

  GetPostsUseCase(this.repository);

  Future<List<PostModel>> call({dynamic startAfter}) async {
    return repository.fetchPosts(startAfter: startAfter);
  }
}
