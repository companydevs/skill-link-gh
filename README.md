# SkillLink GH

A full-stack platform connecting clients with skilled artisans in Ghana. Built with Flutter (mobile), Spring Boot (recommendation backend), and React (admin panel).

---

## Project Structure

```
skill_link_gh/
├── frontend/        # Flutter mobile app (iOS & Android)
├── backend/         # Spring Boot recommendation engine (Java 17 + PostgreSQL)
└── admin_panel/     # React admin dashboard (TypeScript + shadcn/ui)
```

---

## How It Works

1. Artisans post services and upload reels (short videos)
2. Clients discover artisans via a TikTok-style feed ranked by the recommendation engine
3. The backend scores every post/reel using engagement, recency, location proximity, and personal category preferences
4. Every interaction (like, save, skip, watch-time, booking) silently updates the user's preference profile
5. Bookings are managed with Paystack payments and an escrow wallet system
6. The admin panel gives operators full visibility over jobs, artisans, escrow, and disputes

---

## Quick Start

### Prerequisites
- Flutter SDK ^3.29.2
- Java 17+
- Maven 3.8+
- PostgreSQL 14+
- Node.js 18+ (admin panel)

### 1. Backend
```bash
cd backend
# Set environment variables
export DB_USERNAME=postgres
export DB_PASSWORD=your_password
export FIREBASE_PROJECT_ID=skill-link-gh
export FIREBASE_SERVICE_ACCOUNT_PATH=firebase-service-account.json

mvn spring-boot:run
# Runs on http://localhost:8080
```

### 2. Frontend
```bash
cd frontend
flutter pub get
flutter run
```

### 3. Admin Panel
```bash
cd admin_panel
npm install
npm run dev
# Runs on http://localhost:5173
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter, Dart, Riverpod, Firebase |
| Backend | Spring Boot 3, Java 17, PostgreSQL, Firebase Admin SDK |
| Admin | React 18, TypeScript, Vite, Tailwind, shadcn/ui |
| Payments | Paystack |
| Auth | Firebase Auth (trusted by backend via ID token verification) |
| Storage | Firebase Storage (videos, images) |
| Realtime | Firestore (chat, live tracking) |

---

## License

MIT
