# Schéma de Base de Données - Investment Portfolio

## Vue d'ensemble

Ce document décrit le schéma de base de données pour l'application Investment Portfolio. La base de données utilise PostgreSQL en production et SQLite en développement, avec SQLAlchemy comme ORM.

## Tables principales

### 1. Users (Utilisateurs)

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    currency_preference VARCHAR(3) DEFAULT 'USD',
    risk_tolerance VARCHAR(20) CHECK (risk_tolerance IN ('conservative', 'moderate', 'aggressive')),
    is_active BOOLEAN DEFAULT TRUE,
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active);
```

### 2. Investments (Investissements)

```sql
CREATE TABLE investments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    symbol VARCHAR(20) NOT NULL,
    name VARCHAR(255) NOT NULL,
    asset_type VARCHAR(20) CHECK (asset_type IN ('stock', 'etf', 'crypto', 'bond', 'commodity', 'reit', 'mutual_fund')),
    country VARCHAR(3) NOT NULL, -- Code ISO 3166-1 alpha-3
    sector VARCHAR(100),
    industry VARCHAR(100),
    market_cap_category VARCHAR(20) CHECK (market_cap_category IN ('large_cap', 'mid_cap', 'small_cap', 'micro_cap')),
    purchase_date DATE NOT NULL,
    purchase_price DECIMAL(15,4) NOT NULL,
    quantity DECIMAL(15,8) NOT NULL,
    currency VARCHAR(3) NOT NULL, -- Code ISO 4217
    current_price DECIMAL(15,4),
    current_value DECIMAL(15,2),
    gain_loss DECIMAL(15,2),
    gain_loss_percent DECIMAL(8,4),
    dividend_yield DECIMAL(5,4),
    expense_ratio DECIMAL(5,4), -- Pour les ETF et fonds mutuels
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_investments_user_id ON investments(user_id);
CREATE INDEX idx_investments_symbol ON investments(symbol);
CREATE INDEX idx_investments_asset_type ON investments(asset_type);
CREATE INDEX idx_investments_country ON investments(country);
CREATE INDEX idx_investments_sector ON investments(sector);
CREATE INDEX idx_investments_active ON investments(is_active);
CREATE INDEX idx_investments_purchase_date ON investments(purchase_date);

