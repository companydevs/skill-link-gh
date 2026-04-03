import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';

import '../../posts_comments_detail_screen/widgets/comment_item_widget.dart';
import '../../../domain/models/local_comment.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String reelId;
  final String reelAuthor;

  const CommentsBottomSheet({
    super.key,
    required this.reelId,
    required this.reelAuthor,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _firestore = FirebaseFirestore.instance;

  final List<LocalComment> _comments = [];
  bool _isLoading = true;
  bool _isPosting = false;

  String? _replyingToCommentId;
  String? _replyingToUserName;
  String? _currentUserAvatar;
  String? _currentUserName;

  static const _quickEmojis = ['❤️', '🙌', '🔥', '👏', '😢', '😍', '😮', '😂'];

  @override
  void initState() {
    super.initState();
    _loadComments();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final d = doc.data() ?? {};
      final url =
          d['profileImage'] as String? ??
          d['photoUrl'] as String? ??
          user.photoURL;
      final name = (d['fullName'] as String? ?? '').isNotEmpty
          ? d['fullName'] as String
          : (d['displayName'] as String? ?? user.displayName ?? '');
      if (mounted)
        setState(() {
          if (url != null && url.isNotEmpty) _currentUserAvatar = url;
          if (name.isNotEmpty) _currentUserName = name;
        });
    } catch (_) {}
  }

  Future<void> _loadComments({bool refresh = false}) async {
    if (refresh) {
      _comments.clear();
      if (mounted) setState(() => _isLoading = true);
    }

    try {
      // Fetch ALL comments for this reel, filter client-side
      // (Firestore doesn't support isNull queries on all SDK versions)
      final snap = await _firestore
          .collection('reels')
          .doc(widget.reelId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .get();

      if (!mounted) return;

      // Only top-level comments (no parentId)
      final topLevel = snap.docs.where((d) {
        final data = d.data();
        final pid = data['parentId'];
        return pid == null || pid == '';
      }).toList();

      final userIds = topLevel
          .map((d) => (d.data())['userId'] as String? ?? '')
          .toSet()
          .where((id) => id.isNotEmpty)
          .toList();

      final Map<String, String> avatarMap = {};
      final Map<String, String> nameMap = {};
      if (userIds.isNotEmpty) {
        final userDocs = await Future.wait(
          userIds.map((uid) => _firestore.collection('users').doc(uid).get()),
        );
        for (final doc in userDocs) {
          if (!doc.exists) continue;
          final d = doc.data()!;
          final img = (d['profileImage'] as String? ?? '').isNotEmpty
              ? d['profileImage'] as String
              : (d['photoUrl'] as String? ?? '');
          if (img.isNotEmpty) avatarMap[doc.id] = img;
          final name = (d['fullName'] as String? ?? '').isNotEmpty
              ? d['fullName'] as String
              : (d['displayName'] as String? ?? '');
          if (name.isNotEmpty) nameMap[doc.id] = name;
        }
      }

      final loaded = topLevel.map((doc) {
        final data = doc.data();
        // Handle both old schema (likes: int) and new schema (likes: List)
        final rawLikes = data['likes'];
        final likesList = rawLikes is List
            ? List<String>.from(rawLikes)
            : <String>[];
        return LocalComment(
          id: doc.id,
          parentId: null,
          userId: data['userId'] ?? '',
          userName: nameMap[data['userId']] ?? data['userName'] ?? 'Anonymous',
          userAvatar: avatarMap[data['userId']] ?? data['userAvatar'] ?? '',
          isVerified: data['isVerified'] ?? false,
          commentText: data['text'] ?? data['commentText'] ?? '',
          likes: likesList,
          replies: data['replyCount'] ?? data['replies'] ?? 0,
          level: 0,
          createdAt:
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isExpanded: false,
        );
      }).toList();

      if (mounted)
        setState(() {
          _comments
            ..clear()
            ..addAll(loaded);
          _isLoading = false;
        });
    } catch (e) {
      log('Error loading reel comments: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleReplies(String commentId) async {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final comment = _comments[index];
    final alreadyLoaded = _comments.any((c) => c.parentId == commentId);

    if (!comment.isExpanded && !alreadyLoaded) {
      try {
        final snap = await _firestore
            .collection('reels')
            .doc(widget.reelId)
            .collection('comments')
            .where('parentId', isEqualTo: commentId)
            .orderBy('timestamp', descending: false)
            .get();

        if (!mounted) return;

        final userIds = snap.docs
            .map((d) => (d.data())['userId'] as String? ?? '')
            .toSet()
            .where((id) => id.isNotEmpty)
            .toList();

        final Map<String, String> avatarMap = {};
        final Map<String, String> nameMap = {};
        if (userIds.isNotEmpty) {
          final userDocs = await Future.wait(
            userIds.map((uid) => _firestore.collection('users').doc(uid).get()),
          );
          for (final doc in userDocs) {
            if (!doc.exists) continue;
            final d = doc.data()!;
            final img = (d['profileImage'] as String? ?? '').isNotEmpty
                ? d['profileImage'] as String
                : (d['photoUrl'] as String? ?? '');
            if (img.isNotEmpty) avatarMap[doc.id] = img;
            final name = (d['fullName'] as String? ?? '').isNotEmpty
                ? d['fullName'] as String
                : (d['displayName'] as String? ?? '');
            if (name.isNotEmpty) nameMap[doc.id] = name;
          }
        }

        final replies = snap.docs.map((doc) {
          final data = doc.data();
          final rawLikes = data['likes'];
          final likesList = rawLikes is List
              ? List<String>.from(rawLikes)
              : <String>[];
          return LocalComment(
            id: doc.id,
            parentId: commentId,
            userId: data['userId'] ?? '',
            userName:
                nameMap[data['userId']] ?? data['userName'] ?? 'Anonymous',
            userAvatar: avatarMap[data['userId']] ?? data['userAvatar'] ?? '',
            isVerified: data['isVerified'] ?? false,
            commentText: data['text'] ?? data['commentText'] ?? '',
            likes: likesList,
            replies: 0,
            level: 1,
            createdAt:
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isExpanded: false,
          );
        }).toList();

        if (snap.docs.isNotEmpty) {
          setState(() {
            _comments.removeWhere((c) => c.parentId == commentId);
            _comments.insertAll(index + 1, replies);
            _comments[index] = _comments[index].copyWith(isExpanded: true);
          });
          return;
        }
      } catch (e) {
        log('Error loading reel replies: $e');
      }
    }

    setState(() {
      _comments[index] = _comments[index].copyWith(
        isExpanded: !_comments[index].isExpanded,
      );
    });
  }

  void _onReplyComment(String commentId, String userName) {
    final tapped = _comments.firstWhere(
      (c) => c.id == commentId,
      orElse: () => _comments.first,
    );
    final rootId = tapped.parentId ?? commentId;
    setState(() {
      _replyingToCommentId = rootId;
      _replyingToUserName = userName;
    });
    _commentController.text = '@$userName ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
    _focusNode.requestFocus();
  }

  Future<void> _onPostComment(String text) async {
    if (text.trim().isEmpty || _isPosting) return;
    _isPosting = true;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isPosting = false;
      return;
    }

    final userName = (_currentUserName?.isNotEmpty == true)
        ? _currentUserName!
        : user.displayName ?? 'Anonymous';
    final avatarUrl = _currentUserAvatar ?? '';
    final rootParentId = _replyingToCommentId;

    final ref = _firestore
        .collection('reels')
        .doc(widget.reelId)
        .collection('comments')
        .doc();

    // Optimistic insert
    final optimistic = LocalComment(
      id: ref.id,
      parentId: rootParentId,
      userId: user.uid,
      userName: userName,
      userAvatar: avatarUrl,
      isVerified: false,
      commentText: text,
      likes: [],
      replies: 0,
      level: rootParentId == null ? 0 : 1,
      createdAt: DateTime.now(),
      isExpanded: false,
    );

    setState(() {
      if (rootParentId == null) {
        _comments.add(optimistic);
      } else {
        final parentIdx = _comments.indexWhere((c) => c.id == rootParentId);
        if (parentIdx != -1) {
          int insertAt = parentIdx + 1;
          while (insertAt < _comments.length &&
              _comments[insertAt].parentId == rootParentId) {
            insertAt++;
          }
          _comments.insert(insertAt, optimistic);
          _comments[parentIdx] = _comments[parentIdx].copyWith(
            replies: _comments[parentIdx].replies + 1,
            isExpanded: true,
          );
        } else {
          _comments.add(optimistic);
        }
      }
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
    _commentController.clear();

    try {
      await ref.set({
        'userId': user.uid,
        'userName': userName,
        'userAvatar': avatarUrl,
        'isVerified': false,
        'text': text,
        'likes': [],
        'replyCount': 0,
        'parentId': rootParentId,
        'timestamp': FieldValue.serverTimestamp(),
        'reelId': widget.reelId,
      });

      if (rootParentId != null) {
        await _firestore
            .collection('reels')
            .doc(widget.reelId)
            .collection('comments')
            .doc(rootParentId)
            .update({'replyCount': FieldValue.increment(1)});
      } else {
        await _firestore.collection('reels').doc(widget.reelId).update({
          'comments': FieldValue.increment(1),
        });
      }
    } catch (e) {
      log('Error posting reel comment: $e');
      if (mounted) {
        setState(() => _comments.removeWhere((c) => c.id == ref.id));
        AppToast.show(
          context,
          message: 'Failed to post comment',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

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
    final ref = _firestore
        .collection('reels')
        .doc(widget.reelId)
        .collection('comments')
        .doc(commentId);
    await ref.update({
      'likes': isLiked
          ? FieldValue.arrayRemove([user.uid])
          : FieldValue.arrayUnion([user.uid]),
    });
  }

  Future<void> _deleteComment(String commentId) async {
    final idx = _comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;
    final removed = _comments[idx];
    setState(() => _comments.removeAt(idx));
    try {
      await _firestore
          .collection('reels')
          .doc(widget.reelId)
          .collection('comments')
          .doc(commentId)
          .delete();
      if (removed.parentId == null) {
        await _firestore.collection('reels').doc(widget.reelId).update({
          'comments': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      if (mounted) setState(() => _comments.insert(idx, removed));
    }
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }

  List<LocalComment> _buildTree() {
    final repliesMap = <String, List<LocalComment>>{};
    final parents = <LocalComment>[];
    for (final c in _comments) {
      if (c.parentId == null) {
        parents.add(c);
      } else {
        repliesMap.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }
    final ordered = <LocalComment>[];
    void add(LocalComment p, int lvl) {
      ordered.add(p.copyWith(level: lvl == 0 ? 0 : 1));
      if (p.isExpanded) {
        for (final r in repliesMap[p.id] ?? []) {
          add(r, lvl + 1);
        }
      }
    }

    for (final p in parents) {
      add(p, 0);
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final ordered = _buildTree();

    return Padding(
      // This pushes the entire sheet up when keyboard appears
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height:
            MediaQuery.of(context).size.height * 0.82 -
            MediaQuery.of(context).viewInsets.bottom,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Comments',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ordered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No comments yet',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to comment!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadComments(refresh: true),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        itemCount: ordered.length,
                        itemBuilder: (_, i) {
                          final c = ordered[i];
                          final isLiked =
                              currentUser != null &&
                              c.likes.contains(currentUser.uid);
                          final actualReplies = _comments
                              .where((r) => r.parentId == c.id)
                              .length;
                          final hasReplies = actualReplies > 0 || c.replies > 0;
                          return CommentItemWidget(
                            commentId: c.id,
                            commentOwnerId: c.userId,
                            userName: c.userName,
                            userAvatar: c.userAvatar,
                            isVerified: c.isVerified,
                            timestamp: _fmt(c.createdAt),
                            commentText: c.commentText,
                            likes: c.likes.length,
                            replies: actualReplies > 0
                                ? actualReplies
                                : c.replies,
                            isLiked: isLiked,
                            level: c.level,
                            isExpanded: c.isExpanded,
                            onLike: () => _onLikeComment(c.id),
                            onReply: () => _onReplyComment(c.id, c.userName),
                            onReport: () => AppToast.show(
                              context,
                              message: 'Comment reported',
                              type: ToastType.success,
                            ),
                            onToggleReplies: hasReplies && c.level == 0
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

            // Quick emojis
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.dividerColor, width: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _quickEmojis
                    .map(
                      (e) => GestureDetector(
                        onTap: () {
                          _commentController.text += e;
                          _commentController.selection =
                              TextSelection.fromPosition(
                                TextPosition(
                                  offset: _commentController.text.length,
                                ),
                              );
                          _focusNode.requestFocus();
                        },
                        child: Text(e, style: const TextStyle(fontSize: 26)),
                      ),
                    )
                    .toList(),
              ),
            ),

            // Reply banner
            if (_replyingToUserName != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
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
                      onTap: () => setState(() {
                        _replyingToCommentId = null;
                        _replyingToUserName = null;
                        _commentController.clear();
                      }),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

            // Composer
            _ReelComposer(
              controller: _commentController,
              focusNode: _focusNode,
              isPosting: _isPosting,
              currentUserAvatar: _currentUserAvatar,
              onPost: _onPostComment,
            ),
          ],
        ),
      ), // Container
    ); // Padding
  }
}

// ── Composer ──────────────────────────────────────────────────────────────────
class _ReelComposer extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isPosting;
  final String? currentUserAvatar;
  final Function(String) onPost;

  const _ReelComposer({
    required this.controller,
    required this.focusNode,
    required this.isPosting,
    required this.currentUserAvatar,
    required this.onPost,
  });

  @override
  State<_ReelComposer> createState() => _ReelComposerState();
}

class _ReelComposerState extends State<_ReelComposer> {
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
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 12),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundImage: NetworkImage(
                widget.currentUserAvatar?.isNotEmpty == true
                    ? widget.currentUserAvatar!
                    : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
              ),
            ),
            const SizedBox(width: 10),
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
