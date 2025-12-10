import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/post_card_widget.dart';

class PostsHomepage extends StatefulWidget {
  const PostsHomepage({super.key});

  @override
  State<PostsHomepage> createState() => _PostsHomepageState();
}

class _PostsHomepageState extends State<PostsHomepage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  List<Map<String, dynamic>> _posts = [];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Filter state
  double _locationRadius = 10.0;
  Set<String> _selectedCategories = {};
  RangeValues _priceRange = const RangeValues(0, 1000);

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadMorePosts();
    }
  }

  Future<void> _loadInitialPosts() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _posts = _getMockPosts();
      _isLoading = false;
    });
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    final newPosts = _getMockPosts(startId: _posts.length + 1);

    setState(() {
      _posts.addAll(newPosts);
      _isLoading = false;
      if (_posts.length >= 20) {
        _hasMore = false;
      }
    });
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() {
      _posts = _getMockPosts();
      _hasMore = true;
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        locationRadius: _locationRadius,
        selectedCategories: _selectedCategories,
        priceRange: _priceRange,
        onApplyFilters: (radius, categories, priceRange) {
          setState(() {
            _locationRadius = radius;
            _selectedCategories = categories;
            _priceRange = priceRange;
          });
          _applyFilters();
        },
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _posts = _getMockPosts();
        _isLoading = false;
      });
    });
  }

  List<Map<String, dynamic>> _getMockPosts({int startId = 1}) {
    return List.generate(5, (index) {
      final id = startId + index;
      return {
        "id": id,
        "artisanName": [
          "Kwame Mensah",
          "Ama Osei",
          "Kofi Asante",
          "Abena Boateng",
          "Yaw Owusu"
        ][index % 5],
        "artisanImage": [
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        ][index % 5],
        "artisanImageLabel": [
          "Professional headshot of a man with short black hair wearing a blue shirt",
          "Professional headshot of a woman with long black hair wearing a white blouse",
          "Professional headshot of a man with gray hair wearing a green polo shirt",
          "Professional headshot of a woman with curly hair wearing a yellow top",
          "Professional headshot of a man with a beard wearing a red t-shirt"
        ][index % 5],
        "serviceCategory": [
          "Plumbing",
          "Electrical",
          "Carpentry",
          "Painting",
          "Masonry"
        ][index % 5],
        "postImages": [
          [
            {
              "url":
                  "https://images.unsplash.com/photo-1606619353175-663591b85c7c",
              "label":
                  "Close-up of hands installing a chrome faucet on a white sink"
            },
            {
              "url":
                  "https://img.rocket.new/generatedImages/rocket_gen_img_1cf5d864f-1764748519370.png",
              "label": "Modern bathroom with newly installed plumbing fixtures"
            }
          ],
          [
            {
              "url":
                  "https://img.rocket.new/generatedImages/rocket_gen_img_1b19239b5-1764686240320.png",
              "label":
                  "Electrician working on a circuit breaker panel with wires"
            }
          ],
          [
            {
              "url":
                  "https://img.rocket.new/generatedImages/rocket_gen_img_1d4009585-1764671124427.png",
              "label": "Carpenter measuring and cutting wood on a workbench"
            },
            {
              "url":
                  "https://img.rocket.new/generatedImages/rocket_gen_img_1591db856-1764829841141.png",
              "label": "Finished wooden cabinet with smooth finish"
            },
            {
              "url":
                  "https://img.rocket.new/generatedImages/rocket_gen_img_13f952939-1765099274532.png",
              "label": "Custom wooden furniture piece in a living room"
            }
          ],
          [
            {
              "url":
                  "https://img.rocket.new/generatedImages/rocket_gen_img_1a3cc914b-1764705370275.png",
              "label": "Painter applying white paint to a wall with a roller"
            }
          ],
          [
            {
              "url":
                  "https://images.unsplash.com/photo-1621994300405-d0419299ef4c",
              "label": "Mason laying bricks for a new wall construction"
            },
            {
              "url":
                  "https://img.rocket.new/generatedImages/rocket_gen_img_18c857f45-1765175563831.png",
              "label": "Completed brick wall with mortar joints"
            }
          ]
        ][index % 5],
        "description": [
          "Just completed a full bathroom renovation in East Legon! New fixtures, modern design, and leak-free guarantee. Available for similar projects.",
          "Rewired a complete 3-bedroom house with modern circuit breakers and safety switches. All work certified and guaranteed.",
          "Custom kitchen cabinets made from premium mahogany wood. Perfect finish and durable construction. Contact for your woodwork needs!",
          "Transformed this living room with fresh paint and professional finish. Interior and exterior painting services available.",
          "Built a beautiful garden wall using quality bricks and cement. Strong foundation and weather-resistant construction."
        ][index % 5],
        "pricing": [
          "GHS 2,500 - 5,000",
          "GHS 1,800 - 3,500",
          "GHS 3,000 - 8,000",
          "GHS 800 - 2,000",
          "GHS 1,500 - 4,000"
        ][index % 5],
        "likes": [45, 67, 89, 34, 56][index % 5],
        "comments": [12, 23, 34, 8, 15][index % 5],
        "isLiked": false,
        "isSaved": false,
        "postedTime": DateTime.now().subtract(Duration(hours: index + 1)),
      };
    });
  }

  void _toggleLike(int postId) {
    setState(() {
      final postIndex = _posts.indexWhere((post) => post["id"] == postId);
      if (postIndex != -1) {
        final isLiked = _posts[postIndex]["isLiked"] as bool;
        _posts[postIndex]["isLiked"] = !isLiked;
        _posts[postIndex]["likes"] =
            (_posts[postIndex]["likes"] as int) + (isLiked ? -1 : 1);
      }
    });
  }

  void _toggleSave(int postId) {
    setState(() {
      final postIndex = _posts.indexWhere((post) => post["id"] == postId);
      if (postIndex != -1) {
        _posts[postIndex]["isSaved"] = !(_posts[postIndex]["isSaved"] as bool);
      }
    });
  }

  void _navigateToPostDetail(Map<String, dynamic> post) {
    // Navigation to post detail screen would go here
  }

  void _navigateToArtisanProfile(Map<String, dynamic> post) {
    Navigator.pushNamed(context, '/artisan-profile-screen');
  }

  void _navigateToBooking(Map<String, dynamic> post) {
    Navigator.pushNamed(context, '/service-booking-screen');
  }

  void _navigateToSearch() {
    Navigator.pushNamed(context, '/search-and-discovery-screen');
  }

  void _showPostOptions(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'bookmark_border',
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                  title: Text(
                    'Save Post',
                    style: theme.textTheme.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleSave(post["id"] as int);
                  },
                ),
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'share',
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                  title: Text(
                    'Share',
                    style: theme.textTheme.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'report',
                    color: theme.colorScheme.error,
                    size: 24,
                  ),
                  title: Text(
                    'Report',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'location_on',
              color: theme.colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 1.w),
            Text(
              'Accra, Ghana',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            CustomIconWidget(
              iconName: 'keyboard_arrow_down',
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'search',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _navigateToSearch,
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'notifications_outlined',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {},
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: _posts.isEmpty && _isLoading
          ? _buildLoadingState(theme)
          : _posts.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _onRefresh,
                  color: theme.colorScheme.primary,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 2.h),
                    itemCount: _posts.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _posts.length) {
                        return _buildLoadingIndicator(theme);
                      }

                      final post = _posts[index];
                      return PostCardWidget(
                        post: post,
                        onLike: () => _toggleLike(post["id"] as int),
                        onComment: () => _navigateToPostDetail(post),
                        onBookNow: () => _navigateToBooking(post),
                        onArtisanTap: () => _navigateToArtisanProfile(post),
                        onPostTap: () => _navigateToPostDetail(post),
                        onLongPress: () => _showPostOptions(post),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterBottomSheet,
        backgroundColor: theme.colorScheme.primary,
        child: CustomIconWidget(
          iconName: 'tune',
          color: Colors.white,
          size: 24,
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 0,
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30.w,
                          height: 12,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Container(
                          width: 20.w,
                          height: 10,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              SizedBox(height: 2.h),
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              SizedBox(height: 1.h),
              Container(
                width: 60.w,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'people_outline',
              color: theme.colorScheme.onSurfaceVariant,
              size: 80,
            ),
            SizedBox(height: 3.h),
            Text(
              'No Posts Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Follow artisans to see their posts and discover quality services in your area',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: _navigateToSearch,
              child: const Text('Discover Artisans'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        color: theme.colorScheme.primary,
      ),
    );
  }
}
