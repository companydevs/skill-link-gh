# SkillLink GH — Flutter App

Mobile app for SkillLink GH. Connects clients with skilled artisans in Ghana via a TikTok-style discovery feed, service bookings, in-app messaging, and a wallet payment system.

---

## Features

- Posts feed with location-aware ranking (powered by recommendation backend)
- Reels feed (TikTok-style short videos) with watch-time tracking
- Artisan discovery with real-time distance calculation
- Service booking with Paystack payment + wallet
- Real-time artisan tracking during active bookings
- In-app messaging
- Google Sign-In + email/password auth
- Light & dark theme

---

## Prerequisites

- Flutter SDK ^3.29.2
- Dart SDK
- Android Studio or VS Code with Flutter extensions
- Android SDK / Xcode (for iOS)
- Firebase project configured (`google-services.json` in `android/app/`)

---

## Setup

```bash
flutter pub get
flutter run
```

---

## Backend Integration

The app connects to the Spring Boot recommendation backend at `http://10.0.2.2:8080` (Android emulator) by default.

To change the URL, update `_baseUrl` in `lib/services/backend_api_service.dart`:

```dart
static const String _baseUrl = 'http://10.0.2.2:8080';   // Android emulator
// static const String _baseUrl = 'http://localhost:8080'; // iOS simulator
// static const String _baseUrl = 'https://your-api.com'; // Production
```

The app automatically falls back to Firestore if the backend is unreachable.

### What gets tracked automatically

Every user action sends an interaction event to the backend to improve recommendations:

| Action | Event sent |
|---|---|
| Like a post/reel | `LIKE` |
| Unlike | `UNLIKE` |
| Save a post | `SAVE` |
| Unsave | `UNSAVE` |
| Report a post | `REPORT` |
| Watch a reel | `VIEW` + watch seconds |
| Swipe past quickly (<2s) | `SKIP` |

---

## Project Structure

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

## State Management

Riverpod with `StateNotifier`. Key providers:

| Provider | Purpose |
|---|---|
| `postsNotifierProvider` | Post feed state + interaction tracking |
| `reelsNotifierProvider` | Reel feed state + watch-time tracking |
| `bookingNotifierProvider` | Booking creation and tracking |
| `backendApiServiceProvider` | Singleton backend API client |

---

## Build

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

---

## Tech Stack

- Flutter + Dart
- Riverpod (state management)
- Firebase Auth, Firestore, Storage, Cloud Functions
- Dio (HTTP client for backend API)
- Geolocator + Geocoding
- Paystack (payments)
- Video Compress + Video Player
