# Skill Link GH – Flutter App

A modern Flutter-based mobile application designed for seamless cross-platform performance, clean UI, in-app messaging, artisan discovery, bookings, reels, and more.  
Built for speed, scalability, and modern mobile UX.

---

## ✨ Features

- 🔍 **Artisan Search & Discovery**
- 💬 **In-App Messaging**
- 🎥 **Reels / Short Videos**
- 📄 **Service Booking**
- 👤 **Artisan Profile Pages**
- 🏠 **Posts Homepage**
- 📱 **Responsive UI (Sizer)**
- 🎨 **Light & Dark Theme Support**
- 🚀 **Fast Navigation With Clean Routes**
- 🗄️ **Optimized Assets & Reusable Components**

---

## 📋 Prerequisites

Before running the project, ensure you have:

- Flutter SDK **^3.29.2**
- Dart SDK
- Android Studio or VS Code with Flutter extensions
- Android SDK / Xcode (iOS)

---

## 📦 Dependencies Installation

```bash
flutter pub get
```

---

## ▶️ Run the Application

```bash
flutter run
```

---

## 📁 Project Structure

```
flutter_app/
├── android/                   # Android configuration
├── ios/                       # iOS configuration
├── lib/
│   ├── core/                  # Core helpers, utilities, services
│   │   └── utils/             # Utility functions
│   ├── presentation/          # Screens & widgets
│   │   ├── splash_screen/
│   │   ├── in_app_messaging/
│   │   ├── posts_homepage/
│   │   ├── reels_screen/
│   │   ├── artisan_profile_screen/
│   │   ├── registration_screen/
│   │   └── service_booking_screen/
│   ├── routes/                # AppRoutes
│   ├── theme/                 # Light & Dark themes
│   ├── widgets/               # Reusable components
│   └── main.dart              # Entry point
├── assets/
│   ├── images/
│   └── screenshots/           
├── pubspec.yaml
└── README.md
```

---

## 🧩 Routing Configuration

Routes are defined in `lib/routes/app_routes.dart`:

```dart
class AppRoutes {
  static const String initial = '/';
  static const String postsHomepage = '/posts-homepage';
  static const String artisanProfile = '/artisan-profile-screen';
  static const String reels = '/reels-screen';
  static const String serviceBooking = '/service-booking-screen';
  static const String registration = '/registration-screen';
  static const String searchAndDiscovery = '/search-and-discovery-screen';
  static const String inAppMessagingScreen = '/in-app-messaging-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (_) => const PostsHomepage(),
    postsHomepage: (_) => const PostsHomepage(),
    artisanProfile: (_) => const ArtisanProfileScreen(),
    reels: (_) => const ReelsScreen(),
    serviceBooking: (_) => const ServiceBookingScreen(),
    registration: (_) => const RegistrationScreen(),
    searchAndDiscovery: (_) => const SearchAndDiscoveryScreen(),
    inAppMessagingScreen: (_) => const InAppMessaging(),
  };
}
```

---

## 🎨 Theming

Access theme values:

```dart
final theme = Theme.of(context);
final primary = theme.colorScheme.primary;
```

Supports:

- Dark & light mode
- Custom typography
- Buttons
- Text styles
- Cards & surfaces
- Input fields

---

## 📱 Responsive UI (Sizer)

Sizer helps scale UI dynamically:

```dart
Container(
  width: 50.w,  // 50% of screen width
  height: 20.h, // 20% of screen height
  child: Text('Responsive'),
)
```

---

## 🖼️ Screenshots

All screenshots are in the `assets/screenshots/` folder:

### App Preview (4 Per Row)

| Screenshot                    | Screenshot                    | Screenshot                    | Screenshot                    |
| ----------------------------- | ----------------------------- | ----------------------------- | ----------------------------- |
| ![Screenshot 1](assets/screenshots/1.png) | ![Screenshot 2](assets/screenshots/2.png) | ![Screenshot 3](assets/screenshots/3.png) | ![Screenshot 4](assets/screenshots/4.png) |
| ![Screenshot 5](assets/screenshots/5.png) | ![Screenshot 6](assets/screenshots/6.png) | ![Screenshot 7](assets/screenshots/7.png) | —                             |


## ⚙️ Building for Release

### Android (APK)

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

---

## 🧪 Testing

Run all Flutter tests:

```bash
flutter test
```

---

## 🛠️ Tools & Tech

- Flutter
- Dart
- Material 3
- Sizer
- Provider / Riverpod (if used)
- Firebase (optional)
- Clean architecture
- Reusable widgets & services

---

## 👨‍💻 Development Workflow

1. Create/modify features inside `presentation/`
2. Add route to `AppRoutes`
3. Add assets to `pubspec.yaml`
4. Run `flutter pub get`
5. Test on Android & iOS profiles
6. Push with clear commit messages

---

## 📄 License

This project is licensed under the **MIT License**.

---

## 💬 Contact

For support, issues, or feature requests — open a GitHub issue.
