import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import 'package:skill_link_gh/domain/models/local_comment.dart';
import 'package:skill_link_gh/domain/models/post_model.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';

import 'widgets/comment_composer_widget.dart';
import 'widgets/comment_item_widget.dart';
import 'widgets/comment_sort_dropdown_widget.dart';
import 'widgets/post_context_header_widget.dart';
import 'widgets/comment_shimmer_widget_screen.dart';

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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<LocalComment> _comments = [];
  DocumentSnapshot? _lastDoc;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  String _sortBy = 'newest';
  static const int _pageSize = 20;

  // 🔥 Reply state
  String? _replyingToCommentId;
  String? _replyingToUserName;

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

  // ===================== LOAD COMMENTS =====================
  Future<void> _loadComments({bool refresh = false}) async {
    if (refresh) {
      _comments.clear();
      _lastDoc = null;
      _hasMore = true;
      _isLoading = true;
      if (mounted) setState(() {});
    }

    if (!_hasMore) return;

    Query query = _firestore
        .collection('posts')
        .doc(widget.post.id)
        .collection('comments')
        .orderBy('createdAt', descending: _sortBy == 'newest')
        .limit(_pageSize);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();
    if (!mounted) return;

    if (snapshot.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snapshot.docs.last;
      _comments.addAll(snapshot.docs.map(LocalComment.fromDoc));
    }

    setState(() {
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 120 &&
        !_isLoadingMore &&
        _hasMore) {
      _isLoadingMore = true;
      _loadComments();
    }
  }

  // ===================== BUILD COMMENT TREE WITH FIXED REPLY INDENT =====================
  List<LocalComment> _buildCommentTree(List<LocalComment> comments) {
    final Map<String, List<LocalComment>> repliesMap = {};
    final List<LocalComment> parents = [];

    for (final c in comments) {
      if (c.parentId == null) {
        parents.add(c);
      } else {
        repliesMap.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }

    final List<LocalComment> ordered = [];

    void addReplies(LocalComment parent, int level) {
      // Cap level at 1 for all replies beyond the first level
      final displayLevel = level == 0 ? 0 : 1;
      ordered.add(parent.copyWith(level: displayLevel));

      final replies = repliesMap[parent.id];
      if (replies != null && parent.isExpanded) {
        for (final r in replies) {
          addReplies(r, level + 1);
        }
      }
    }

    for (final parent in parents) {
      addReplies(parent, 0);
    }

    return ordered;
  }

  // ===================== LIKE / UNLIKE =====================
  Future<void> _onLikeComment(String commentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final comment = _comments[index];
    final isLiked = comment.likes.contains(user.uid);

    setState(() {
      isLiked
          ? comment.likes.remove(user.uid)
          : comment.likes.add(user.uid);
    });

    await _firestore
        .collection('posts')
        .doc(widget.post.id)
        .collection('comments')
        .doc(commentId)
        .update({
      'likes': isLiked
          ? FieldValue.arrayRemove([user.uid])
          : FieldValue.arrayUnion([user.uid]),
    });
  }

  // ===================== REPLY =====================
  void _onReplyComment(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
    });

    _commentController.text = '@$userName ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
  }

  // ===================== TOGGLE REPLIES =====================
  void _toggleReplies(String commentId) {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    setState(() {
      _comments[index] = _comments[index].copyWith(
        isExpanded: !_comments[index].isExpanded,
      );
    });
  }

  // ===================== POST COMMENT =====================
  Future<void> _onPostComment(String text) async {
    if (text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = _firestore
        .collection('posts')
        .doc(widget.post.id)
        .collection('comments')
        .doc();

    await ref.set({
      'id': ref.id,
      'userId': user.uid,
      'userName': user.displayName ?? 'Anonymous',
      'userAvatar': user.photoURL ??
          'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
      'isVerified': false,
      'commentText': text,
      'likes': [],
      'replies': 0,
      'level': _replyingToCommentId == null ? 0 : 1,
      'parentId': _replyingToCommentId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // increment parent reply count
    if (_replyingToCommentId != null) {
      await _firestore
          .collection('posts')
          .doc(widget.post.id)
          .collection('comments')
          .doc(_replyingToCommentId!)
          .update({
        'replies': FieldValue.increment(1),
      });
    }

    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });

    _commentController.clear();
    _loadComments(refresh: true);
  }

Future<void> _deleteComment(String commentId) async {
  final functions = FirebaseFunctions.instance;

  try {
    // Call Cloud Function
    final result = await functions.httpsCallable('deleteComment').call({
      'postId': widget.post.id,
      'commentId': commentId,
    });

    if (result.data['success'] == true) {
      // Remove from local list immediately
      _comments.removeWhere((c) => c.id == commentId);

      setState(() {}); // update UI

      // ✅ Show success toast
      AppToast.show(
        context,
        message: result.data['message'] ?? 'Comment deleted along with replies',
        type: ToastType.success,
      );
    } else {
      // ✅ Show error toast
      AppToast.show(
        context,
        message: result.data['message'] ?? 'Failed to delete comment',
        type: ToastType.error,
      );
    }
  } catch (e) {
    // ✅ Show error toast
    if(!mounted) return;
    AppToast.show(
      context,
      message: 'Failed to delete comment: $e',
      type: ToastType.error,
    );
  }
}


  // ===================== FORMAT TIMESTAMP LIKE INSTA =====================
  String formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) return '${difference.inSeconds}s';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';

    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    final orderedComments = _buildCommentTree(_comments);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        actions: [
          CommentSortDropdownWidget(
            currentSort: _sortBy,
            onSortChanged: (v) {
              setState(() => _sortBy = v);
              _loadComments(refresh: true);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          PostContextHeaderWidget(
            postImageUrl: widget.post.postImages.first.url,
            postTitle: widget.post.description,
            postAuthor: widget.post.artisanName,
            postDate: formatTimestamp(widget.post.createdAt),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const CommentShimmerWidget()
                : RefreshIndicator(
                    onRefresh: () => _loadComments(refresh: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.only(top: 1.h),
                      itemCount:
                          orderedComments.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (_, index) {
                        if (index == orderedComments.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final c = orderedComments[index];
                        final isLiked = currentUser != null &&
                            c.likes.contains(currentUser.uid);

                        return CommentItemWidget(
                            commentOwnerId: c.userId, // ✅ add this

                          commentId: c.id,
                          userName: c.userName,
                          userAvatar: c.userAvatar,
                          isVerified: c.isVerified,
                          timestamp: formatTimestamp(c.createdAt),
                          commentText: c.commentText,
                          likes: c.likes.length,
                          replies: c.replies,
                          isLiked: isLiked,
                          level: c.level,
                          onLike: () => _onLikeComment(c.id),
                          onReply: () => _onReplyComment(c.id, c.userName),
                          onReport: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Comment reported')),
                            );
                          },
                          onToggleReplies:
                              c.replies > 0 ? () => _toggleReplies(c.id) : null,
                          onDelete: currentUser != null && currentUser.uid == c.userId
                              ? () => _deleteComment(c.id)
                              : null,
                        );
                      },
                    ),
                  ),
          ),
          if (_replyingToUserName != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              color: theme.colorScheme.surfaceVariant,
              child: Row(
                children: [
                  Text(
                    'Replying to @$_replyingToUserName',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _replyingToCommentId = null;
                        _replyingToUserName = null;
                      });
                      _commentController.clear();
                    },
                  ),
                ],
              ),
            ),
          CommentComposerWidget(
            controller: _commentController,
            onPost: _onPostComment,
          ),
        ],
      ),
    );
  }
}