-- Contrainte pour éviter les doublons d'investissements pour un utilisateur
CREATE UNIQUE INDEX idx_investments_user_symbol_unique 
ON investments(user_id, symbol) WHERE is_active = TRUE;
```

### 3. Price History (Historique des prix)

```sql
CREATE TABLE price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    investment_id UUID NOT NULL REFERENCES investments(id) ON DELETE CASCADE,
    price DECIMAL(15,4) NOT NULL,
    market_cap BIGINT,
    volume BIGINT,
    open_price DECIMAL(15,4),
    high_price DECIMAL(15,4),
    low_price DECIMAL(15,4),
    close_price DECIMAL(15,4),
    adjusted_close DECIMAL(15,4),
    dividend_amount DECIMAL(10,4),
    split_ratio DECIMAL(8,4),
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    source VARCHAR(50) DEFAULT 'yahoo_finance',
    data_quality VARCHAR(20) DEFAULT 'good' CHECK (data_quality IN ('good', 'delayed', 'estimated', 'missing')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_price_history_investment_id ON price_history(investment_id);
CREATE INDEX idx_price_history_timestamp ON price_history(timestamp);
CREATE INDEX idx_price_history_investment_timestamp ON price_history(investment_id, timestamp);
CREATE INDEX idx_price_history_source ON price_history(source);

-- Contrainte pour éviter les doublons de prix à la même heure
CREATE UNIQUE INDEX idx_price_history_unique 
ON price_history(investment_id, timestamp, source);
```

### 4. Portfolio Snapshots (Instantanés de portfolio)

```sql
CREATE TABLE portfolio_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    snapshot_date DATE NOT NULL,
    total_value DECIMAL(15,2) NOT NULL,
    total_cost DECIMAL(15,2) NOT NULL,
    total_gain_loss DECIMAL(15,2) NOT NULL,
    total_gain_loss_percent DECIMAL(8,4) NOT NULL,
    diversification_score DECIMAL(3,2),
    risk_score DECIMAL(3,2),
    currency VARCHAR(3) NOT NULL,
    investment_count INTEGER NOT NULL,
    breakdown_by_country JSONB,
    breakdown_by_sector JSONB,
    breakdown_by_asset_type JSONB,
    top_performers JSONB,
    worst_performers JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_portfolio_snapshots_user_id ON portfolio_snapshots(user_id);
CREATE INDEX idx_portfolio_snapshots_date ON portfolio_snapshots(snapshot_date);
CREATE INDEX idx_portfolio_snapshots_user_date ON portfolio_snapshots(user_id, snapshot_date);

-- Contrainte pour éviter les doublons de snapshots par jour
CREATE UNIQUE INDEX idx_portfolio_snapshots_unique 
ON portfolio_snapshots(user_id, snapshot_date);
```

### 5. Investment Transactions (Transactions d'investissement)

```sql
CREATE TABLE investment_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    investment_id UUID NOT NULL REFERENCES investments(id) ON DELETE CASCADE,
    transaction_type VARCHAR(20) CHECK (transaction_type IN ('buy', 'sell', 'dividend', 'split', 'bonus')),
    transaction_date DATE NOT NULL,
    quantity DECIMAL(15,8) NOT NULL,
    price DECIMAL(15,4) NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL,
    fees DECIMAL(10,2) DEFAULT 0,
    currency VARCHAR(3) NOT NULL,
    exchange_rate DECIMAL(10,6) DEFAULT 1.0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transactions_investment_id ON investment_transactions(investment_id);
CREATE INDEX idx_transactions_date ON investment_transactions(transaction_date);
CREATE INDEX idx_transactions_type ON investment_transactions(transaction_type);
```

### 6. Recommendations (Recommandations)

```sql
CREATE TABLE recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recommendation_type VARCHAR(50) DEFAULT 'portfolio_optimization',
    investment_horizon VARCHAR(20) CHECK (investment_horizon IN ('short_term', 'medium_term', 'long_term')),
    risk_tolerance VARCHAR(20) CHECK (risk_tolerance IN ('conservative', 'moderate', 'aggressive')),
    total_recommended_amount DECIMAL(15,2),
    currency VARCHAR(3) NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'applied', 'dismissed', 'expired')),
    confidence_score DECIMAL(3,2),
    generated_by VARCHAR(50) DEFAULT 'ai_agent',
    market_analysis JSONB,
    portfolio_impact JSONB,
    reasoning TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_recommendations_user_id ON recommendations(user_id);
CREATE INDEX idx_recommendations_status ON recommendations(status);
CREATE INDEX idx_recommendations_created_at ON recommendations(created_at);
CREATE INDEX idx_recommendations_expires_at ON recommendations(expires_at);
```

### 7. Recommendation Items (Éléments de recommandation)

```sql
CREATE TABLE recommendation_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recommendation_id UUID NOT NULL REFERENCES recommendations(id) ON DELETE CASCADE,
    symbol VARCHAR(20) NOT NULL,
    name VARCHAR(255) NOT NULL,
    asset_type VARCHAR(20) NOT NULL,
    country VARCHAR(3) NOT NULL,
    sector VARCHAR(100),
    recommended_amount DECIMAL(15,2) NOT NULL,
    recommended_percentage DECIMAL(5,2) NOT NULL,
    current_price DECIMAL(15,4),
    target_price DECIMAL(15,4),
    time_horizon VARCHAR(50),
    risk_score DECIMAL(3,2),
    expected_return DECIMAL(5,2),
    confidence_score DECIMAL(3,2),
    reasoning TEXT,
    applied BOOLEAN DEFAULT FALSE,
    applied_date TIMESTAMP WITH TIME ZONE,
    applied_amount DECIMAL(15,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_recommendation_items_recommendation_id ON recommendation_items(recommendation_id);
CREATE INDEX idx_recommendation_items_symbol ON recommendation_items(symbol);
CREATE INDEX idx_recommendation_items_applied ON recommendation_items(applied);
```

### 8. User Preferences (Préférences utilisateur)

```sql
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    preferred_countries TEXT[], -- Array de codes pays
    preferred_sectors TEXT[], -- Array de secteurs
    excluded_sectors TEXT[], -- Array de secteurs à exclure
    preferred_asset_types TEXT[], -- Array de types d'actifs
    min_market_cap BIGINT,
    max_pe_ratio DECIMAL(5,2),
    min_dividend_yield DECIMAL(5,4),
    max_expense_ratio DECIMAL(5,4),
    investment_objectives TEXT[], -- growth, income, preservation, etc.
    notification_preferences JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);
