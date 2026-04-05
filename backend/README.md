# SkillLink GH — Recommendation Backend

Spring Boot 3 + PostgreSQL service that powers the personalised feed for posts and reels.

---

## What It Does

- Scores every post and reel using a weighted algorithm (engagement + recency + location + user preferences)
- Learns from every user interaction (like, save, skip, watch-time, booking) to continuously improve recommendations
- Exposes REST endpoints consumed by the Flutter app
- Trusts Firebase ID tokens for authentication — no separate auth system needed

---

## Recommendation Algorithm

### Algorithm Type: Geo-Aware Weighted Preference Ranking

Formally a **weighted multi-signal ranking function with online preference learning** — a rule-based, collaborative-free recommendation system. No ML model or training pipeline is required.

It combines four well-known techniques:

- **Content-based filtering** — matches content to the user's category affinity scores (no model, just weighted counters updated per interaction)
- **Recency decay** — exponential time decay, the same principle used in Reddit's and Hacker News's ranking formulas
- **Geo-proximity scoring** — haversine distance weighting, similar to how Yelp and Uber-style feeds surface nearby results first
- **Engagement scoring** — log-normalised interaction counts, similar to YouTube's early ranking approach
- **Online learning** — user preferences update in real-time after every interaction (no batch training, no retraining cycle)

### Why not a neural model?

TikTok's actual system trains a deep neural network on billions of interactions to predict click-through rate. That requires massive data and compute. What we built is **deterministic** — given the same inputs it always produces the same output. A neural model is probabilistic and learns patterns that can't be hand-coded.

This is exactly how most apps start. When enough interaction data accumulates in the `user_interactions` table (tens of thousands of rows), the `RecommendationEngine.java` scoring function can be swapped for a trained ML model using that data. The table already collects every signal needed for that upgrade.

### Scoring Formula

Final score for each piece of content:

```
score = 0.30 × engagement
      + 0.20 × recency
      + 0.25 × location
      + 0.25 × preference
```

| Signal | How it's measured |
|---|---|
| Engagement | Weighted sum: saves×3 + likes×2 + comments×1.5 + shares×2.5 + views×0.1 (log-normalised) |
| Recency | Exponential decay — content older than 48h scores lower |
| Location | Haversine distance — nearest artisans score highest (linear decay over 50km) |
| Preference | Per-user category affinity built from interaction history |

### Interaction Weights (preference learning)

| Interaction | Score delta |
|---|---|
| Book | +5.0 |
| Save | +3.0 |
| Share | +2.0 |
| Like | +2.0 |
| Comment | +1.5 |
| View | +0.2 (scaled by watch-time) |
| Skip | -1.0 |
| Unlike | -1.0 |
| Unsave | -1.5 |
| Report | -3.0 |

---

## API Endpoints

### Feed
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/feed/posts` | Personalised ranked posts |
| GET | `/api/feed/reels` | Personalised ranked reels |

Query params: `lat`, `lng`, `radiusKm`, `lastContentId`, `pageSize`

### Interactions
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/interactions` | Record a user interaction |

Body: `{ contentId, contentType, interactionType, watchSeconds? }`

### Sync (admin only)
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/sync/posts` | Upsert a post from Firestore |
| POST | `/api/sync/reels` | Upsert a reel from Firestore |
| DELETE | `/api/sync/posts/{id}` | Soft-delete a post |
| DELETE | `/api/sync/reels/{id}` | Soft-delete a reel |

---

## Setup

### Prerequisites
- Java 17+
- Maven 3.8+
- PostgreSQL 14+
- Firebase service account JSON (download from Firebase Console → Project Settings → Service Accounts)

### Environment Variables

| Variable | Description |
|---|---|
| `DB_USERNAME` | PostgreSQL username |
| `DB_PASSWORD` | PostgreSQL password |
| `FIREBASE_PROJECT_ID` | `skill-link-gh` |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Path to service account JSON file |

### Run

```bash
# Create the database
psql -U postgres -c "CREATE DATABASE skilllink_db;"

# Set env vars (PowerShell)
$env:DB_USERNAME="postgres"
$env:DB_PASSWORD="your_password"
$env:FIREBASE_PROJECT_ID="skill-link-gh"
$env:FIREBASE_SERVICE_ACCOUNT_PATH="firebase-service-account.json"

# Start
mvn spring-boot:run
```

Server starts on `http://localhost:8080`. Hibernate auto-creates all tables on first run.

---

## Project Structure

```
backend/
├── pom.xml
└── src/main/java/com/skilllinkgh/backend/
    ├── config/
    │   ├── FirebaseConfig.java          # Firebase Admin SDK init
    │   ├── FirebaseTokenFilter.java     # Validates Firebase ID tokens
    │   └── SecurityConfig.java          # Spring Security setup
    ├── controller/
    │   ├── FeedController.java          # GET /api/feed/*
    │   ├── InteractionController.java   # POST /api/interactions
    │   └── SyncController.java          # POST /api/sync/*
    ├── dto/
    │   ├── FeedRequest.java
    │   ├── InteractionRequest.java
    │   └── SyncRequest.java
    ├── model/
    │   ├── Post.java
    │   ├── Reel.java
    │   ├── UserInteraction.java
    │   └── UserPreference.java
    ├── repository/
    │   ├── PostRepository.java
    │   ├── ReelRepository.java
    │   ├── UserInteractionRepository.java
    │   └── UserPreferenceRepository.java
    └── service/
        ├── FeedService.java             # Orchestrates feed generation
        ├── RecommendationEngine.java    # Scoring algorithm
        ├── SyncService.java             # Firestore → PostgreSQL sync
        └── UserPreferenceService.java   # Preference learning
```

---

## Security

- All endpoints require a valid Firebase ID token in `Authorization: Bearer <token>`
- `/api/sync/*` requires `ROLE_ADMIN` (set via Firebase custom claims)
- `firebase-service-account.json` is gitignored — never commit it
