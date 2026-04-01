import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:skill_link_gh/domain/models/local_comment.dart';
import 'package:skill_link_gh/domain/models/post_model.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';

import 'widgets/comment_item_widget.dart';
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
  final FocusNode _focusNode = FocusNode();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<LocalComment> _comments = [];
  DocumentSnapshot? _lastDoc;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isPosting = false;

  String? _replyingToCommentId;
  String? _replyingToUserName;
  String? _currentUserAvatar; // loaded from Firestore

  static const int _pageSize = 20;

  // Quick-react emojis (Instagram style)
  static const _quickEmojis = ['❤️', '🙌', '🔥', '👏', '😢', '😍', '😮', '😂'];

  @override
  void initState() {
    super.initState();
    _loadComments();
    _loadCurrentUserAvatar();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Load current user avatar from Firestore ───────────────────────────────
  Future<void> _loadCurrentUserAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final url =
          doc.data()?['profileImage'] as String? ??
          doc.data()?['photoUrl'] as String? ??
          user.photoURL;
      if (mounted && url != null && url.isNotEmpty) {
        setState(() => _currentUserAvatar = url);
      }
    } catch (_) {}
  }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> _loadComments({bool refresh = false}) async {
    if (refresh) {
      _comments.clear();
      _lastDoc = null;
      _hasMore = true;
      if (mounted) setState(() => _isLoading = true);
    }
    if (!_hasMore) return;

    Query query = _firestore
        .collection('posts')
        .doc(widget.post.id)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .limit(_pageSize);

    if (_lastDoc != null) query = query.startAfterDocument(_lastDoc!);

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

  // ── Comment tree ──────────────────────────────────────────────────────────
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
      ordered.add(parent.copyWith(level: level == 0 ? 0 : 1));
      final replies = repliesMap[parent.id];
      if (replies != null && parent.isExpanded) {
        for (final r in replies) addReplies(r, level + 1);
      }
    }

    for (final p in parents) addReplies(p, 0);
    return ordered;
  }

  // ── Like ──────────────────────────────────────────────────────────────────
  Future<void> _onLikeComment(String commentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;
    final comment = _comments[index];
    final isLiked = comment.likes.contains(user.uid);
    setState(() {
      isLiked ? comment.likes.remove(user.uid) : comment.likes.add(user.uid);
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

  // ── Reply ─────────────────────────────────────────────────────────────────
  void _onReplyComment(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
    });
    _commentController.text = '@$userName ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
    _commentController.clear();
  }

  // ── Toggle replies ────────────────────────────────────────────────────────
  void _toggleReplies(String commentId) {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;
    setState(() {
      _comments[index] = _comments[index].copyWith(
        isExpanded: !_comments[index].isExpanded,
      );
    });
  }

  // ── Post comment ──────────────────────────────────────────────────────────
  Future<void> _onPostComment(String text) async {
    if (text.trim().isEmpty || _isPosting) return;
    _isPosting = true;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isPosting = false;
      return;
    }

    try {
      final ref = _firestore
          .collection('posts')
          .doc(widget.post.id)
          .collection('comments')
          .doc();

      await ref.set({
        'id': ref.id,
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userAvatar':
            user.photoURL ??
            'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
        'isVerified': false,
        'commentText': text,
        'likes': [],
        'replies': 0,
        'level': _replyingToCommentId == null ? 0 : 1,
        'parentId': _replyingToCommentId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (_replyingToCommentId != null) {
        await _firestore
            .collection('posts')
            .doc(widget.post.id)
            .collection('comments')
            .doc(_replyingToCommentId!)
            .update({'replies': FieldValue.increment(1)});
      }

      setState(() {
        _replyingToCommentId = null;
        _replyingToUserName = null;
      });
      _commentController.clear();
      _loadComments(refresh: true);
    } catch (e) {
      log('Error posting comment: $e');
    } finally {
      _isPosting = false;
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> _deleteComment(String commentId) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('deleteComment')
          .call({'postId': widget.post.id, 'commentId': commentId});

      if (result.data['success'] == true) {
        _comments.removeWhere((c) => c.id == commentId);
        if (mounted) {
          setState(() {});
          AppToast.show(
            context,
            message: result.data['message'] ?? 'Comment deleted',
            type: ToastType.success,
          );
        }
      } else {
        if (mounted) {
          AppToast.show(
            context,
            message: result.data['message'] ?? 'Failed to delete',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Failed to delete comment: $e',
          type: ToastType.error,
        );
      }
    }
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 52) return '${(diff.inDays / 7).floor()}w';
    return DateFormat('MMM d').format(dt);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final ordered = _buildCommentTree(_comments);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Comments',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.near_me_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Post caption header (like Instagram) ──────────────────────────
          _PostCaptionHeader(post: widget.post, formatTime: _formatTimestamp),
          const Divider(height: 1),

          // ── Comments list ─────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const CommentShimmerWidget()
                : RefreshIndicator(
                    onRefresh: () => _loadComments(refresh: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      itemCount: ordered.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == ordered.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final c = ordered[i];
                        final isLiked =
                            currentUser != null &&
                            c.likes.contains(currentUser.uid);
                        return CommentItemWidget(
                          commentOwnerId: c.userId,
                          commentId: c.id,
                          userName: c.userName,
                          userAvatar: c.userAvatar,
                          isVerified: c.isVerified,
                          timestamp: _formatTimestamp(c.createdAt),
                          commentText: c.commentText,
                          likes: c.likes.length,
                          replies: c.replies,
                          isLiked: isLiked,
                          level: c.level,
                          onLike: () => _onLikeComment(c.id),
                          onReply: () => _onReplyComment(c.id, c.userName),
                          onReport: () => AppToast.show(
                            context,
                            message: 'Comment reported',
                            type: ToastType.success,
                          ),
                          onToggleReplies: c.replies > 0
                              ? () => _toggleReplies(c.id)
                              : null,
                          onDelete: currentUser?.uid == c.userId
                              ? () => _deleteComment(c.id)
                              : null,
                        );
                      },
                    ),
                  ),
          ),

          // ── Quick emoji row ───────────────────────────────────────────────
          _QuickEmojiRow(
            emojis: _quickEmojis,
            onTap: (e) {
              _commentController.text += e;
              _commentController.selection = TextSelection.fromPosition(
                TextPosition(offset: _commentController.text.length),
              );
              _focusNode.requestFocus();
            },
          ),

          // ── Reply banner ──────────────────────────────────────────────────
          if (_replyingToUserName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Text(
                    'Replying to ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '@$_replyingToUserName',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // ── Composer ──────────────────────────────────────────────────────
          _IGComposer(
            controller: _commentController,
            focusNode: _focusNode,
            isPosting: _isPosting,
            currentUserAvatar: _currentUserAvatar,
            onPost: _onPostComment,
          ),
        ],
      ),
    );
  }
}

