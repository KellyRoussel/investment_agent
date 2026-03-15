# InvestTrack

AI-powered investment portfolio management with real-time tracking, portfolio analytics, and streamed AI recommendations.

## Structure

| Directory | Stack | Purpose |
|-----------|-------|---------|
| `frontend/` | React 19 + TypeScript + Vite + Tailwind | Web client |
| `mobile app/` | Flutter 3.7.2+ (Dart) | Android/iOS client |
| Backend | FastAPI (separate repo: `myBackend`) | API, auth, AI agents |

## Features

- **Portfolio Dashboard** — Total value, gains/losses, diversification, historical chart, sector/country breakdown
- **Investment Tracking** — CRUD with full metadata (symbol, quantity, purchase price, sector, country, dividend yield)
- **Watchlist** — Track symbols without holding them
- **AI Recommendations** — Multi-step agent workflow streamed via SSE with real-time progress and markdown output
- **Report History** — Browse past recommendation reports
- **Authentication** — Google OAuth 2.0 with JWT access/refresh tokens (auto-refresh on 401)

## Quick Start

### Frontend

```bash
cd frontend
npm install
cp .env.local.example .env.local   # set VITE_API_URL=http://localhost:8000
npm run dev                         # → http://localhost:5173
```

### Mobile App

```bash
cd "mobile app"
# Edit assets/.env: BASE_URL=https://your-backend-url
flutter pub get
flutter run
```

## Tech Stack

### Frontend
- React 19, TypeScript, Vite
- TailwindCSS v4, Headless UI, Heroicons
- React Router v7, React Hook Form + Zod
- Axios (with JWT interceptors), Recharts

### Mobile
- Flutter/Dart, Provider (state), GoRouter (navigation)
- Dio (HTTP + auth interceptors), fl_chart
- flutter_web_auth_2 (OAuth), flutter_secure_storage
