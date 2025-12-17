import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/domain/models/post_model.dart';
import 'package:skill_link_gh/presentation/posts_comments_detail_screen/widgets/comment_composer_widget.dart';
import 'package:skill_link_gh/presentation/posts_comments_detail_screen/widgets/comment_item_widget.dart';
import 'package:skill_link_gh/presentation/posts_comments_detail_screen/widgets/comment_sort_dropdown_widget.dart';
import 'package:skill_link_gh/presentation/posts_comments_detail_screen/widgets/post_context_header_widget.dart';

class PostCommentsDetailsScreen extends StatefulWidget {
  final PostModel post;
  const PostCommentsDetailsScreen({super.key, required this.post});

  @override
  State<PostCommentsDetailsScreen> createState() =>
      _PostCommentsDetailsScreenState();
}

class _PostCommentsDetailsScreenState extends State<PostCommentsDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();

  String _sortBy = 'newest';
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = 20;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot> _commentsDocs = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments({bool refresh = false}) async {
    if (refresh) {
      _commentsDocs.clear();
      _hasMore = true;
    }

    if (!_hasMore) return;

    Query query = _firestore
        .collection('posts')
        .doc(widget.post.id)
        .collection('comments')
        .orderBy('createdAt', descending: _sortBy == 'newest');

    if (_commentsDocs.isNotEmpty) {
      query = query.startAfterDocument(_commentsDocs.last);
    }

    final snapshot = await query.limit(_pageSize).get();
    if (snapshot.docs.isEmpty) {
      _hasMore = false;
    }

    // Avoid duplicates
    final newDocs = snapshot.docs
        .where((doc) => !_commentsDocs.any((existing) => existing.id == doc.id))
        .toList();

    setState(() {
      _commentsDocs.addAll(newDocs);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _hasMore) {
      _isLoadingMore = true;
      _loadComments().then((_) => _isLoadingMore = false);
    }
  }

  Future<void> _refreshComments() async {
    await _loadComments(refresh: true);
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    _refreshComments();
  }

  Future<void> _onPostComment(String text) async {
    if (text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final commentRef = _firestore
        .collection('posts')
        .doc(widget.post.id)
        .collection('comments')
        .doc();

    await commentRef.set({
      'id': commentRef.id,
      'userName': user.displayName ?? 'Anonymous',
      'userAvatar': user.photoURL ??
          'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
      'isVerified': false,
      'commentText': text,
      'likes': <String>[], // list of user IDs who liked
      'replies': 0,
      'level': 0,
      'parentId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
    _refreshComments();
  }

Future<void> _onLikeComment(String commentId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final commentRef = _firestore
      .collection('posts')
      .doc(widget.post.id)
      .collection('comments')
      .doc(commentId);

  final doc = await commentRef.get();
  if (!doc.exists) return;

  List likes = List.from(doc['likes'] ?? []);

  if (likes.contains(user.uid)) {
    // Remove user from likes
    likes.remove(user.uid);
  } else {
    // Add user to likes
    likes.add(user.uid);
  }

  try {
    await commentRef.update({'likes': likes});
    // Refresh local comments list
    _refreshComments();
  } catch (e) {
    print('Error updating like: $e');
  }
}

  void _onReplyComment(String commentId, String userName) {
    _commentController.text = '@$userName ';
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: BackButton(color: theme.colorScheme.onSurface),
        title: Text('Comments', style: theme.textTheme.titleLarge),
        actions: [
          CommentSortDropdownWidget(
            currentSort: _sortBy,
            onSortChanged: _onSortChanged,
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: Column(
        children: [
          // Post header
          PostContextHeaderWidget(
            postImageUrl: widget.post.postImages.first.url,
            postTitle: widget.post.description,
            postAuthor: widget.post.artisanName,
            postDate: widget.post.createdAt.toIso8601String(),
          ),
          Divider(height: 1, thickness: 1, color: theme.dividerColor),

          // Comments list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshComments,
              color: theme.colorScheme.primary,
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(vertical: 1.h),
                itemCount: _commentsDocs.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _commentsDocs.length) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(2.h),
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  }

                  final comment =
                      _commentsDocs[index].data() as Map<String, dynamic>;
                  final likesList = List<String>.from(comment['likes'] ?? []);
                  final isLiked =
                      currentUser != null && likesList.contains(currentUser.uid);

                  return CommentItemWidget(
                    commentId: comment['id'],
                    userName: comment['userName'],
                    userAvatar: comment['userAvatar'],
                    isVerified: comment['isVerified'],
                    timestamp: comment['createdAt'] != null
                        ? (comment['createdAt'] as Timestamp)
                            .toDate()
                            .toLocal()
                            .toString()
                        : 'Just now',
                    commentText: comment['commentText'],
                    likes: likesList.length,
                    replies: comment['replies'],
                    isLiked: isLiked,
                    level: comment['level'],
                    onLike: () => _onLikeComment(comment['id']),
                    onReply: () =>
                        _onReplyComment(comment['id'], comment['userName']),
                    onReport: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Comment reported'),
                          backgroundColor: theme.colorScheme.primary,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Comment composer
          CommentComposerWidget(
            controller: _commentController,
            onPost: _onPostComment,
          ),
        ],
      ),
    );
  }
}