```

### 9. Market Data Cache (Cache des données de marché)

```sql
CREATE TABLE market_data_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    symbol VARCHAR(20) NOT NULL,
    data_type VARCHAR(50) NOT NULL, -- 'quote', 'profile', 'news', etc.
    data JSONB NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_market_cache_symbol ON market_data_cache(symbol);
CREATE INDEX idx_market_cache_type ON market_data_cache(data_type);
CREATE INDEX idx_market_cache_expires ON market_data_cache(expires_at);

-- Contrainte pour éviter les doublons
CREATE UNIQUE INDEX idx_market_cache_unique 
ON market_data_cache(symbol, data_type);
```

### 10. API Usage Logs (Logs d'utilisation API)

```sql
CREATE TABLE api_usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    endpoint VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER NOT NULL,
    response_time_ms INTEGER,
    request_size_bytes INTEGER,
    response_size_bytes INTEGER,
    ip_address INET,
    user_agent TEXT,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_api_logs_user_id ON api_usage_logs(user_id);
CREATE INDEX idx_api_logs_endpoint ON api_usage_logs(endpoint);
CREATE INDEX idx_api_logs_created_at ON api_usage_logs(created_at);
CREATE INDEX idx_api_logs_status_code ON api_usage_logs(status_code);
```

## Vues utiles

### 1. Vue Portfolio Summary

```sql
CREATE VIEW portfolio_summary AS
SELECT 
    u.id as user_id,
    u.email,
    u.currency_preference,
    COUNT(i.id) as total_investments,
    COALESCE(SUM(i.current_value), 0) as total_value,
    COALESCE(SUM(i.purchase_price * i.quantity), 0) as total_cost,
    COALESCE(SUM(i.gain_loss), 0) as total_gain_loss,
    CASE 
        WHEN COALESCE(SUM(i.purchase_price * i.quantity), 0) > 0 
        THEN (COALESCE(SUM(i.gain_loss), 0) / SUM(i.purchase_price * i.quantity)) * 100
        ELSE 0 
    END as total_gain_loss_percent,
    COUNT(DISTINCT i.country) as countries_count,
    COUNT(DISTINCT i.sector) as sectors_count,
    COUNT(DISTINCT i.asset_type) as asset_types_count
FROM users u
LEFT JOIN investments i ON u.id = i.user_id AND i.is_active = TRUE
GROUP BY u.id, u.email, u.currency_preference;
```

### 2. Vue Top Performers

```sql
CREATE VIEW top_performers AS
SELECT 
    i.user_id,
    i.symbol,
    i.name,
    i.current_price,
    i.purchase_price,
    i.gain_loss_percent,
    i.sector,
    i.country,
    ROW_NUMBER() OVER (PARTITION BY i.user_id ORDER BY i.gain_loss_percent DESC) as rank
FROM investments i
WHERE i.is_active = TRUE 
AND i.current_price IS NOT NULL
AND i.gain_loss_percent IS NOT NULL;
```

### 3. Vue Diversification Analysis

```sql
CREATE VIEW diversification_analysis AS
WITH portfolio_stats AS (
    SELECT 
        i.user_id,
        COUNT(*) as total_investments,
        COUNT(DISTINCT i.country) as countries_count,
        COUNT(DISTINCT i.sector) as sectors_count,
        COUNT(DISTINCT i.asset_type) as asset_types_count,
        SUM(i.current_value) as total_value
    FROM investments i
    WHERE i.is_active = TRUE AND i.current_value IS NOT NULL
    GROUP BY i.user_id
),
country_diversity AS (
    SELECT 
        i.user_id,
        i.country,
        SUM(i.current_value) as country_value,
        (SUM(i.current_value) / ps.total_value) as country_percentage
    FROM investments i
    JOIN portfolio_stats ps ON i.user_id = ps.user_id
    WHERE i.is_active = TRUE AND i.current_value IS NOT NULL
    GROUP BY i.user_id, i.country, ps.total_value
)
SELECT 
    ps.user_id,
    ps.total_investments,
    ps.countries_count,
    ps.sectors_count,
    ps.asset_types_count,
    -- Calcul de l'indice de Herfindahl pour la diversité géographique
    COALESCE(
        1 - SUM(POWER(cd.country_percentage, 2)), 
        0
    ) as geographic_diversification_score
