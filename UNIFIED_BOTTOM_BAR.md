# Unified Bottom Navigation Bar

## Problem Solved

Previously, the app had **two different bottom navigation bars** that would switch between screens:
- **CustomBottomBar**: Home, Reels, **Search**, Messages, Profile
- **TikTokBottomBar**: Home, Reels, **Create**, Messages, Profile

This created a jarring, inconsistent user experience where the entire bottom bar would change when navigating between screens.

## Solution: UnifiedBottomBar

**ONE consistent bottom bar** across ALL screens with context-aware center button:

### For Artisans:
```
[Home] [Reels] [CREATE] [Messages] [Profile]
                  ↑
            TikTok-style
            dual-color button
```

### For Clients:
```
[Home] [Reels] [Search] [Messages] [Profile]
                  ↑
            Standard search icon
```

## Key Features

✅ **Consistent Layout** - Same 5 tabs across all screens
✅ **Context-Aware** - Center button adapts based on user type
✅ **Smooth Animations** - Icon transitions and color changes
✅ **Badge Support** - Unread message counts
✅ **Haptic Feedback** - Touch feedback for better UX
✅ **Auto-Navigation** - Built-in route handling

## Usage

### Basic Implementation

```dart
import 'package:skill_link_gh/widgets/unified_bottom_bar.dart';

Scaffold(
  body: YourContent(),
  bottomNavigationBar: UnifiedBottomBar(
    currentIndex: 0, // 0=Home, 1=Reels, 2=Search/Create, 3=Messages, 4=Profile
  ),
)
```

### With Custom Navigation

```dart
UnifiedBottomBar(
  currentIndex: 1,
  onTap: (index) {
    // Handle navigation
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/posts-homepage');
        break;
      case 1:
        // Already on reels
        break;
      // ... etc
    }
  },
  onCreateTap: () {
    // Handle create button tap (artisans only)
    _showCreateSheet();
  },
)
```

### With Badges

```dart
UnifiedBottomBar(
  currentIndex: 3,
  badges: {
    3: 5, // 5 unread messages
  },
)
```

## Tab Indices

| Index | Tab | Route |
|-------|-----|-------|
| 0 | Home | `/posts-homepage` |
| 1 | Reels | `/reels-screen` |
| 2 | Search/Create | `/search-and-discovery-screen` |
| 3 | Messages | `/conversations-screen` |
| 4 | Profile | `/artisan-profile-screen` |

## Center Button Behavior

### Artisans
- Shows **TikTok-style Create button**
- Dual-color design (cyan + pink accents)
- Triggers `onCreateTap` callback
- Opens content creation sheet

### Clients
- Shows **standard Search icon**
- Navigates to search/discovery screen
- Same behavior as other tabs

## Implementation Details

### Auto-Detection
The bar automatically detects user type using Riverpod:
```dart
final isArtisanAsync = ref.watch(isArtisanProvider);
```

### Loading State
While user type is loading, shows search button by default.

### Error State
On error, falls back to search button (safe default).

## Migration from Old Bars

### Before (CustomBottomBar)
```dart
import '../../widgets/custom_bottom_bar.dart';

bottomNavigationBar: const CustomBottomBar(currentIndex: 0),
```

### After (UnifiedBottomBar)
```dart
import '../../widgets/unified_bottom_bar.dart';

bottomNavigationBar: const UnifiedBottomBar(currentIndex: 0),
```

### Before (TikTokBottomBar)
```dart
import 'package:skill_link_gh/widgets/tiktok_bottom_bar.dart';

bottomNavigationBar: TikTokBottomBar(
  currentIndex: 1,
  onTap: (index) { /* ... */ },
  onCreateTap: () { /* ... */ },
),
```

### After (UnifiedBottomBar)
```dart
import 'package:skill_link_gh/widgets/unified_bottom_bar.dart';

bottomNavigationBar: UnifiedBottomBar(
  currentIndex: 1,
  onTap: (index) { /* ... */ },
  onCreateTap: () { /* ... */ },
),
```

## Screens Updated

All main screens now use UnifiedBottomBar:

- ✅ `posts_homepage.dart` - Index 0 (Home)
- ✅ `reels_screen.dart` - Index 1 (Reels)
- ✅ `search_and_discovery_screen.dart` - Index 2 (Search)
- ✅ `conversations_screen.dart` - Index 3 (Messages)
- ✅ `booking_management.dart` - Index 4 (Bookings)
- ✅ `artisan_profile_screen.dart` - Index 4 (Profile)

## Benefits

### User Experience
- **Consistency** - No more jarring bar switches
- **Predictability** - Same layout everywhere
- **Clarity** - Users always know where they are
- **Smooth** - Animated transitions

### Developer Experience
- **Single Source of Truth** - One bar to maintain
- **Easy Updates** - Change once, applies everywhere
- **Type Safety** - Compile-time checks
- **Flexible** - Easy to customize per screen

## Design Philosophy

The unified bar follows these principles:

1. **Consistency Over Novelty** - Same structure everywhere
2. **Context-Aware** - Adapts to user role without changing layout
3. **Thumb-Friendly** - All buttons easily reachable
4. **Visual Hierarchy** - Active tab clearly indicated
5. **Minimal Cognitive Load** - Users don't need to relearn navigation

## Future Enhancements

Possible improvements:
- [ ] Animated tab transitions
- [ ] Long-press actions
- [ ] Customizable tab order
- [ ] Dynamic tab visibility
- [ ] Gesture navigation support

## Technical Notes

### Dependencies
- `flutter_riverpod` - For user type detection
- `user_type_provider.dart` - Provides artisan/client status

### Performance
- Lightweight widget
- Efficient rebuilds (only when user type changes)
- No unnecessary re-renders

### Accessibility
- Proper semantic labels
- Touch target sizes (48x48 minimum)
- Color contrast ratios met
- Screen reader support

---

**Result:** A consistent, professional navigation experience that eliminates ambiguity and improves usability across the entire app! 🎯
