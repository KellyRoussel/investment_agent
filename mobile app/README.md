# InvestTrack

A Flutter mobile app for investment portfolio management with AI-powered recommendations. Track your investments in real time, visualize portfolio performance, and receive intelligent investment suggestions.

## Features

- **Portfolio Dashboard** — Real-time metrics (total value, gains/losses, diversification score), historical value charts, and top/worst performers ranking. Breakdown by country, sector, and asset type.
- **Investment Tracking** — Add, edit, and delete investments with full metadata (symbol, quantity, purchase price, sector, country, dividend yield, expense ratio).
- **AI Recommendations** — Streamed multi-step agent workflow (SSE) with real-time progress visualization and markdown-rendered results.
- **Authentication** — Google OAuth 2.0 with JWT access/refresh tokens stored securely via platform-native storage (Keychain / Keystore).
- **User Profile** — View profile details and configure currency preferences.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.7.2+ (Dart) |
| State Management | Provider (ChangeNotifier) |
| Navigation | GoRouter |
| HTTP Client | Dio (with auth interceptors & auto token refresh) |
| Charts | fl_chart |
| Auth | flutter_web_auth_2 (OAuth browser flow + deep links) |
| Secure Storage | flutter_secure_storage |
| Environment | flutter_dotenv |

## Project Structure

```
lib/
├── main.dart                    # Entry point & dependency setup
├── app.dart                     # Root MaterialApp configuration
├── core/                        # Network, storage, theme, constants, utils
├── models/                      # Data classes (auth, user, portfolio, investment, recommendation)
├── services/                    # Business logic (auth, investments, portfolio, recommendations, users)
├── providers/                   # State management (ChangeNotifier providers)
├── navigation/                  # GoRouter config & bottom nav shell
├── screens/                     # UI pages (auth, portfolio, investments, recommendations, profile)
└── widgets/                     # Reusable components (common, charts, investment, portfolio, recommendations)
```

## Getting Started

### Prerequisites

- Flutter 3.7.2+
- Android Studio or Xcode (for iOS)

### Setup

```bash
cd "mobile app"
flutter pub get
flutter run
```

### Environment

The app connects to the FastAPI backend. Environment variables are configured in `assets/.env`:

```
BASE_URL=https://kellyroussel-backend.onrender.com
OAUTH_BASE_URL=https://kellyroussel-backend.onrender.com
```

### Build

```bash
flutter build apk          # Android APK
flutter build appbundle     # Google Play bundle
flutter build ios           # iOS (requires macOS)
```

## Architecture

The app follows a layered architecture: **UI (Screens/Widgets) → Providers → Services → API Client → Backend**.

- **Provider pattern** for reactive state management
- **Dio interceptors** for automatic JWT token injection and refresh on 401 responses
- **SSE streaming** for real-time AI recommendation workflow updates
- **Deep link callback** (`investtrack://auth`) for OAuth flow completion
- **Dark theme** with cyan/purple accent colors