// ── Post caption header ───────────────────────────────────────────────────────
class _PostCaptionHeader extends StatelessWidget {
  final PostModel post;
  final String Function(DateTime?) formatTime;

  const _PostCaptionHeader({required this.post, required this.formatTime});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = post.artisanImage.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            backgroundImage: hasImage ? NetworkImage(post.artisanImage) : null,
            child: !hasImage
                ? Text(
                    post.artisanName.isNotEmpty
                        ? post.artisanName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '${post.artisanName}  ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: post.description),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatTime(post.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick emoji row ───────────────────────────────────────────────────────────
class _QuickEmojiRow extends StatelessWidget {
  final List<String> emojis;
  final ValueChanged<String> onTap;

  const _QuickEmojiRow({required this.emojis, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: emojis
            .map(
              (e) => GestureDetector(
                onTap: () => onTap(e),
                child: Text(e, style: const TextStyle(fontSize: 26)),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Instagram-style composer ──────────────────────────────────────────────────
class _IGComposer extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isPosting;
  final String? currentUserAvatar;
  final Function(String) onPost;

  const _IGComposer({
    required this.controller,
    required this.focusNode,
    required this.isPosting,
    required this.currentUserAvatar,
    required this.onPost,
  });

  @override
  State<_IGComposer> createState() => _IGComposerState();
}

class _IGComposerState extends State<_IGComposer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 20,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Current user avatar
            CircleAvatar(
              radius: 17,
              backgroundImage: widget.currentUserAvatar != null
                  ? NetworkImage(widget.currentUserAvatar!)
                  : null,
              child: widget.currentUserAvatar == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 10),
            // Input field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Post button — only visible when there's text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: _hasText
                  ? GestureDetector(
                      key: const ValueKey('post'),
                      onTap: widget.isPosting
                          ? null
                          : () => widget.onPost(widget.controller.text),
                      child: widget.isPosting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : Text(
                              'Post',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    )
                  : const SizedBox(key: ValueKey('empty'), width: 0),
            ),
          ],
        ),
      ),
    );
  }
}
