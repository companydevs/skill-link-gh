import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../data/repository/chat_repository.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import 'in_app_messaging.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmerAnim = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ChatRepository();
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: CustomAppBar(title: 'Messages', variant: AppBarVariant.standard),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 3),
      body: StreamBuilder<QuerySnapshot>(
        stream: repo.conversationsStream(),
        builder: (context, snapshot) {
          // Show shimmer while waiting OR on first empty snapshot that hasn't settled
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final hasData = snapshot.hasData;

          if (isLoading ||
              (!hasData &&
                  snapshot.connectionState != ConnectionState.active)) {
            return _buildShimmer(theme);
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmpty(theme, context);
          }

          return _buildList(context, theme, docs, currentUid);
        },
      ),
    );
  }

  Widget _buildShimmer(ThemeData theme) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) {
        return ListView.separated(
          padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
          itemCount: 6,
          separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
          itemBuilder: (_, __) =>
              _ShimmerTile(anim: _shimmerAnim, theme: theme),
        );
      },
    );
  }

  Widget _buildEmpty(ThemeData theme, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 36,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'No messages yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            'Find an artisan and start a conversation',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.searchAndDiscovery),
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('Find Artisans'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    ThemeData theme,
    List<QueryDocumentSnapshot> docs,
    String currentUid,
  ) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      itemCount: docs.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 18.w,
        color: theme.colorScheme.outline.withValues(alpha: 0.15),
      ),
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUid = participants.firstWhere(
          (id) => id != currentUid,
          orElse: () => '',
        );

        final names = data['participantNames'] as Map<String, dynamic>?;
        final avatars = data['participantAvatars'] as Map<String, dynamic>?;
        final otherName = names?[otherUid] as String? ?? 'User';
        final otherAvatar = avatars?[otherUid] as String? ?? '';
        final lastMessage = data['lastMessage'] as String? ?? '';
        final lastTime = data['lastMessageTime'] as Timestamp?;
        final unread =
            (data['unreadCount'] as Map<String, dynamic>?)?[currentUid]
                as int? ??
            0;

        return ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: 4.w,
            vertical: 0.5.h,
          ),
          leading: CircleAvatar(
            radius: 6.w,
            backgroundImage: otherAvatar.isNotEmpty
                ? NetworkImage(otherAvatar)
                : null,
            child: otherAvatar.isEmpty
                ? Text(otherName.isNotEmpty ? otherName[0].toUpperCase() : '?')
                : null,
          ),
          title: Text(
            otherName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: unread > 0
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lastTime != null)
                Text(
                  _formatDate(lastTime.toDate()),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: unread > 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (unread > 0) ...[
                SizedBox(height: 0.5.h),
                Container(
                  padding: EdgeInsets.all(1.w),
                  constraints: BoxConstraints(minWidth: 5.w, minHeight: 5.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 9.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.inAppMessagingScreen,
            arguments: ChatArgs(
              otherUserId: otherUid,
              otherUserName: otherName,
              otherUserAvatar: otherAvatar,
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final p = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $p';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}/${dt.year.toString().substring(2)}';
    }
  }
}

// ── Shimmer tile ──────────────────────────────────────────────────────────────
class _ShimmerTile extends StatelessWidget {
  final Animation<double> anim;
  final ThemeData theme;

  const _ShimmerTile({required this.anim, required this.theme});

  Widget _box(double w, double h, {double r = 8, bool circle = false}) {
    final base = theme.colorScheme.surfaceContainerHighest;
    final highlight = theme.colorScheme.surface;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: circle ? null : BorderRadius.circular(r),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        gradient: LinearGradient(
          begin: Alignment(anim.value - 1, 0),
          end: Alignment(anim.value, 0),
          colors: [base, highlight, base],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _box(12.w, 12.w, circle: true),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(30.w, 1.6.h),
              SizedBox(height: 0.8.h),
              _box(50.w, 1.3.h),
            ],
          ),
        ),
        SizedBox(width: 2.w),
        _box(12.w, 1.2.h),
      ],
    );
  }
}
