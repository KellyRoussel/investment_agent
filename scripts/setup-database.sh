#!/bin/bash

# Script pour configurer la base de données avec Docker et Alembic

set -e

echo "🚀 Configuration de la base de données Investment Portfolio..."

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Veuillez installer Docker d'abord."
    exit 1
fi

# Vérifier si Docker Compose est installé
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé. Veuillez installer Docker Compose d'abord."
    exit 1
fi

# Créer l'environnement virtuel Python s'il n'existe pas
if [ ! -d "venv" ]; then
    echo "📦 Création de l'environnement virtuel Python..."
    python -m venv venv
fi

# Activer l'environnement virtuel
echo "🔧 Activation de l'environnement virtuel..."
source venv/bin/activate

# Installer les dépendances
echo "📚 Installation des dépendances Python..."
pip install --upgrade pip
pip install -r requirements.txt

# Démarrer PostgreSQL avec Docker Compose
echo "🐘 Démarrage de PostgreSQL..."
docker-compose up -d postgres

# Attendre que PostgreSQL soit prêt
echo "⏳ Attente que PostgreSQL soit prêt..."
until docker-compose exec postgres pg_isready -U postgres -d investment_portfolio; do
    echo "PostgreSQL n'est pas encore prêt, attente..."
    sleep 2
done

echo "✅ PostgreSQL est prêt!"

# Configurer les variables d'environnement pour Alembic
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/investment_portfolio"

# Créer la migration initiale avec Alembic
echo "🔄 Création de la migration initiale..."
alembic revision --autogenerate -m "Initial migration"

# Appliquer les migrations
echo "🚀 Application des migrations..."
alembic upgrade head

# Vérifier que les tables ont été créées
echo "🔍 Vérification de la création des tables..."
python -c "
import psycopg2
conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/investment_portfolio')
cur = conn.cursor()
cur.execute(\"SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';\")
tables = cur.fetchall()
print('📋 Tables créées:')
for table in tables:
    print(f'  - {table[0]}')
conn.close()
"

# Optionnel : Démarrer pgAdmin
echo "🌐 Démarrage de pgAdmin (optionnel)..."
docker-compose up -d pgadmin

echo "🎉 Configuration terminée!"
echo ""
echo "📊 Accès aux services:"
echo "  - PostgreSQL: localhost:5432"
echo "  - pgAdmin: http://localhost:8080 (admin@investment-portfolio.com / admin)"
echo "  - Redis: localhost:6379"
echo ""
echo "🔧 Commandes utiles:"
echo "  - Arrêter les services: docker-compose down"
echo "  - Voir les logs: docker-compose logs -f"
echo "  - Créer une nouvelle migration: alembic revision --autogenerate -m 'Description'"
echo "  - Appliquer les migrations: alembic upgrade head"
echo "  - Revenir en arrière: alembic downgrade -1"
echo ""
echo "🚀 Prêt pour le développement!"
