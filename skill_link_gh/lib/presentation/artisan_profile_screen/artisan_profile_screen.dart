import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/data/repository/auth_repository.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';
import 'package:skill_link_gh/widgets/utils/createPost.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/about_section_widget.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/portfolio_section_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/profile_stats_widget.dart';
import './widgets/reviews_section_widget.dart';
import './widgets/services_section_widget.dart';

class ArtisanProfileScreen extends StatefulWidget {
  const ArtisanProfileScreen({super.key});

  @override
  State<ArtisanProfileScreen> createState() => _ArtisanProfileScreenState();
}

class _ArtisanProfileScreenState extends State<ArtisanProfileScreen>
    with SingleTickerProviderStateMixin {
  final AuthRepository _authRepository = AuthRepository();

  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showStickyHeader = false;
  bool _isLoggingOut = false;

  // Mock data (artisan, portfolio, reviews, services)
  final Map<String, dynamic> artisanData = {
    "id": "ART001",
    "name": "Kwame Mensah",
    "coverPhoto":
        "https://img.rocket.new/generatedImages/rocket_gen_img_1dc4f57f7-1764722656772.png",
    "coverPhotoSemanticLabel":
        "Modern workshop interior with tools and equipment on wooden workbench",
    "profileImage":
        "https://img.rocket.new/generatedImages/rocket_gen_img_103ed5b0c-1763301455344.png",
    "profileImageSemanticLabel":
        "Professional headshot of African man with short black hair wearing blue shirt",
    "serviceCategories": ["Carpentry", "Furniture Making", "Home Repairs"],
    "rating": 4.8,
    "totalReviews": 127,
    "totalJobs": 245,
    "responseTime": "2 hours",
    "verificationBadges": {
      "identityVerified": true,
      "skillCertified": true,
      "backgroundChecked": true,
    },
    "bio":
        "Professional carpenter with 12+ years of experience in custom furniture making and home repairs. Specialized in modern and traditional Ghanaian woodwork designs. Committed to quality craftsmanship and customer satisfaction.",
    "experience": "12 years",
    "certifications": [
      "Master Carpenter Certification - Ghana Carpentry Association",
      "Furniture Design Certificate - Accra Technical Institute",
      "Safety Training Certified",
    ],
    "location": "East Legon, Accra",
    "memberSince": "2020-03-15",
    "languages": ["English", "Twi", "Ga"],
    "availability": "Available for bookings",
  };

  final List<Map<String, dynamic>> portfolioImages = [
    {
      "id": 1,
      "imageUrl":
          "https://img.rocket.new/generatedImages/rocket_gen_img_14eb753f8-1764845698055.png",
      "semanticLabel":
          "Modern living room with gray sofa and wooden coffee table",
      "title": "Custom Living Room Set",
      "description": "Modern furniture set with custom upholstery",
    },
    {
      "id": 2,
      "imageUrl":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1e7e14362-1765034691936.png",
      "semanticLabel": "Elegant wooden dining table with six matching chairs",
      "title": "Dining Table & Chairs",
      "description": "Handcrafted mahogany dining set",
    },
    {
      "id": 3,
      "imageUrl":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1b16d49f6-1765159452801.png",
      "semanticLabel": "Contemporary bedroom with wooden bed frame and dresser",
      "title": "Bedroom Furniture",
      "description": "Complete bedroom set with custom finishes",
    },
    {
      "id": 4,
      "imageUrl":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1cb5b4340-1765254120023.png",
      "semanticLabel": "Built-in wooden bookshelf with decorative items",
      "title": "Custom Bookshelf",
      "description": "Wall-mounted storage solution",
    },
  ];

  final List<Map<String, dynamic>> reviews = [
    {
      "id": 1,
      "clientName": "Ama Osei",
      "clientAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1e6851c39-1763295120619.png",
      "clientAvatarSemanticLabel":
          "Portrait of African woman with natural hair wearing white top",
      "rating": 5.0,
      "date": "2024-11-28",
      "service": "Custom Dining Table",
      "review":
          "Excellent craftsmanship! Kwame delivered exactly what I wanted. The dining table is beautiful and very sturdy. Highly recommend his services.",
      "helpful": 24,
      "images": [
        {
          "url": "https://images.unsplash.com/photo-1596363713526-91c3c2d84e85",
          "semanticLabel": "Finished wooden dining table in home setting",
        },
      ],
    },
    {
      "id": 2,
      "clientName": "Kofi Asante",
      "clientAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1b174a9a5-1763291952790.png",
      "clientAvatarSemanticLabel":
          "Professional photo of African man with beard wearing gray shirt",
      "rating": 4.5,
      "date": "2024-11-15",
      "service": "Kitchen Cabinet Repair",
      "review":
          "Very professional and punctual. Fixed my kitchen cabinets perfectly. The only minor issue was communication could be faster, but overall great work.",
      "helpful": 18,
    },
    {
      "id": 3,
      "clientName": "Abena Mensah",
      "clientAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1ad91979a-1763295629510.png",
      "clientAvatarSemanticLabel":
          "Headshot of African woman with braided hair smiling",
      "rating": 5.0,
      "date": "2024-10-30",
      "service": "Bedroom Furniture Set",
      "review":
          "Outstanding service from start to finish. Kwame is a true craftsman who takes pride in his work. My bedroom looks amazing!",
      "helpful": 31,
    },
  ];

  final List<Map<String, dynamic>> services = [
    {
      "id": 1,
      "name": "Custom Furniture Making",
      "description":
          "Design and build custom furniture pieces tailored to your specifications",
      "price": "GHS 500 - 5,000",
      "duration": "1-4 weeks",
      "available": true,
    },
    {
      "id": 2,
      "name": "Furniture Repair & Restoration",
      "description":
          "Professional repair and restoration of damaged or worn furniture",
      "price": "GHS 150 - 800",
      "duration": "2-7 days",
      "available": true,
    },
    {
      "id": 3,
      "name": "Home Carpentry Services",
      "description":
          "General carpentry work including door installation, shelving, and repairs",
      "price": "GHS 200 - 1,500",
      "duration": "1-5 days",
      "available": true,
    },
    {
      "id": 4,
      "name": "Kitchen Cabinet Installation",
      "description":
          "Custom kitchen cabinet design, building, and installation",
      "price": "GHS 2,000 - 8,000",
      "duration": "2-6 weeks",
      "available": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showStickyHeader) {
      setState(() => _showStickyHeader = true);
    } else if (_scrollController.offset <= 200 && _showStickyHeader) {
      setState(() => _showStickyHeader = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleBookNow() {
    Navigator.pushNamed(context, '/service-booking-screen');
  }

  void _handleMessage() {
    Navigator.pushNamed(context, '/posts-homepage');
  }

  void _handleShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile sharing coming soon')),
    );
  }

  void _handleFavorite() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Added to favorites')));
  }

  void _handleReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: const Text('Are you sure you want to report this artisan?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted')));
              },
              child: const Text('Report')),
        ],
      ),
    );
  }

  // Create Post Handler
  void _handleCreatePost() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _showStickyHeader
          ? CustomAppBar(
              variant: AppBarVariant.standard,
              backgroundColor: theme.colorScheme.surface,
              titleWidget: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomImageWidget(
                      imageUrl: artisanData["profileImage"] as String,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      semanticLabel:
                          artisanData["profileImageSemanticLabel"] as String,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          artisanData["name"] as String,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'star',
                              size: 14,
                              color: theme.colorScheme.secondary,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              '${artisanData["rating"]} (${artisanData["totalReviews"]})',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'share',
                    size: 24,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: _handleShare,
                ),
                PopupMenuButton<String>(
                  icon: CustomIconWidget(
                    iconName: 'more_vert',
                    size: 24,
                    color: Colors.white,
                  ),
                  onSelected: (value) {
                    if (value == 'favorite') _handleFavorite();
                    if (value == 'report') _handleReport();
                    if (value == 'logout') _handleLogout();
                    if (value == 'delete') _handleDeleteAccount();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'favorite', child: Text('Save to Favorites')),
                    PopupMenuItem(value: 'report', child: Text('Report User')),
                    PopupMenuItem(value: 'logout', child: Text('Log out')),
                    PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Account',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            )
          : CustomAppBar(
              variant: AppBarVariant.transparent,
              actions: [
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'share',
                    size: 24,
                    color: Colors.white,
                  ),
                  onPressed: _handleShare,
                ),
                PopupMenuButton<String>(
                  icon: CustomIconWidget(
                    iconName: 'more_vert',
                    size: 24,
                    color: Colors.white,
                  ),
                  onSelected: (value) {
                    if (value == 'favorite') _handleFavorite();
                    if (value == 'report') _handleReport();
                    if (value == 'logout') _handleLogout();
                    if (value == 'delete') _handleDeleteAccount();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'favorite', child: Text('Save to Favorites')),
                    PopupMenuItem(value: 'report', child: Text('Report User')),
                    PopupMenuItem(value: 'logout', child: Text('Log out')),
                    PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Account',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: ProfileHeaderWidget(artisanData: artisanData)),
              SliverToBoxAdapter(child: ProfileStatsWidget(artisanData: artisanData)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicatorColor: theme.colorScheme.primary,
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Portfolio'),
                      Tab(text: 'Reviews'),
                      Tab(text: 'Services'),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    AboutSectionWidget(artisanData: artisanData),
                    PortfolioSectionWidget(portfolioImages: portfolioImages),
                    ReviewsSectionWidget(
                        reviews: reviews,
                        averageRating: artisanData["rating"] as double,
                        totalReviews: artisanData["totalReviews"] as int),
                    ServicesSectionWidget(services: services),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ActionButtonsWidget(
              onBookNow: _handleBookNow,
              onMessage: _handleMessage,
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(currentIndex: context.currentBottomBarIndex),
      // FAB for creating post
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreatePost,
        child: const Icon(Icons.post_add),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Log out'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                  onPressed: _isLoggingOut ? null : () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: _isLoggingOut
                    ? null
                    : () async {
                        setState(() => _isLoggingOut = true);
                        try {
                          await _authRepository.signOut();
                        } finally {
                          if (mounted) Navigator.pop(context, true);
                        }
                      },
                child: _isLoggingOut
                    ? const CircularProgressIndicator()
                    : const Text('Log out'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.loginScreen, (route) => false);
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      showLoadingDialog(context, message: 'Deleting your account...');
      final functions = FirebaseFunctions.instance;
      await functions.httpsCallable('deleteUserAccount').call();
      await FirebaseAuth.instance.signOut();
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.pushReplacementNamed(context, '/login-screen');
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      AppToast.show(context,
          message: 'Failed to delete account. Please try again.', type: ToastType.error);
    }
  }

  void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => WillPopScope(
              onWillPop: () async => false,
              child: Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 20),
                      Text(message ?? 'Please wait...'),
                    ],
                  ),
                ),
              ),
            ));
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).colorScheme.surface, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
