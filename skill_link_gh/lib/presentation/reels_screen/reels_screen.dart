import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/reel_info_overlay_widget.dart';
import './widgets/reel_interaction_overlay_widget.dart';
import './widgets/reel_video_player_widget.dart';

/// Reels Screen - Immersive vertical video feed showcasing artisan skills
/// Implements full-screen video playback with swipe navigation and interactive overlays
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  int _currentReelIndex = 0;
  bool _isMuted = true;

  // Mock reels data
  final List<Map<String, dynamic>> _reelsData = [
    {
      "id": 1,
      "videoUrl":
          "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
      "artisan": {
        "name": "Kwame Mensah",
        "avatar":
            "https://img.rocket.new/generatedImages/rocket_gen_img_10e32363d-1763295001957.png",
        "semanticLabel":
            "Profile photo of a man with short black hair wearing a blue shirt",
        "category": "Carpentry"
      },
      "description":
          "Custom mahogany dining table crafted with traditional joinery techniques. 6-seater design with hand-carved details. #GhanaianCraftsmanship #WoodWorking #CustomFurniture",
      "likes": 1247,
      "comments": 89,
      "shares": 34,
      "isLiked": false,
      "timestamp": DateTime.now().subtract(const Duration(hours: 3)),
    },
    {
      "id": 2,
      "videoUrl":
          "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
      "artisan": {
        "name": "Ama Osei",
        "avatar":
            "https://images.unsplash.com/photo-1726273561224-29c44e5114c8",
        "semanticLabel":
            "Profile photo of a woman with braided hair wearing traditional kente cloth",
        "category": "Fashion Design"
      },
      "description":
          "Transforming traditional kente patterns into modern fashion. Each piece tells a story of Ghanaian heritage. #KenteFashion #GhanaStyle #AfricanFashion",
      "likes": 2156,
      "comments": 143,
      "shares": 67,
      "isLiked": true,
      "timestamp": DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      "id": 3,
      "videoUrl":
          "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
      "artisan": {
        "name": "Kofi Asante",
        "avatar":
            "https://images.unsplash.com/photo-1559575003-fb4ee38a747d",
        "semanticLabel":
            "Profile photo of a man with glasses wearing a work apron",
        "category": "Metalwork"
      },
      "description":
          "Forging custom iron gates with intricate Adinkra symbols. Traditional blacksmithing meets modern design. #Metalwork #GhanaArt #CustomGates",
      "likes": 892,
      "comments": 56,
      "shares": 23,
      "isLiked": false,
      "timestamp": DateTime.now().subtract(const Duration(hours: 8)),
    },
    {
      "id": 4,
      "videoUrl":
          "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
      "artisan": {
        "name": "Abena Darko",
        "avatar":
            "https://images.unsplash.com/photo-1606094092594-93c09d76b721",
        "semanticLabel":
            "Profile photo of a woman with natural hair wearing colorful beads",
        "category": "Jewelry Making"
      },
      "description":
          "Handcrafted beaded jewelry using recycled glass beads from Krobo. Supporting sustainable fashion. #GhanaBeads #EcoFashion #HandmadeJewelry",
      "likes": 1534,
      "comments": 98,
      "shares": 45,
      "isLiked": false,
      "timestamp": DateTime.now().subtract(const Duration(hours: 12)),
    },
    {
      "id": 5,
      "videoUrl":
          "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
      "artisan": {
        "name": "Yaw Boateng",
        "avatar":
            "https://images.unsplash.com/photo-1685538426106-fccba68cd1ba",
        "semanticLabel":
            "Profile photo of a man with dreadlocks wearing a paint-stained shirt",
        "category": "Painting & Decor"
      },
      "description":
          "Transforming homes with vibrant African-inspired murals. Every wall tells a unique story. #MuralArt #GhanaDecor #InteriorDesign",
      "likes": 1876,
      "comments": 112,
      "shares": 58,
      "isLiked": true,
      "timestamp": DateTime.now().subtract(const Duration(hours: 16)),
    },
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  void _handleLike(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _reelsData[index]["isLiked"] = !(_reelsData[index]["isLiked"] as bool);
      if (_reelsData[index]["isLiked"] as bool) {
        _reelsData[index]["likes"] = (_reelsData[index]["likes"] as int) + 1;
      } else {
        _reelsData[index]["likes"] = (_reelsData[index]["likes"] as int) - 1;
      }
    });
  }

  void _handleComment(int index) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCommentsSheet(index),
    );
  }

  void _handleShare(int index) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildShareSheet(index),
    );
  }

  void _handleBookService(int index) {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/service-booking-screen');
  }

  void _toggleMute() {
    HapticFeedback.selectionClick();
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _navigateToProfile(int index) {
    Navigator.pushNamed(context, '/artisan-profile-screen');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _reelsData.length,
            onPageChanged: (index) {
              setState(() {
                _currentReelIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildReelItem(index);
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reels',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'camera_alt',
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 1,
      ),
    );
  }

  Widget _buildReelItem(int index) {
    final reel = _reelsData[index];
    final artisan = reel["artisan"] as Map<String, dynamic>;

    return Stack(
      fit: StackFit.expand,
      children: [
        ReelVideoPlayerWidget(
          videoUrl: reel["videoUrl"] as String,
          isActive: _currentReelIndex == index,
          isMuted: _isMuted,
        ),
        GestureDetector(
          onDoubleTap: () => _handleLike(index),
          child: Container(
            color: Colors.transparent,
          ),
        ),
        Positioned(
          left: 16,
          bottom: 100,
          right: 80,
          child: ReelInfoOverlayWidget(
            artisanName: artisan["name"] as String,
            artisanAvatar: artisan["avatar"] as String,
            artisanAvatarSemanticLabel: artisan["semanticLabel"] as String,
            category: artisan["category"] as String,
            description: reel["description"] as String,
            onProfileTap: () => _navigateToProfile(index),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 100,
          child: ReelInteractionOverlayWidget(
            likes: reel["likes"] as int,
            comments: reel["comments"] as int,
            shares: reel["shares"] as int,
            isLiked: reel["isLiked"] as bool,
            onLikeTap: () => _handleLike(index),
            onCommentTap: () => _handleComment(index),
            onShareTap: () => _handleShare(index),
            onBookServiceTap: () => _handleBookService(index),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 120,
          child: IconButton(
            icon: CustomIconWidget(
              iconName: _isMuted ? 'volume_off' : 'volume_up',
              color: Colors.white,
              size: 24,
            ),
            onPressed: _toggleMute,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSheet(int index) {
    final theme = Theme.of(context);
    final reel = _reelsData[index];

    final List<Map<String, dynamic>> mockComments = [
      {
        "user": "Akosua Mensah",
        "avatar":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1bd4bd8ba-1763298705210.png",
        "semanticLabel":
            "Profile photo of a woman with short hair wearing glasses",
        "comment":
            "This is absolutely beautiful! How much would something like this cost?",
        "timestamp": DateTime.now().subtract(const Duration(minutes: 15)),
        "likes": 12,
      },
      {
        "user": "Kwabena Owusu",
        "avatar":
            "https://img.rocket.new/generatedImages/rocket_gen_img_17fea9682-1764690565935.png",
        "semanticLabel": "Profile photo of a man with a beard wearing a cap",
        "comment": "Amazing craftsmanship! Do you deliver to Kumasi?",
        "timestamp": DateTime.now().subtract(const Duration(hours: 1)),
        "likes": 8,
      },
      {
        "user": "Efua Agyeman",
        "avatar":
            "https://img.rocket.new/generatedImages/rocket_gen_img_17eb4a1d7-1763298324036.png",
        "semanticLabel": "Profile photo of a woman with long braids",
        "comment": "I need this for my new home! Can I book a consultation?",
        "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
        "likes": 5,
      },
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${reel["comments"]} Comments',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mockComments.length,
              itemBuilder: (context, commentIndex) {
                final comment = mockComments[commentIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomImageWidget(
                        imageUrl: comment["avatar"] as String,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        semanticLabel: comment["semanticLabel"] as String,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  comment["user"] as String,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTimestamp(
                                      comment["timestamp"] as DateTime),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              comment["comment"] as String,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CustomIconWidget(
                                  iconName: 'favorite_border',
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${comment["likes"]}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Reply',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.5),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'send',
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareSheet(int index) {
    final theme = Theme.of(context);

    final List<Map<String, String>> shareOptions = [
      {"icon": "message", "label": "Send Message"},
      {"icon": "content_copy", "label": "Copy Link"},
      {"icon": "share", "label": "Share to..."},
      {"icon": "bookmark_border", "label": "Save"},
      {"icon": "flag", "label": "Report"},
      {"icon": "block", "label": "Not Interested"},
    ];

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          ...shareOptions.map((option) {
            return ListTile(
              leading: CustomIconWidget(
                iconName: option["icon"]!,
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text(
                option["label"]!,
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
