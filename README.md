# Investment Portfolio API

## Vue d'ensemble

L'**Investment Portfolio API** est une application FastAPI qui permet aux utilisateurs de gérer et suivre leurs investissements financiers. L'application collecte, stocke et met à jour automatiquement les informations sur les investissements des utilisateurs, tout en fournissant des analyses et des recommandations personnalisées.

## Fonctionnalités principales

### 📊 Gestion du Portfolio
- **Enregistrement des investissements** : Ajout d'actions, ETF, cryptomonnaies avec détails complets
- **Suivi en temps réel** : Mise à jour automatique des prix via l'API Yahoo Finance
- **Analyse de diversité** : Visualisation du portfolio selon différents axes (géographie, secteur, type d'actif)

### 🔄 Mise à jour des données
- **Synchronisation automatique** : Mise à jour régulière des valeurs des investissements
- **Intégration Yahoo Finance** : Récupération des données de prix en temps réel
- **Historique des prix** : Stockage de l'évolution des valeurs dans le temps

### 🤖 Recommandations IA
- **Agent intelligent** : Analyse du portfolio existant et des choix passés
- **Recherche automatique** : Analyse des actualités et tendances du marché
- **Suggestions personnalisées** : Recommandations d'investissement adaptées au profil

## Architecture technique

### Stack technologique
- **Backend** : Python 3.13+ avec FastAPI
- **Base de données** : PostgreSQL
- **ORM** : SQLAlchemy avec Alembic pour les migrations
- **API externe** : Yahoo Finance pour les données de marché
- **IA/ML** : OpenAI API

### Structure du projet
```
investment_agent/
├── app/
│   ├── api/
│   │   ├── v1/
│   │   │   ├── endpoints/
│   │   │   │   ├── investments.py
│   │   │   │   ├── portfolio.py
│   │   │   │   ├── prices.py
│   │   │   │   └── recommendations.py
│   │   │   └── api.py
│   │   └── dependencies.py
│   ├── core/
│   │   ├── config.py
│   │   ├── security.py
│   │   └── database.py
│   ├── models/
│   │   ├── investment.py
│   │   ├── portfolio.py
│   │   ├── price_history.py
│   │   └── user.py
│   ├── schemas/
│   │   ├── investment.py
│   │   ├── portfolio.py
│   │   └── recommendation.py
│   ├── services/
│   │   ├── yahoo_finance.py
│   │   ├── portfolio_analyzer.py
│   │   └── recommendation_agent.py
│   └── main.py
├── tests/
├── docs/
├── requirements.txt
├── .env.example
└── README.md
```

## Modèles de données

### Investment
```python
class Investment:
    id: UUID
    user_id: UUID
    symbol: str              # Ticker symbol (AAPL, BTC-USD, etc.)
    name: str               # Nom de l'entreprise/actif
    asset_type: str         # stock, etf, crypto, bond
    country: str            # Pays d'origine
    sector: str             # Secteur d'activité
    purchase_date: datetime
    purchase_price: float
    quantity: float
    currency: str
    created_at: datetime
    updated_at: datetime
```

### PriceHistory
```python
class PriceHistory:
    id: UUID
    investment_id: UUID
    price: float
    market_cap: Optional[float]
    volume: Optional[float]
    timestamp: datetime
    source: str              # yahoo_finance, manual, etc.
```

### Portfolio
```python
class Portfolio:
    id: UUID
    user_id: UUID
    total_value: float
    total_cost: float
    total_gain_loss: float
    total_gain_loss_percent: float
    diversification_score: float
    last_updated: datetime
```

## Endpoints API

### 📈 Gestion des investissements

#### `GET /api/v1/investments/search?name={company_name}`
Rechercher un symbole d'investissement par nom d'entreprise
**Paramètres de requête :**
- `name` (string, requis) : Nom de l'entreprise à rechercher
- `limit` (int, optionnel) : Nombre maximum de résultats (défaut: 10)

**Exemple :**
```
GET /api/v1/investments/search?name=Apple&limit=5
```

**Réponse :**
```json
{
  "results": [
    {
      "symbol": "AAPL",
      "name": "Apple Inc.",
      "asset_type": "stock",
      "country": "USA",
      "sector": "Technology",
      "market_cap": 3000000000000,
      "currency": "USD",
      "exchange": "NASDAQ"
    },
    {
      "symbol": "AAPL.MX",
      "name": "Apple Inc.",
      "asset_type": "stock", 
      "country": "MEX",
      "sector": "Technology",
      "market_cap": 3000000000000,
      "currency": "MXN",
      "exchange": "BMV"
    }
  ],
  "total": 2,
  "query": "Apple"
}
```

#### `POST /api/v1/investments/`
Ajouter un nouvel investissement
```json
{
  "symbol": "AAPL",
  "name": "Apple Inc.",
  "asset_type": "stock",
  "country": "USA",
  "sector": "Technology",
  "purchase_date": "2024-01-15",
  "purchase_price": 185.50,
  "quantity": 10,
  "currency": "USD"
}
```

#### `GET /api/v1/investments/`
Récupérer tous les investissements de l'utilisateur

#### `GET /api/v1/investments/{investment_id}`
Récupérer un investissement spécifique

#### `PUT /api/v1/investments/{investment_id}`
Modifier un investissement

#### `DELETE /api/v1/investments/{investment_id}`
Supprimer un investissement

### 💰 Mise à jour des prix

#### `POST /api/v1/prices/update`
Mettre à jour les prix de tous les investissements

#### `GET /api/v1/prices/history/{investment_id}`
Récupérer l'historique des prix d'un investissement

### 📊 Analyse du portfolio

#### `GET /api/v1/portfolio/summary`
Récupérer le résumé du portfolio
```json
{
  "total_value": 25000.00,
  "total_cost": 22000.00,
  "total_gain_loss": 3000.00,
  "total_gain_loss_percent": 13.64,
  "diversification_score": 8.5,
  "by_country": {
    "USA": 60.0,
    "France": 25.0,
    "Germany": 15.0
  },
  "by_sector": {
    "Technology": 40.0,
    "Healthcare": 20.0,
    "Finance": 15.0,
    "Consumer Goods": 25.0
  },
  "by_asset_type": {
    "stock": 70.0,
    "etf": 20.0,
    "crypto": 10.0
  }
}
```

#### `GET /api/v1/portfolio/diversification`
Analyse détaillée de la diversité du portfolio

### 🤖 Recommandations

#### `POST /api/v1/recommendations/generate`
Générer des recommandations d'investissement
```json
{
  "investment_horizon": "long_term",
  "risk_tolerance": "moderate",
  "investment_amount": 5000.00,
  "preferences": {
    "countries": ["USA", "France"],
    "sectors": ["Technology", "Healthcare"],
    "exclude_sectors": ["Tobacco", "Weapons"]
  }
}
```

#### `GET /api/v1/recommendations/`
Récupérer les recommandations précédentes
