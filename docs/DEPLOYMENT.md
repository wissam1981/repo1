# Deployment runbook — three platforms (closed audience)

Audience: **you + colleagues (closed)**. You have a **paid Apple Developer**
account. The app is a Flutter client (web + iOS + Android) talking to a Python
FastAPI backend that calls OpenAI.

The client's backend URL is fixed at build time:
`--dart-define=API_BASE_URL=https://YOUR-BACKEND-URL`.

---

## Architecture for production

```
 iOS (TestFlight) ┐
 Android (APK)    ├──HTTPS──▶  FastAPI on Cloud Run  ──▶ OpenAI
 Web (Firebase)   ┘                     │
                                        └──▶ Postgres (Neon, free tier)
```

Why these choices for a closed group:
- **Cloud Run** runs the existing Docker image; pay-per-request, ~$0–3/mo at
  this scale. Mirrors the Coffee Machine app's Google ecosystem.
- **Neon Postgres (free)** instead of SQLite: Cloud Run's disk is ephemeral,
  so SQLite data would vanish on redeploy. The app already supports Postgres
  via `DATABASE_URL` (psycopg installed). Free tier is plenty for a few users.
- **Firebase Hosting** for the web build (same as Coffee Machine).
- **TestFlight** for iOS: ideal closed distribution, uses the paid account, no
  public App Store review needed for internal testers.
- **Android**: share the signed APK directly (no Play Console fee) or use Play
  internal testing later ($25 one-time).

---

## Prerequisites to install (one-time, on this Mac)

```sh
brew install --cask google-cloud-sdk docker   # backend deploy
# firebase CLI is already installed
```

---

## 1. Database (Neon — free)

1. Create a project at https://neon.tech (GitHub login works).
2. Copy the connection string, force the psycopg driver:
   `postgresql+psycopg://USER:PASS@HOST/DB?sslmode=require`

## 2. Backend → Cloud Run

```sh
cd backend
gcloud auth login
gcloud config set project YOUR_GCP_PROJECT
gcloud run deploy contract-trainer-api \
  --source . --region me-central1 --allow-unauthenticated \
  --set-env-vars "AI_PROVIDER=openai" \
  --set-env-vars "DATABASE_URL=postgresql+psycopg://..." \
  --set-secrets "OPENAI_API_KEY=openai-key:latest,JWT_SECRET=jwt-secret:latest"
```
Store secrets first with `gcloud secrets create`. The deploy prints the HTTPS
service URL — that is `API_BASE_URL` for every client build.

## 3. Web → Firebase Hosting

```sh
cd frontend
flutter build web --release --dart-define=API_BASE_URL=https://YOUR-BACKEND-URL
firebase login
firebase use --add            # pick/create a project
firebase deploy --only hosting
```

## 4. iOS → TestFlight

```sh
cd frontend
flutter build ipa --release --dart-define=API_BASE_URL=https://YOUR-BACKEND-URL
```
Then open `build/ios/archive/Runner.xcarchive` in Xcode → Distribute App →
App Store Connect → Upload. Add internal testers in TestFlight. (A matching app
record must exist in App Store Connect, bundle id `com.example.contractEnglishTrainer`
— change to your own reverse-domain id before first upload.)

## 5. Android → signed APK

```sh
cd frontend
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-BACKEND-URL
# share build/app/outputs/flutter-apk/app-release.apk
```
For a release signing key, configure `android/key.properties` (see Flutter docs).

---

## Cost control (closed audience)

- OpenAI is the main variable cost (~3–5¢ per tutor question, <1¢ per lookup,
  TTS cached). For a closed group this is small but real — watch the OpenAI
  usage dashboard and set a billing cap.
- Cloud Run + Neon free tier ≈ $0–3/mo.
- Apple: already paid. Google Play: optional $25 if you want the store later.

## Hardening still recommended before public (NOT needed for closed)

- Per-user rate limits on AI endpoints
- Real OAuth (Google/Apple) instead of guest-only
- Move the in-process progress store / audio cache to Redis if you ever run
  more than one backend instance
