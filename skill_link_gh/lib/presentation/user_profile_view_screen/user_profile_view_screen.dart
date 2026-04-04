import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/user_avatar_widget.dart';

/// Read-only profile view for any user — opened when tapping a commenter's
/// avatar or name. Fetches the user's public data from Firestore by userId.
class UserProfileViewScreen extends StatefulWidget {
  final String userId;

  const UserProfileViewScreen({super.key, required this.userId});

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'User not found';
          _loading = false;
        });
        return;
      }

      final data = doc.data()!;
      data['id'] = doc.id;

      // Fetch their posts — no orderBy to avoid requiring a composite index
      final postsSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('artisanId', isEqualTo: widget.userId)
          .limit(12)
          .get();

      final posts = postsSnap.docs.map((d) {
        final p = d.data();
        p['id'] = d.id;
        return p;
      }).toList();

      if (mounted) {
        setState(() {
          _data = data;
          _posts = posts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = 'Failed to load profile';
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _data == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
        ),
        body: Center(child: Text(_error ?? 'Something went wrong')),
      );
    }

    final d = _data!;
    final name = d['fullName'] as String? ?? d['name'] as String? ?? 'User';
    final avatar =
        d['profileImage'] as String? ?? d['photoUrl'] as String? ?? '';
    final bio = d['bio'] as String? ?? '';
    final location = d['location'] as String? ?? '';
    final rating = (d['rating'] as num?)?.toDouble() ?? 0.0;
    final category =
        (d['serviceCategories'] as List?)?.cast<String>().join(', ') ?? '';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── App bar with avatar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 22.h,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover
                  Container(color: theme.colorScheme.primaryContainer),
                  // Avatar centered at bottom
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 3,
                          ),
                        ),
                        child: UserAvatarWidget(
                          imageUrl: avatar.isNotEmpty ? avatar : null,
                          name: name,
                          size: 80,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            title: Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // ── Profile info ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (category.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          location,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (rating > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      bio,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Book button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/service-booking-screen',
                        arguments: d,
                      ),
                      child: const Text('Book Now'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Posts grid ───────────────────────────────────────────────────
          if (_posts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  'Posts',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(2),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((_, i) {
                  final post = _posts[i];
                  final images = post['postImages'] as List? ?? [];
                  final imgUrl = images.isNotEmpty
                      ? (images[0] as Map)['url'] as String? ?? ''
                      : '';
                  return imgUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: imgUrl, fit: BoxFit.cover)
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                        );
                }, childCount: _posts.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
              ),
            ),
          ],

          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ),
        ],
      ),
    );
  }
}