FROM portfolio_stats ps
LEFT JOIN country_diversity cd ON ps.user_id = cd.user_id
GROUP BY ps.user_id, ps.total_investments, ps.countries_count, ps.sectors_count, ps.asset_types_count;
```

## Triggers et fonctions

### 1. Mise à jour automatique des valeurs

```sql
CREATE OR REPLACE FUNCTION update_investment_values()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculer la valeur actuelle
    NEW.current_value = NEW.current_price * NEW.quantity;
    
    -- Calculer le gain/perte
    NEW.gain_loss = NEW.current_value - (NEW.purchase_price * NEW.quantity);
    
    -- Calculer le pourcentage de gain/perte
    IF NEW.purchase_price * NEW.quantity > 0 THEN
        NEW.gain_loss_percent = (NEW.gain_loss / (NEW.purchase_price * NEW.quantity)) * 100;
    ELSE
        NEW.gain_loss_percent = 0;
    END IF;
    
    -- Mettre à jour le timestamp
    NEW.updated_at = CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_investment_values
    BEFORE UPDATE OF current_price ON investments
    FOR EACH ROW
    EXECUTE FUNCTION update_investment_values();
```

### 2. Nettoyage automatique du cache

```sql
CREATE OR REPLACE FUNCTION cleanup_expired_cache()
RETURNS void AS $$
BEGIN
    DELETE FROM market_data_cache WHERE expires_at < CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Programmer cette fonction avec pg_cron ou un scheduler externe
```

## Index composites optimisés

```sql
-- Index pour les requêtes fréquentes de portfolio
CREATE INDEX idx_investments_user_active_updated 
ON investments(user_id, is_active, updated_at);

-- Index pour l'historique des prix avec plage de dates
CREATE INDEX idx_price_history_investment_date_range 
ON price_history(investment_id, timestamp DESC);

-- Index pour les recommandations actives
CREATE INDEX idx_recommendations_user_active 
ON recommendations(user_id, status, created_at DESC) 
WHERE status = 'active';

-- Index pour les logs API avec filtrage temporel
CREATE INDEX idx_api_logs_user_date_status 
ON api_usage_logs(user_id, created_at DESC, status_code);
```

## Contraintes et validations

### Contraintes de données

```sql
-- Vérifier que la quantité est positive
ALTER TABLE investments ADD CONSTRAINT chk_positive_quantity 
CHECK (quantity > 0);

-- Vérifier que le prix est positif
ALTER TABLE investments ADD CONSTRAINT chk_positive_prices 
CHECK (purchase_price > 0 AND (current_price IS NULL OR current_price > 0));

-- Vérifier que les pourcentages sont dans une plage raisonnable
ALTER TABLE investments ADD CONSTRAINT chk_gain_loss_percent 
CHECK (gain_loss_percent >= -100);

-- Vérifier que les dates sont cohérentes
ALTER TABLE investments ADD CONSTRAINT chk_purchase_date_not_future 
CHECK (purchase_date <= CURRENT_DATE);

-- Vérifier que les montants de recommandation sont positifs
ALTER TABLE recommendation_items ADD CONSTRAINT chk_positive_recommended_amount 
CHECK (recommended_amount > 0);
```

## Configuration de performance

### Paramètres PostgreSQL recommandés

```sql
-- Optimisations pour les requêtes analytiques
ALTER SYSTEM SET work_mem = '256MB';
ALTER SYSTEM SET shared_buffers = '1GB';
ALTER SYSTEM SET effective_cache_size = '3GB';
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET seq_page_cost = 1.0;

-- Configuration pour les statistiques
ALTER SYSTEM SET default_statistics_target = 1000;
```

### Partitioning (pour les grandes tables)

```sql
-- Partitioning par date pour price_history (si nécessaire)
CREATE TABLE price_history_y2024 PARTITION OF price_history
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- Partitioning par utilisateur pour api_usage_logs (si nécessaire)
CREATE TABLE api_logs_user_1 PARTITION OF api_usage_logs
FOR VALUES WITH (modulus 4, remainder 0);
```

Ce schéma de base de données est conçu pour être extensible, performant et maintenir l'intégrité des données tout en supportant les fonctionnalités avancées de l'application d'investissement.
