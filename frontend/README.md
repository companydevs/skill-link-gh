# Skill Link GH – Flutter App

A modern Flutter-based mobile application designed for seamless cross-platform performance, clean UI, in-app messaging, artisan discovery, bookings, reels, and more.  
Built for speed, scalability, and modern mobile UX.

---

## ✨ Features

- 🔍 **Artisan Search & Discovery** — location-aware, sorted by proximity
- 💬 **In-App Messaging** — real-time chat between clients and artisans
- 🎥 **Reels / Short Videos** — TikTok-style feed with watch-time tracking
- 📄 **Service Booking** — multi-step booking with scheduling and payment
- 👤 **Artisan Profile Pages** — portfolio, reviews, services, ratings
- 🏠 **Posts Homepage** — personalised feed ranked by recommendation engine
- 💳 **Wallet & Payments** — Paystack integration with escrow hold/release
- 📍 **Real-time Tracking** — live artisan location during active bookings
- 📱 **Responsive UI** — Sizer-based adaptive layout
- 🎨 **Light & Dark Theme** — system-aware theming

---

## 🖼️ App Preview

| | | |
|---|---|---|
| ![](assets/screenshots/1.png) | ![](assets/screenshots/2.png) | ![](assets/screenshots/3.png) |
| ![](assets/screenshots/4.png) | ![](assets/screenshots/5.png) | ![](assets/screenshots/6.png) |
| ![](assets/screenshots/7.png) | | |

---

## 📋 Prerequisites

- Flutter SDK **^3.29.2**
- Dart SDK
- Android Studio or VS Code with Flutter extensions
- Android SDK / Xcode (for iOS)
- Firebase project with `google-services.json` in `android/app/`

---

## 📦 Setup

```bash
flutter pub get
flutter run
```

---

## 🔗 Backend Integration

The app connects to the Spring Boot recommendation backend at `http://10.0.2.2:8080` (Android emulator) by default.

Update `_baseUrl` in `lib/services/backend_api_service.dart` to match your environment:

```dart
static const String _baseUrl = 'http://10.0.2.2:8080';    // Android emulator
// static const String _baseUrl = 'http://localhost:8080'; // iOS simulator
// static const String _baseUrl = 'https://your-api.com';  // Production
```

The app automatically falls back to Firestore if the backend is unreachable — no crashes, no user impact.

### Interaction tracking (automatic)

Every user action sends an event to the backend to improve recommendations:

| Action | Event |
|---|---|
| Like a post/reel | `LIKE` |
| Unlike | `UNLIKE` |
| Save a post | `SAVE` |
| Unsave | `UNSAVE` |
| Report | `REPORT` |
| Watch a reel | `VIEW` + watch seconds |
| Swipe past quickly (<2s) | `SKIP` |

---

## 📁 Project Structure

```
lib/
├── core/                    # Theme, exports, app config
├── data/
│   └── repository/          # Data layer (Firestore + backend API)
│       ├── post_repository.dart
│       ├── reels_repositoty.dart
│       ├── booking_repository.dart
│       ├── artisan_repository.dart
│       ├── auth_repository.dart
│       ├── comments_repository.dart
│       ├── profile_repository.dart
│       └── wallet_repository.dart
├── domain/
│   └── models/              # Data models
├── notifier/                # StateNotifiers
├── presentation/            # Screens
│   ├── posts_homepage/
│   ├── reels_screen/
│   ├── artisan_profile_screen/
│   ├── service_booking_screen/
│   ├── booking_tracking_screen/
│   ├── wallet_screen/
│   ├── login_screen/
│   ├── registration_screen/
│   └── search_and_discovery_screen/
├── provider/                # Riverpod providers
│   ├── backend_provider.dart
│   ├── post_provider.dart
│   ├── reels_provider.dart
│   └── booking_provider.dart
├── routes/                  # AppRoutes
├── services/
│   ├── backend_api_service.dart   # Spring Boot API client
│   └── presence_service.dart
└── main.dart
```

---

## 🧩 Routing

Routes defined in `lib/routes/app_routes.dart`:

```dart
static const String postsHomepage    = '/posts-homepage';
static const String reels            = '/reels-screen';
static const String artisanProfile   = '/artisan-profile-screen';
static const String serviceBooking   = '/service-booking-screen';
static const String bookingTracking  = '/booking-tracking-screen';
static const String walletScreen     = '/wallet-screen';
static const String searchAndDiscovery = '/search-and-discovery-screen';
static const String inAppMessaging   = '/in-app-messaging-screen';
```

---

## 🎨 Theming

```dart
final theme = Theme.of(context);
final primary = theme.colorScheme.primary;
```

Supports dark & light mode, custom typography, buttons, cards, input fields.

---

## 📱 Responsive UI (Sizer)

```dart
Container(
  width: 50.w,   // 50% of screen width
  height: 20.h,  // 20% of screen height
)
```

---

## ⚙️ Build

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

---

## 🛠️ Tech Stack

- Flutter + Dart
- Riverpod (state management)
- Firebase Auth, Firestore, Storage, Cloud Functions
- Dio (HTTP client for backend API)
- Geolocator + Geocoding
- Paystack (payments)
- Video Compress + Video Player
- Google Maps + Distance Matrix API

---

## 📄 License

MIT
