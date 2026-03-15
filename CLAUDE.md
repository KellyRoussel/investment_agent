# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

InvestTrack — an AI-powered investment portfolio management app. The backend lives in the separate `myBackend` repository. This repo contains two clients:

- `frontend/` — React 19 + TypeScript + Vite web app
- `mobile app/` — Flutter 3.7.2+ Android/iOS app

## Commands

### Frontend (React)

```bash
cd frontend
npm install
npm run dev       # Dev server on :5173 (proxies /api → localhost:8000)
npm run build     # tsc + vite build
npm run lint      # ESLint
npm run preview   # Preview production build
```

Environment: copy `frontend/.env.local.example` to `frontend/.env.local` and set `VITE_API_URL`.

### Mobile App (Flutter)

```bash
cd "mobile app"
flutter pub get
flutter run               # Run on connected device/emulator
flutter build apk         # Android APK
flutter build appbundle   # Google Play bundle
flutter build ios         # iOS (requires macOS)
```

Environment: `assets/.env` — set `BASE_URL` and `OAUTH_BASE_URL` to the backend URL.

## Architecture

### Frontend

**Entry**: `src/main.tsx` → `src/App.tsx` wraps everything in `AuthProvider` + `BrowserRouter`.

**Routing** (`App.tsx`): Public routes (`/login`, `/signup`, `/auth/callback/:appName`) are open. All others are behind `ProtectedRoute` with a shared `Layout`.

**Auth flow**: `AuthContext` holds user state, initialized from `localStorage` on mount. `authService` handles Google OAuth redirect and token storage. `api.ts` (Axios singleton) auto-injects the Bearer token and silently refreshes on 401 — concurrent refresh calls are deduplicated via a shared promise.

**SSE streaming** (`recommendationsService.ts`): Uses native `fetch` (not Axios) for the recommendation stream. A `setTimeout(0)` yield after each chunk lets React flush state updates mid-stream.

**Path aliases**: `@components`, `@pages`, `@services`, `@contexts`, `@hooks`, `@utils`, `@types` all resolve to `src/` subdirectories (configured in `vite.config.ts` and mirrored in `tsconfig.app.json`).

**Key pages**: Portfolio, Investments, Watchlist, Recommendations (SSE stream), ReportHistory, Profile.

### Mobile App

**Architecture**: UI (Screens/Widgets) → Providers (ChangeNotifier) → Services → Dio HTTP client → Backend.

**Auth**: `flutter_web_auth_2` opens OAuth in a browser; deep link `investtrack://auth` returns the user to the app. Dio interceptors auto-inject JWT and refresh on 401.

**SSE**: Recommendation workflow streams from the backend via chunked HTTP read.

**State**: Provider pattern — no nested BuildContext dependencies; providers are registered at the app root in `main.dart`.

### Backend Connection

The backend is `myBackend` (separate repo), deployed on Render. Key endpoints used:
- `GET /investment/recommendations/generate/v2` — SSE stream
- `GET /investment/models` — available AI models
- `POST /auth/refresh-token` — token refresh (header: `X-Refresh-Token`)
- Standard CRUD under `/investment/`, `/portfolio/`, `/watchlist/`, `/users/`
