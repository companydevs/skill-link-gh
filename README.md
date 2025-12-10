# Skill Link GH – Flutter App

A modern Flutter-based mobile application connecting customers with skilled artisans in Ghana.  
Features real-time messaging, short video reels, service discovery, booking system, beautiful profiles and a super-fast, fully responsive UI.

Built with Flutter 3 + Material 3 – runs perfectly on Android & iOS.

---

## Features

| Feature                     | Description                                                                 |
|-----------------------------|-----------------------------------------------------------------------------|
| Artisan Search & Discovery  | Powerful search and category-based discovery of local artisans             |
| In-App Messaging            | Real-time chat between customers and artisans                               |
| Reels / Short Videos        | TikTok-style vertical video feed for artisans to showcase their work        |
| Service Booking             | Book services, select date/time, confirm payment (in-app or cash)           |
| Artisan Profile Pages     | Detailed profiles with portfolio, reviews, ratings, reels and contact       |
| Posts Homepage              | Instagram-like feed with posts, stories and reels                           |
| Responsive UI (Sizer)       | Perfect layout on every screen size – phones, tablets and foldables         |
| Light & Dark Theme          | Full Material 3 light/dark mode support with smooth transitions            |
| Fast Navigation             | Clean GoRouter / Named routes with deep linking                             |
| Optimized Assets            | All images compressed, reusable widgets, clean architecture                  |

---

## Prerequisites

- Flutter SDK **≥3.29.2** (latest stable recommended)
- Dart SDK (bundled with Flutter)
- Android Studio or VS Code + Flutter/Dart extensions
- Android SDK (for Android)
- Xcode 15+ (for iOS – macOS only)

---

Home Feed
 src="assets/screenshots/2.png" width="200" alt="Reels"/>
 src="assets/screenshots/3.png" width="200" alt="Artisan Profile"/>
 src="assets/screenshots/4.png" width="200" alt="Booking"/>
src="assets/screenshots/5.png" width="200" alt="Chat"/>
src="assets/screenshots/6.png" width="200" alt="Search"/>
src="assets/screenshots/7.png" width="200" alt="Dark Mode"/>


skill-link-gh/
├── android/                  # Android native configs
├── ios/                      # iOS native configs
├── lib/
│   ├── core/                 # Global utilities & services
│   │   ├── utils/            # Helpers, extensions, constants
│   │   ├── services/         # API, Firebase, local storage services
│   │   └── di/               # Dependency injection (get_it or Riverpod)
│   │
│   ├── data/                 # Data layer (repositories, models, remote/local sources)
│   │   ├── models/           # Dart data classes
│   │   └── repositories/     # Repository implementations
│   │
│   ├── domain/               # Business logic (optional clean architecture layer)
│   │
│   ├── presentation/         # UI layer – everything you see
│   │   ├── screens/          # All main screens
│   │   │   ├── splash_screen/
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── registration_screen.dart
│   │   │   ├── home/
│   │   │   │   └── posts_homepage.dart
│   │   │   ├── reels/
│   │   │   │   └── reels_screen.dart
│   │   │   ├── messaging/
│   │   │   │   └── in_app_messaging_screen.dart
│   │   │   ├── profile/
│   │   │   │   └── artisan_profile_screen.dart
│   │   │   ├── booking/
│   │   │   │   └── service_booking_screen.dart
│   │   │   └── search/
│   │   │       └── search_and_discovery_screen.dart
│   │   │
│   │   ├── widgets/          # Reusable custom widgets
│   │   ├── bloc/ or provider/   # State management (choose one)
│   │   └── theme/            # AppTheme, colors, typography
│   │
│   ├── routes/               # app_routes.dart + GoRouter config
│   └── main.dart             # App entry point
│
├── assets/
│   ├── images/               # App icons, logos, illustrations
│   └── screenshots/          # 1.png to 7.png (app preview)
│
├── test/                     # Unit & widget tests
├── pubspec.yaml
└── README.md
## Installation & Running

```bash
# Clone the repo
git clone https://github.com/your-username/skill-link-gh.git
cd skill-link-gh

# Get dependencies
flutter pub get
