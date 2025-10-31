# Spécification API - Investment Portfolio

## Vue d'ensemble

Cette document décrit en détail l'API REST de l'application Investment Portfolio. L'API suit les conventions RESTful et utilise le format JSON pour l'échange de données.

## Base URL

```
http://localhost:8000/api/v1
```

## Authentification

L'API utilise l'authentification JWT (JSON Web Tokens). Incluez le token dans l'en-tête Authorization :

```
Authorization: Bearer <your_jwt_token>
```

## Codes de réponse HTTP

- `200 OK` - Requête réussie
- `201 Created` - Ressource créée avec succès
- `400 Bad Request` - Données de requête invalides
- `401 Unauthorized` - Token d'authentification manquant ou invalide
- `403 Forbidden` - Accès non autorisé
- `404 Not Found` - Ressource non trouvée
- `422 Unprocessable Entity` - Erreur de validation
- `500 Internal Server Error` - Erreur serveur

## Endpoints

### 1. Gestion des investissements

#### `GET /investments/search`
Rechercher un symbole d'investissement par nom d'entreprise

**Query Parameters :**
- `name` (str, requis) : Nom de l'entreprise à rechercher
- `limit` (int, optionnel) : Nombre maximum de résultats (défaut: 10, max: 50)
- `asset_type` (str, optionnel) : Filtrer par type d'actif (stock, etf, crypto, etc.)
- `country` (str, optionnel) : Filtrer par code pays (ISO 3166-1 alpha-3)

**Exemple de requête :**
```
GET /api/v1/investments/search?name=Apple&limit=5&asset_type=stock&country=USA
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
      "industry": "Consumer Electronics",
      "market_cap": 3000000000000,
      "currency": "USD",
      "exchange": "NASDAQ",
      "current_price": 190.25,
      "price_change_percent": 1.2,
      "volume": 50000000,
      "is_tradable": true
    },
    {
      "symbol": "AAPL.MX",
      "name": "Apple Inc.",
      "asset_type": "stock",
      "country": "MEX", 
      "sector": "Technology",
      "industry": "Consumer Electronics",
      "market_cap": 3000000000000,
      "currency": "MXN",
      "exchange": "BMV",
      "current_price": 3200.50,
      "price_change_percent": 0.8,
      "volume": 150000,
      "is_tradable": true
    }
  ],
  "total": 2,
  "query": "Apple",
  "filters_applied": {
    "asset_type": "stock",
    "country": "USA"
  },
  "search_time_ms": 245
}
```

**Codes d'erreur :**
- `400 Bad Request` : Paramètre `name` manquant ou invalide
- `422 Unprocessable Entity` : Paramètres de filtrage invalides
- `503 Service Unavailable` : Service de recherche temporairement indisponible

#### `POST /investments/`
Créer un nouvel investissement

**Body :**
```json
{
  "symbol": "AAPL",
  "name": "Apple Inc.",
  "asset_type": "stock",
  "country": "USA",
  "sector": "Technology",
  "purchase_date": "2024-01-15T00:00:00Z",
  "purchase_price": 185.50,
  "quantity": 10,
  "currency": "USD"
}
```

