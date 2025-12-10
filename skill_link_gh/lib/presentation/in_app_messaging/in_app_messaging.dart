import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/widgets/custom_bottom_bar.dart';

import '../../core/app_export.dart';
import './widgets/message_bubble_widget.dart';
import './widgets/message_input_widget.dart';
import './widgets/typing_indicator_widget.dart';

/// In-App Messaging screen for secure communication between clients and artisans
/// Features real-time chat, voice messages, image sharing, and booking context integration
class InAppMessaging extends StatefulWidget {
  const InAppMessaging({super.key});

  @override
  State<InAppMessaging> createState() => _InAppMessagingState();
}

class _InAppMessagingState extends State<InAppMessaging> {
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isOnline = true;
  bool _isLoadingMore = false;

  final List<Map<String, dynamic>> _messages = [
    {
      "id": 1,
      "type": "text",
      "content": "Hi! I saw your carpentry work. Are you available next week?",
      "timestamp": "10:30 AM",
      "isCurrentUser": true,
      "status": "read",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_122f6d06e-1764690565988.png",
      "avatarLabel":
          "Profile photo of a woman with long brown hair wearing a white blouse",
    },
    {
      "id": 2,
      "type": "text",
      "content":
          "Hello! Yes, I have availability next week. What kind of work do you need?",
      "timestamp": "10:32 AM",
      "isCurrentUser": false,
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_10e32363d-1763295001957.png",
      "avatarLabel":
          "Profile photo of a man with short black hair wearing a blue shirt",
    },
    {
      "id": 3,
      "type": "text",
      "content":
          "I need custom kitchen cabinets installed. Can you handle that?",
      "timestamp": "10:33 AM",
      "isCurrentUser": true,
      "status": "read",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_122f6d06e-1764690565988.png",
      "avatarLabel":
          "Profile photo of a woman with long brown hair wearing a white blouse",
      "reaction": "👍",
    },
    {
      "id": 4,
      "type": "image",
      "imageUrl":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1785173a3-1765180551561.png",
      "imageLabel":
          "Modern white kitchen with wooden cabinets and marble countertops",
      "timestamp": "10:35 AM",
      "isCurrentUser": true,
      "status": "read",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_122f6d06e-1764690565988.png",
      "avatarLabel":
          "Profile photo of a woman with long brown hair wearing a white blouse",
    },
    {
      "id": 5,
      "type": "text",
      "content":
          "Absolutely! That's my specialty. The kitchen looks great. I can definitely work with that style.",
      "timestamp": "10:36 AM",
      "isCurrentUser": false,
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_10e32363d-1763295001957.png",
      "avatarLabel":
          "Profile photo of a man with short black hair wearing a blue shirt",
    },
    {
      "id": 6,
      "type": "voice",
      "duration": "0:45",
      "timestamp": "10:38 AM",
      "isCurrentUser": false,
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_10e32363d-1763295001957.png",
      "avatarLabel":
          "Profile photo of a man with short black hair wearing a blue shirt",
    },
    {
      "id": 7,
      "type": "text",
      "content": "Perfect! What's your rate and how long would it take?",
      "timestamp": "10:40 AM",
      "isCurrentUser": true,
      "status": "read",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_122f6d06e-1764690565988.png",
      "avatarLabel":
          "Profile photo of a woman with long brown hair wearing a white blouse",
    },
    {
      "id": 8,
      "type": "booking",
      "bookingData": {
        "service": "Custom Kitchen Cabinets Installation",
        "date": "December 18, 2025 at 9:00 AM",
        "status": "Confirmed",
      },
      "timestamp": "10:42 AM",
      "isCurrentUser": false,
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_10e32363d-1763295001957.png",
      "avatarLabel":
          "Profile photo of a man with short black hair wearing a blue shirt",
    },
    {
      "id": 9,
      "type": "text",
      "content":
          "Great! I've sent you a booking request with my estimate. It should take about 3 days.",
      "timestamp": "10:42 AM",
      "isCurrentUser": false,
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_10e32363d-1763295001957.png",
      "avatarLabel":
          "Profile photo of a man with short black hair wearing a blue shirt",
    },
    {
      "id": 10,
      "type": "text",
      "content": "Excellent! I've confirmed the booking. See you next week!",
      "timestamp": "10:45 AM",
      "isCurrentUser": true,
      "status": "delivered",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_122f6d06e-1764690565988.png",
      "avatarLabel":
          "Profile photo of a woman with long brown hair wearing a white blouse",
      "reaction": "❤️",
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMoreMessages();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadMoreMessages() async {
    
    if (_isLoadingMore) return;
    if (!mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    await Future.delayed(Duration(seconds: 1));
      if (!mounted) return;

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _handleSendMessage(String message) {
    setState(() {
      _messages.add({
        "id": _messages.length + 1,
        "type": "text",
        "content": message,
        "timestamp": _formatTime(DateTime.now()),
        "isCurrentUser": true,
        "status": "sent",
        "avatar":
            "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
        "avatarLabel":
            "Profile photo of a woman with long brown hair wearing a white blouse",
      });
    });

    _scrollToBottom();
    _simulateTyping();
  }

  void _handleSendImage(String imageUrl) {
    setState(() {
      _messages.add({
        "id": _messages.length + 1,
        "type": "image",
        "imageUrl": imageUrl,
        "imageLabel": "Shared image from gallery",
        "timestamp": _formatTime(DateTime.now()),
        "isCurrentUser": true,
        "status": "sent",
        "avatar":
            "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
        "avatarLabel":
            "Profile photo of a woman with long brown hair wearing a white blouse",
      });
    });

    _scrollToBottom();
  }

  void _handleSendVoice(String voiceId) {
    setState(() {
      _messages.add({
        "id": _messages.length + 1,
        "type": "voice",
        "duration": "0:15",
        "timestamp": _formatTime(DateTime.now()),
        "isCurrentUser": true,
        "status": "sent",
        "avatar":
            "https://img.rocket.new/generatedImages/rocket_gen_img_122f6d06e-1764690565988.png",
        "avatarLabel":
            "Profile photo of a woman with long brown hair wearing a white blouse",
      });
    });

    _scrollToBottom();
  }

  void _handleSendLocation() {
    setState(() {
      _messages.add({
        "id": _messages.length + 1,
        "type": "location",
        "locationName": "Accra Mall, Tetteh Quarshie Interchange",
        "timestamp": _formatTime(DateTime.now()),
        "isCurrentUser": true,
        "status": "sent",
        "avatar":
            "https://img.rocket.new/generatedImages/rocket_gen_img_122f6d06e-1764690565988.png",
        "avatarLabel":
            "Profile photo of a woman with long brown hair wearing a white blouse",
      });
    });

    _scrollToBottom();
  }

  void _simulateTyping() {
    setState(() {
      _isTyping = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _showMessageOptions(Map<String, dynamic> message) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 2.h),
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 3.h),
              _buildOptionTile(
                icon: 'content_copy',
                label: 'Copy',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _buildOptionTile(
                icon: 'reply',
                label: 'Reply',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _buildOptionTile(
                icon: 'delete_outline',
                label: 'Delete',
                color: theme.colorScheme.error,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _buildOptionTile(
                icon: 'flag_outlined',
                label: 'Report',
                color: theme.colorScheme.error,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final optionColor = color ?? theme.colorScheme.onSurface;

    return ListTile(
      leading: CustomIconWidget(
        iconName: icon,
        size: 24,
        color: optionColor,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: optionColor,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showReactionPicker(Map<String, dynamic> message) {
    final theme = Theme.of(context);
    final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 2.h),
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 3.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Wrap(
                  spacing: 4.w,
                  runSpacing: 2.h,
                  children: reactions.map((reaction) {
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          message['reaction'] = reaction;
                        });
                      },
                      child: Container(
                        width: 15.w,
                        height: 15.w,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            reaction,
                            style: TextStyle(fontSize: 24.sp),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 3.h),
            ],
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
        // leading: IconButton(
        //   onPressed: () => Navigator.pushNamed(context, AppRoutes.postsHomepage),

        //   icon: CustomIconWidget(
        //     iconName: 'arrow_back',
        //     size: 24,
        //     color: theme.colorScheme.onSurface,
        //   ),
        // ),
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
                    child: CustomImageWidget(
                      imageUrl:
                          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
                      width: 10.w,
                      height: 10.w,
                      fit: BoxFit.cover,
                      semanticLabel:
                          "Profile photo of a man with short black hair wearing a blue shirt",
                    ),
                  ),
                ),
                if (_isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 3.w,
                      height: 3.w,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
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
                    'Kwame Mensah',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isOnline ? 'Online' : 'Last seen 5 min ago',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _isOnline
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
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
          IconButton(
            onPressed: () {},
            icon: CustomIconWidget(
              iconName: 'more_vert',
              size: 24,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
       bottomNavigationBar: CustomBottomBar(
        currentIndex: 3,
      ),
      body: Column(
        children: [
          if (_isLoadingMore)
            Container(
              padding: EdgeInsets.symmetric(vertical: 1.h),
              child: Center(
                child: SizedBox(
                  width: 6.w,
                  height: 6.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMoreMessages,
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return TypingIndicatorWidget(userName: 'Kwame');
                  }

                  final message = _messages[index];
                  final isCurrentUser =
                      message['isCurrentUser'] as bool? ?? false;

                  return Slidable(
                    key: ValueKey(message['id']),
                    endActionPane: ActionPane(
                      motion: ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (context) => _showReactionPicker(message),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          icon: Icons.add_reaction,
                          label: 'React',
                        ),
                        SlidableAction(
                          onPressed: (context) {},
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                          icon: Icons.reply,
                          label: 'Reply',
                        ),
                      ],
                    ),
                    child: MessageBubbleWidget(
                      message: message,
                      isCurrentUser: isCurrentUser,
                      onLongPress: () => _showMessageOptions(message),
                    ),
                  );
                },
              ),
            ),
          ),
          MessageInputWidget(
            onSendMessage: _handleSendMessage,
            onSendImage: _handleSendImage,
            onSendVoice: _handleSendVoice,
            onSendLocation: _handleSendLocation,
          ),

          
        ],
        
      ),
    );
  }
}
