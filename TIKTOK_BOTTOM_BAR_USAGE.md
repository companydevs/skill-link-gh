# TikTok-Style Bottom Bar - Usage Guide

## What Was Created

I've created a TikTok-style bottom navigation bar with:

1. **`tiktok_bottom_bar.dart`** - The main bottom bar widget with center create button
2. **`create_content_bottom_sheet.dart`** - The bottom sheet that appears when tapping create

## Features

### TikTok Bottom Bar
- ✅ 5 navigation items (Home, Reels, Create, Messages, Profile)
- ✅ Center create button with TikTok-style dual-color design
- ✅ Cyan and pink accent colors on the sides
- ✅ White/black center with + icon
- ✅ Gradient effect
- ✅ Badge support for notifications
- ✅ Smooth animations

### Create Bottom Sheet
- ✅ Slides up from bottom
- ✅ Options for Create Reel, Create Post, Go Live
- ✅ Gradient icon backgrounds
- ✅ Clean, modern design
- ✅ Easy to dismiss

## How to Use

### Step 1: Import the Widgets

```dart
import 'package:skill_link_gh/widgets/tiktok_bottom_bar.dart';
import 'package:skill_link_gh/widgets/create_content_bottom_sheet.dart';
```

### Step 2: Replace CustomBottomBar with TikTokBottomBar

**In your screens (e.g., ReelsScreen, PostsHomepage, etc.):**

```dart
// BEFORE:
bottomNavigationBar: const CustomBottomBar(currentIndex: 1),

// AFTER:
bottomNavigationBar: TikTokBottomBar(
  currentIndex: 1, // 0=Home, 1=Reels, 2=Create, 3=Messages, 4=Profile
  onTap: (index) {
    // Handle navigation
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/posts-homepage');
        break;
      case 1:
        Navigator.pushNamed(context, '/reels-screen');
        break;
      case 3:
        Navigator.pushNamed(context, '/conversations-screen');
        break;
      case 4:
        Navigator.pushNamed(context, '/artisan-profile-screen');
        break;
    }
  },
  onCreateTap: () {
    // Show create options
    CreateContentBottomSheet.show(
      context,
      onCreateReel: () {
        // Handle create reel
        _pickAndUploadVideo(); // Your existing method
      },
      onCreatePost: () {
        // Handle create post
        Navigator.pushNamed(context, '/create-post');
      },
      onGoLive: () {
        // Handle go live (optional)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live streaming coming soon!')),
        );
      },
    );
  },
  badges: {
    3: 5, // 5 unread messages
  },
),
```

### Step 3: Full Example for ReelsScreen

```dart
@override
Widget build(BuildContext context) {
  final reelsAsync = ref.watch(reelsNotifierProvider);
  final theme = Theme.of(context);

  return Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: [
        // Your existing reels content
        reelsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
          data: (reels) {
            if (reels.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.video_library_outlined,
                      color: Colors.white70,
                      size: 80,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "No reels yet",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Be the first to share your work!",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        CreateContentBottomSheet.show(
                          context,
                          onCreateReel: _pickAndUploadVideo,
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Reel'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            // Your existing PageView with reels
            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: reels.length,
              onPageChanged: (index) {
                setState(() => _currentReelIndex = index);
              },
              itemBuilder: (context, index) {
                return ReelVideoPlayerWidget(
                  reel: reels[index],
                  // ... other properties
                );
              },
            );
          },
        ),
      ],
    ),
    bottomNavigationBar: TikTokBottomBar(
      currentIndex: 1, // Reels tab
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/posts-homepage',
              (route) => false,
            );
            break;
          case 1:
            // Already on reels
            break;
          case 3:
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/conversations-screen',
              (route) => false,
            );
            break;
          case 4:
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/artisan-profile-screen',
              (route) => false,
            );
            break;
        }
      },
      onCreateTap: () {
        CreateContentBottomSheet.show(
          context,
          onCreateReel: _pickAndUploadVideo,
          onCreatePost: () {
            // Navigate to create post or show post creation dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create post coming soon!')),
            );
          },
        );
      },
    ),
  );
}
```

## Customization

### Change Colors

In `tiktok_bottom_bar.dart`, modify the gradient colors:

```dart
gradient: LinearGradient(
  colors: [
    const Color(0xFF00F2EA), // Cyan - change this
    const Color(0xFFFF0050), // Pink - change this
  ],
),
```

### Change Button Size

```dart
Container(
  width: 44, // Change width
  height: 28, // Change height
  // ...
)
```

### Add More Options to Bottom Sheet

In `create_content_bottom_sheet.dart`, add more `_buildOption` calls:

```dart
_buildOption(
  context,
  icon: Icons.camera_alt_outlined,
  title: 'Take Photo',
  subtitle: 'Capture a moment',
  gradient: LinearGradient(
    colors: [Colors.blue, Colors.cyan],
  ),
  onTap: () {
    Navigator.pop(context);
    // Handle take photo
  },
),
```

## Migration Guide

### Replace in All Screens

You need to replace `CustomBottomBar` with `TikTokBottomBar` in:

1. ✅ `frontend/lib/presentation/reels_screen/reels_screen.dart`
2. ✅ `frontend/lib/presentation/posts_homepage/posts_homepage.dart`
3. ✅ `frontend/lib/presentation/search_and_discovery_screen/search_and_discovery_screen.dart`
4. ✅ `frontend/lib/presentation/in_app_messaging/conversations_screen.dart`
5. ✅ `frontend/lib/presentation/artisan_profile_screen/artisan_profile_screen.dart`

### Index Mapping

**CustomBottomBar** (old):
- 0 = Posts
- 1 = Reels
- 2 = Search
- 3 = Messages
- 4 = Profile

**TikTokBottomBar** (new):
- 0 = Home (Posts)
- 1 = Reels
- 2 = **Create** (center button)
- 3 = Messages
- 4 = Profile

**Note**: Search is removed from bottom bar (can be added to app bar or as a separate screen)

## Benefits

✅ **Modern Design** - Matches TikTok's popular UX pattern  
✅ **Prominent Create Action** - Encourages content creation  
✅ **Better UX** - Center button is easier to reach  
✅ **Visual Appeal** - Gradient effects and animations  
✅ **Flexible** - Easy to customize colors and options  

## Screenshots

The center button looks like this:

```
┌─────────────────────────────────────┐
│  🏠    ▶️    [+]    💬    👤       │
│ Home  Reels Create Inbox Profile   │
└─────────────────────────────────────┘
```

Where `[+]` is a colorful button with:
- Cyan accent on left
- Pink accent on right
- White/black center with + icon
- Gradient background

## Next Steps

1. Import the new widgets
2. Replace `CustomBottomBar` with `TikTokBottomBar` in your screens
3. Add the `onCreateTap` handler
4. Test the create button and bottom sheet
5. Customize colors if needed

---

**Files Created**:
- `frontend/lib/widgets/tiktok_bottom_bar.dart`
- `frontend/lib/widgets/create_content_bottom_sheet.dart`
- `TIKTOK_BOTTOM_BAR_USAGE.md` (this file)

**Ready to use!** 🚀