**Réponse :**
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "user_id": "123e4567-e89b-12d3-a456-426614174001",
  "symbol": "AAPL",
  "name": "Apple Inc.",
  "asset_type": "stock",
  "country": "USA",
  "sector": "Technology",
  "purchase_date": "2024-01-15T00:00:00Z",
  "purchase_price": 185.50,
  "quantity": 10,
  "currency": "USD",
  "current_price": 190.25,
  "current_value": 1902.50,
  "gain_loss": 47.50,
  "gain_loss_percent": 2.56,
  "created_at": "2024-01-20T10:30:00Z",
  "updated_at": "2024-01-20T10:30:00Z"
}
```

#### `GET /investments/`
Récupérer tous les investissements de l'utilisateur

**Query Parameters :**
- `limit` (int, optionnel) : Nombre maximum d'éléments à retourner (défaut: 100)
- `offset` (int, optionnel) : Nombre d'éléments à ignorer (défaut: 0)
- `asset_type` (str, optionnel) : Filtrer par type d'actif
- `country` (str, optionnel) : Filtrer par pays
- `sector` (str, optionnel) : Filtrer par secteur

**Réponse :**
```json
{
  "items": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "symbol": "AAPL",
      "name": "Apple Inc.",
      "asset_type": "stock",
      "country": "USA",
      "sector": "Technology",
      "purchase_date": "2024-01-15T00:00:00Z",
      "purchase_price": 185.50,
      "quantity": 10,
      "currency": "USD",
      "current_price": 190.25,
      "current_value": 1902.50,
      "gain_loss": 47.50,
      "gain_loss_percent": 2.56,
      "created_at": "2024-01-20T10:30:00Z",
      "updated_at": "2024-01-20T10:30:00Z"
    }
  ],
  "total": 1,
  "limit": 100,
  "offset": 0
}
```

#### `GET /investments/{investment_id}`
Récupérer un investissement spécifique

**Réponse :** Identique à la réponse de création

#### `PUT /investments/{investment_id}`
Mettre à jour un investissement

**Body :** Même structure que la création (tous les champs optionnels)

**Réponse :** Investissement mis à jour

#### `DELETE /investments/{investment_id}`
Supprimer un investissement

**Réponse :**
```json
{
  "message": "Investment deleted successfully",
  "investment_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

### 2. Gestion des prix

#### `POST /prices/update`
Mettre à jour les prix de tous les investissements

**Réponse :**
```json
{
  "message": "Prices updated successfully",
  "updated_count": 15,
  "errors": []
}
```

#### `GET /prices/history/{investment_id}`
Récupérer l'historique des prix d'un investissement

**Query Parameters :**
- `start_date` (str, optionnel) : Date de début (format ISO 8601)
- `end_date` (str, optionnel) : Date de fin (format ISO 8601)
- `limit` (int, optionnel) : Nombre maximum d'entrées (défaut: 100)

**Réponse :**
```json
{
  "investment_id": "123e4567-e89b-12d3-a456-426614174000",
  "symbol": "AAPL",
  "price_history": [
    {
      "price": 190.25,
      "market_cap": 3000000000000,
      "volume": 50000000,
      "timestamp": "2024-01-20T16:00:00Z",
      "source": "yahoo_finance"
    },
    {
      "price": 189.80,
      "market_cap": 2995000000000,
      "volume": 45000000,
      "timestamp": "2024-01-19T16:00:00Z",
      "source": "yahoo_finance"
    }
  ],
  "total": 2
}
```

#### `POST /prices/update/{investment_id}`
Mettre à jour le prix d'un investissement spécifique

**Réponse :**
```json
{
  "investment_id": "123e4567-e89b-12d3-a456-426614174000",
  "symbol": "AAPL",
  "old_price": 189.80,
  "new_price": 190.25,
  "price_change": 0.45,
  "price_change_percent": 0.24,
  "timestamp": "2024-01-20T16:00:00Z"
}
```

### 3. Analyse du portfolio

#### `GET /portfolio/summary`
Récupérer le résumé complet du portfolio

**Réponse :**
```json
{
  "portfolio_id": "123e4567-e89b-12d3-a456-426614174002",
  "total_value": 25000.00,
  "total_cost": 22000.00,
  "total_gain_loss": 3000.00,
  "total_gain_loss_percent": 13.64,
  "diversification_score": 8.5,
  "risk_score": 6.2,
  "last_updated": "2024-01-20T16:00:00Z",
  "currency": "USD",
  "breakdown": {
    "by_country": {
      "USA": {
        "value": 15000.00,
        "percentage": 60.0,
        "count": 8
      },
      "France": {
        "value": 6250.00,
        "percentage": 25.0,
        "count": 3
      },
      "Germany": {
        "value": 3750.00,
        "percentage": 15.0,
        "count": 2
      }
    },
    "by_sector": {
      "Technology": {
        "value": 10000.00,
        "percentage": 40.0,
        "count": 5
      },
      "Healthcare": {
        "value": 5000.00,
        "percentage": 20.0,
        "count": 2
      },
      "Finance": {
        "value": 3750.00,
        "percentage": 15.0,
        "count": 2
      },
      "Consumer Goods": {
        "value": 6250.00,
        "percentage": 25.0,
        "count": 4
      }
    },
    "by_asset_type": {
      "stock": {
        "value": 17500.00,
        "percentage": 70.0,
        "count": 10
      },
      "etf": {
        "value": 5000.00,
        "percentage": 20.0,
        "count": 3
      },
      "crypto": {
        "value": 2500.00,
        "percentage": 10.0,
        "count": 2
      }
    }
  },
  "top_performers": [
    {
      "symbol": "AAPL",
      "name": "Apple Inc.",
      "gain_loss_percent": 15.2
    }
  ],
  "worst_performers": [
    {
      "symbol": "TSLA",
      "name": "Tesla Inc.",
      "gain_loss_percent": -8.5
    }
  ]
}
```

#### `GET /portfolio/diversification`
Analyse détaillée de la diversité du portfolio

**Réponse :**
```json
{
  "overall_score": 8.5,
  "recommendations": [
    {
      "type": "geographic_diversification",
      "message": "Consider adding emerging markets exposure",
      "priority": "medium"
    },
    {
      "type": "sector_diversification",
      "message": "Technology sector is over-represented (40%)",
      "priority": "high"
    }
  ],
  "detailed_analysis": {
    "geographic_diversification": {
      "score": 7.0,
      "herfindahl_index": 0.485,
      "concentration_risk": "medium"
    },
    "sector_diversification": {
      "score": 8.0,
      "herfindahl_index": 0.285,
      "concentration_risk": "low"
    },
    "asset_type_diversification": {
      "score": 6.5,
      "herfindahl_index": 0.540,
      "concentration_risk": "medium"
    }
  }
}
```

#### `GET /portfolio/performance`
Analyse de performance du portfolio

**Query Parameters :**
- `period` (str, optionnel) : 1m, 3m, 6m, 1y, 2y, 5y, all (défaut: 1y)

**Réponse :**
```json
{
  "period": "1y",
  "portfolio_return": 13.64,
  "benchmark_return": 10.25,
  "alpha": 3.39,
  "beta": 1.12,
  "sharpe_ratio": 1.45,
  "max_drawdown": -8.5,
  "volatility": 18.2,
  "monthly_returns": [
    {
      "month": "2024-01",
      "return": 2.5
    },
    {
      "month": "2023-12",
      "return": 1.8
    }
  ]
}
```

### 4. Recommandations d'investissement

#### `POST /recommendations/generate`
Générer de nouvelles recommandations

**Body :**
```json
{
  "investment_horizon": "long_term",
  "risk_tolerance": "moderate",
  "investment_amount": 5000.00,
  "currency": "USD",
  "preferences": {
    "countries": ["USA", "France", "Germany"],
    "sectors": ["Technology", "Healthcare", "Finance"],
    "exclude_sectors": ["Tobacco", "Weapons", "Fossil Fuels"],
    "asset_types": ["stock", "etf"],
    "min_market_cap": 1000000000,
    "max_pe_ratio": 25
  },
  "objectives": [
    "growth",
    "diversification",
    "income"
  ]
}
```

**Réponse :**
```json
{
  "recommendation_id": "123e4567-e89b-12d3-a456-426614174003",
  "generated_at": "2024-01-20T16:00:00Z",
  "investment_horizon": "long_term",
  "risk_tolerance": "moderate",
  "total_recommended_amount": 5000.00,
  "recommendations": [
    {
      "symbol": "MSFT",
      "name": "Microsoft Corporation",
      "asset_type": "stock",
      "country": "USA",
      "sector": "Technology",
      "recommended_amount": 1500.00,
      "recommended_percentage": 30.0,
      "reasoning": "Strong fundamentals, cloud growth, dividend yield 0.8%",
      "risk_score": 6.5,
      "expected_return": 12.5,
      "confidence_score": 0.85,
      "current_price": 415.50,
      "target_price": 450.00,
      "time_horizon": "12-18 months"
    },
    {
      "symbol": "VTI",
      "name": "Vanguard Total Stock Market ETF",
      "asset_type": "etf",
      "country": "USA",
      "sector": "Diversified",
      "recommended_amount": 2000.00,
      "recommended_percentage": 40.0,
      "reasoning": "Broad market exposure, low fees (0.03%), good for diversification",
      "risk_score": 7.0,
      "expected_return": 10.0,
      "confidence_score": 0.90,
      "current_price": 245.80,
      "target_price": 270.00,
      "time_horizon": "3-5 years"
    }
  ],
  "portfolio_impact": {
    "diversification_improvement": 0.15,
    "risk_reduction": 0.08,
    "expected_return_increase": 0.02
  },
  "market_analysis": {
    "current_market_conditions": "bullish",
    "key_risks": ["inflation", "interest_rates"],
    "opportunities": ["AI sector growth", "renewable energy transition"]
  }
}
```

#### `GET /recommendations/`
Récupérer l'historique des recommandations

**Query Parameters :**
- `limit` (int, optionnel) : Nombre maximum de recommandations
- `offset` (int, optionnel) : Offset pour la pagination
- `status` (str, optionnel) : active, applied, dismissed

**Réponse :**
```json
{
  "items": [
    {
      "recommendation_id": "123e4567-e89b-12d3-a456-426614174003",
      "generated_at": "2024-01-20T16:00:00Z",
      "status": "active",
      "investment_horizon": "long_term",
      "risk_tolerance": "moderate",
      "total_recommended_amount": 5000.00,
      "recommendations_count": 3,
      "applied_count": 0
    }
  ],
  "total": 1,
  "limit": 100,
  "offset": 0
}
```

#### `GET /recommendations/{recommendation_id}`
Récupérer une recommandation spécifique

**Réponse :** Même structure que la génération de recommandation

#### `POST /recommendations/{recommendation_id}/apply`
Marquer une recommandation comme appliquée

**Body :**
```json
{
  "applied_investments": [
    {
      "symbol": "MSFT",
      "applied_amount": 1500.00,
      "applied_date": "2024-01-21T10:00:00Z"
    }
  ],
  "notes": "Applied Microsoft recommendation, will consider VTI later"
}
```

#### `POST /recommendations/{recommendation_id}/dismiss`
Marquer une recommandation comme rejetée

**Body :**
```json
{
  "reason": "Too risky for current market conditions",
  "notes": "Will reconsider when market stabilizes"
}
```

### 5. Authentification et utilisateurs

#### `POST /auth/register`
Enregistrer un nouvel utilisateur

**Body :**
```json
{
  "email": "user@example.com",
  "password": "securepassword123",
  "full_name": "John Doe",
  "currency_preference": "USD",
  "risk_tolerance": "moderate"
}
```

#### `POST /auth/login`
Connexion utilisateur

**Body :**
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Réponse :**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174001",
    "email": "user@example.com",
    "full_name": "John Doe",
    "currency_preference": "USD",
    "risk_tolerance": "moderate",
    "created_at": "2024-01-15T10:00:00Z"
  }
}
```

#### `GET /auth/me`
Récupérer les informations de l'utilisateur connecté

#### `PUT /auth/me`
Mettre à jour le profil utilisateur

#### `POST /auth/refresh`
Renouveler le token d'accès

## Gestion des erreurs

### Format d'erreur standard

```json
{
  "detail": [
    {
      "loc": ["body", "symbol"],
      "msg": "field required",
      "type": "value_error.missing"
    },
    {
      "loc": ["body", "purchase_price"],
      "msg": "ensure this value is greater than 0",
      "type": "value_error.number.not_gt",
      "ctx": {"limit_value": 0}
    }
  ]
}
```

### Codes d'erreur personnalisés

- `INVESTMENT_NOT_FOUND` (404) : Investissement non trouvé
- `INVALID_SYMBOL` (400) : Symbole d'investissement invalide
- `PRICE_UPDATE_FAILED` (500) : Échec de mise à jour des prix
- `RECOMMENDATION_GENERATION_FAILED` (500) : Échec de génération de recommandation
- `INSUFFICIENT_PERMISSIONS` (403) : Permissions insuffisantes

## Limites et quotas

- **Requêtes par minute** : 100 requêtes par utilisateur
- **Mise à jour des prix** : Maximum 1 par minute par utilisateur
- **Génération de recommandations** : Maximum 5 par jour par utilisateur
- **Taille des requêtes** : Maximum 1MB par requête
- **Historique des prix** : Maximum 1000 entrées par investissement

## Webhooks (optionnel)

### Configuration des webhooks

```json
{
  "webhook_url": "https://your-app.com/webhook",
  "events": ["price_update", "recommendation_generated"],
  "secret": "your_webhook_secret"
}
```

### Format des webhooks

```json
{
  "event": "price_update",
  "timestamp": "2024-01-20T16:00:00Z",
  "data": {
    "investment_id": "123e4567-e89b-12d3-a456-426614174000",
    "symbol": "AAPL",
    "old_price": 189.80,
    "new_price": 190.25,
    "price_change_percent": 0.24
  }
}
```
