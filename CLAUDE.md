# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Investment Portfolio API - A full-stack application for managing financial investments with AI-powered recommendations.

**Monorepo Structure:**
- `app/` - FastAPI backend (Python 3.13+)
- `frontend/` - React 19 + TypeScript + Vite
- `mobile app/` - Flutter mobile app (InvestTrack)

## Common Commands

### Backend
```bash
# Start development server
python -m uvicorn app.main:app --reload

# Database migrations
alembic revision --autogenerate -m "message"
alembic upgrade head

# Start PostgreSQL (via Docker)
docker-compose up -d db
```

### Frontend (from `frontend/` directory)
```bash
npm run dev       # Start Vite dev server (port 5173)
npm run build     # TypeScript check + Vite build
npm run lint      # ESLint check
```

### Mobile (from `mobile app/` directory)
```bash
flutter pub get
flutter run
flutter build apk
```

## Required Environment Variables

```bash
JWT_SECRET_KEY=<generate with: openssl rand -hex 32>
OPENAI__API_KEY=<OpenAI API key>  # Note: double underscore
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/investment_portfolio
```

## Architecture

### Backend Layers (Hexagonal/Clean Architecture)
- **API Layer** (`app/api/endpoints/`) - FastAPI route handlers
- **Domain Layer** (`app/domain/`) - Entities and value objects (Money, Percentage)
- **Service Layer** (`app/services/`) - Business logic (PortfolioCalculator, AIAgents)
- **Repository Layer** (`app/repositories/`) - Data access abstraction
- **Infrastructure** (`app/clients/`) - External API clients (Yahoo Finance, OpenFIGI)

### Key Patterns
- **Repository Pattern**: InvestmentRepository, UserRepository for data access
- **Value Objects**: `Money` (amount + currency), `Percentage` with validation
- **Domain Entities**: Investment with methods like `add_quantity()`, `calculate_total_cost()`
- **Dependency Injection**: FastAPI's `Depends()` for sessions and auth

### Authentication
- JWT with HS256 algorithm (access token: 30 min, refresh token: 7 days)
- Argon2 password hashing
- HTTP Bearer token scheme

### External Integrations
- **Yahoo Finance** (`app/clients/yahoo_finance.py`) - Real-time price data
- **OpenAI** (`app/services/ai_agents.py`) - Investment recommendations using gpt-4.1
- **Open FIGI** (`app/clients/open_figi.py`) - Security identifier lookup

## Database Schema

**Core Models** (in `app/models/`):
- **User** - Email, password hash, risk tolerance (CONSERVATIVE/MODERATE/AGGRESSIVE), currency preference
- **Investment** - Symbol, asset type (STOCK/ETF/CRYPTO/BOND/COMMODITY/REIT/MUTUAL_FUND), purchase details
- **Transaction** - Investment transactions
- **PriceHistory** - Historical price data

All models use UUID primary keys and include `created_at`/`updated_at` timestamps.

## Frontend Architecture

- **State Management**: React Context (AuthContext for auth state)
- **Routing**: react-router-dom with protected routes
- **Forms**: react-hook-form + Zod validation
- **HTTP**: Axios (Vite proxies `/api` to backend at localhost:8000)
- **Styling**: Tailwind CSS
- **Charts**: Recharts

## Mobile Architecture

- **State**: Provider pattern
- **Routing**: go_router
- **HTTP**: Dio
- **Auth**: flutter_web_auth_2 for OAuth
- **Storage**: flutter_secure_storage for tokens

## AI Recommendations

The recommendation service (`app/services/ai_agents.py`) uses a multi-step workflow:
1. Analyzes user's portfolio and preferences
2. Fetches market data
3. Generates personalized recommendations via OpenAI
4. Applies ethical exclusions (fossil fuels, weapons, tobacco)
