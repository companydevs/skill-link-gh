import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/widgets/custom_bottom_bar.dart';

import '../../core/app_export.dart';
import '../../data/repository/chat_repository.dart';
import './widgets/message_bubble_widget.dart';
import './widgets/message_input_widget.dart';
import './widgets/typing_indicator_widget.dart';

/// Arguments passed when navigating to this screen
class ChatArgs {
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;

  const ChatArgs({
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
  });
}

class InAppMessaging extends StatefulWidget {
  const InAppMessaging({super.key});

  @override
  State<InAppMessaging> createState() => _InAppMessagingState();
}

class _InAppMessagingState extends State<InAppMessaging> {
  final ScrollController _scrollController = ScrollController();
  final ChatRepository _chatRepo = ChatRepository();

  late String _otherUid;
  late String _otherName;
  late String _otherAvatar;

  bool _isOtherTyping = false;
  StreamSubscription? _typingSubscription;
  Timer? _typingTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as ChatArgs?;

    if (args != null) {
      _otherUid = args.otherUserId;
      _otherName = args.otherUserName;
      _otherAvatar = args.otherUserAvatar;
    } else {
      // Fallback — should not happen in production
      _otherUid = '';
      _otherName = 'Unknown';
      _otherAvatar = '';
    }

    if (_otherUid.isNotEmpty) {
      _chatRepo
          .ensureConversation(
            otherUid: _otherUid,
            otherName: _otherName,
            otherAvatar: _otherAvatar,
          )
          .then((_) => _chatRepo.markAsRead(_otherUid));

      _typingSubscription = _chatRepo.typingStream(_otherUid).listen((snap) {
        if (!snap.exists) return;
        final data = snap.data() as Map<String, dynamic>?;
        final typing = data?['typing'] as Map<String, dynamic>?;
        final val = typing?[_otherUid] as bool? ?? false;
        if (mounted && val != _isOtherTyping) {
          setState(() => _isOtherTyping = val);
        }
      });
    }
  }

  @override
  void dispose() {
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    if (_otherUid.isNotEmpty) {
      _chatRepo.setTyping(_otherUid, false);
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage(String text) async {
    if (_otherUid.isEmpty) return;
    await _chatRepo.sendMessage(otherUid: _otherUid, content: text);
    _chatRepo.setTyping(_otherUid, false);
    _scrollToBottom();
  }

  Future<void> _handleSendImage(String imageUrl) async {
    if (_otherUid.isEmpty) return;
    await _chatRepo.sendMessage(
      otherUid: _otherUid,
      content: imageUrl,
      type: 'image',
      extra: {'imageUrl': imageUrl, 'imageLabel': 'Shared image'},
    );
    _scrollToBottom();
  }

  Future<void> _handleSendVoice(String voiceId) async {
    if (_otherUid.isEmpty) return;
    await _chatRepo.sendMessage(
      otherUid: _otherUid,
      content: voiceId,
      type: 'voice',
      extra: {'duration': '0:15'},
    );
    _scrollToBottom();
  }

  Future<void> _handleSendLocation() async {
    if (_otherUid.isEmpty) return;
    await _chatRepo.sendMessage(
      otherUid: _otherUid,
      content: 'Shared a location',
      type: 'location',
      extra: {'locationName': 'Shared location'},
    );
    _scrollToBottom();
  }

  void _onTypingChanged(bool isTyping) {
    _typingTimer?.cancel();
    _chatRepo.setTyping(_otherUid, isTyping);
    if (isTyping) {
      // Auto-clear typing after 3s of inactivity
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _chatRepo.setTyping(_otherUid, false);
      });
    }
  }

  Map<String, dynamic> _docToMessage(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isCurrentUser = data['senderId'] == currentUid;
    final ts = data['timestamp'] as Timestamp?;
    final time = ts != null ? _formatTime(ts.toDate()) : '';

    return {
      'id': doc.id,
      'type': data['type'] ?? 'text',
      'content': data['content'] ?? '',
      'timestamp': time,
      'isCurrentUser': isCurrentUser,
      'status': data['status'] ?? 'sent',
      'avatar': isCurrentUser
          ? (FirebaseAuth.instance.currentUser?.photoURL ?? '')
          : _otherAvatar,
      'avatarLabel': isCurrentUser ? 'You' : _otherName,
      // image
      if (data['imageUrl'] != null) 'imageUrl': data['imageUrl'],
      if (data['imageLabel'] != null) 'imageLabel': data['imageLabel'],
      // voice
      if (data['duration'] != null) 'duration': data['duration'],
      // location
      if (data['locationName'] != null) 'locationName': data['locationName'],
      // booking
      if (data['bookingData'] != null) 'bookingData': data['bookingData'],
    };
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  void _showMessageOptions(Map<String, dynamic> message) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 2.h),
              Container(
                width: 12.w,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 2.h),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'content_copy',
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('Copy'),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: message['content'] as String? ?? ''),
                  );
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'delete_outline',
                  size: 24,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () => Navigator.pop(context),
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  void _showReactionPicker(Map<String, dynamic> message) {
    final theme = Theme.of(context);
    final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Wrap(
              spacing: 4.w,
              runSpacing: 2.h,
              children: reactions.map((r) {
                return InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 14.w,
                    height: 14.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(r, style: TextStyle(fontSize: 22.sp)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: _otherAvatar.isNotEmpty
                        ? CustomImageWidget(
                            imageUrl: _otherAvatar,
                            width: 10.w,
                            height: 10.w,
                            fit: BoxFit.cover,
                            semanticLabel: 'Profile photo of $_otherName',
                          )
                        : CircleAvatar(
                            child: Text(
                              _otherName.isNotEmpty
                                  ? _otherName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isOtherTyping ? 'typing...' : '',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: CustomIconWidget(
              iconName: 'call',
              size: 24,
              color: theme.colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: CustomIconWidget(
              iconName: 'videocam',
              size: 24,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 3),
      body: Column(
        children: [
          Expanded(
            child: _otherUid.isEmpty
                ? const Center(child: Text('No conversation selected'))
                : StreamBuilder<QuerySnapshot>(
                    stream: _chatRepo.messagesStream(_otherUid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final messages = docs.map(_docToMessage).toList();

                      // Auto-scroll on new messages
                      if (docs.isNotEmpty) _scrollToBottom();

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconWidget(
                                iconName: 'chat_bubble_outline',
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Say hi to $_otherName',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        itemCount: messages.length + (_isOtherTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length && _isOtherTyping) {
                            return TypingIndicatorWidget(
                              userName: _otherName.split(' ').first,
                            );
                          }
                          final msg = messages[index];
                          return Slidable(
                            key: ValueKey(msg['id']),
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (_) => _showReactionPicker(msg),
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  icon: Icons.add_reaction,
                                  label: 'React',
                                ),
                                SlidableAction(
                                  onPressed: (_) {},
                                  backgroundColor: theme.colorScheme.secondary,
                                  foregroundColor:
                                      theme.colorScheme.onSecondary,
                                  icon: Icons.reply,
                                  label: 'Reply',
                                ),
                              ],
                            ),
                            child: MessageBubbleWidget(
                              message: msg,
                              isCurrentUser: msg['isCurrentUser'] as bool,
                              onLongPress: () => _showMessageOptions(msg),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          MessageInputWidget(
            onSendMessage: _handleSendMessage,
            onSendImage: _handleSendImage,
            onSendVoice: _handleSendVoice,
            onSendLocation: _handleSendLocation,
            onTypingChanged: _onTypingChanged,
          ),
        ],
      ),
    );
  }
}
