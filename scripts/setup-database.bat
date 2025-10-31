@echo off
REM Script Windows pour configurer la base de données avec Docker et Alembic

setlocal enabledelayedexpansion

echo 🚀 Configuration de la base de données Investment Portfolio...

REM Vérifier si Docker est installé
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker n'est pas installé. Veuillez installer Docker d'abord.
    exit /b 1
)

REM Vérifier si Docker Compose est installé
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker Compose n'est pas installé. Veuillez installer Docker Compose d'abord.
    exit /b 1
)

REM Créer l'environnement virtuel Python s'il n'existe pas
if not exist "venv" (
    echo 📦 Création de l'environnement virtuel Python...
    python -m venv venv
)

REM Activer l'environnement virtuel
echo 🔧 Activation de l'environnement virtuel...
call venv\Scripts\activate.bat

REM Installer les dépendances
echo 📚 Installation des dépendances Python...
python -m pip install --upgrade pip
pip install -r requirements.txt

REM Démarrer PostgreSQL avec Docker Compose
echo 🐘 Démarrage de PostgreSQL...
docker-compose up -d postgres

REM Attendre que PostgreSQL soit prêt
echo ⏳ Attente que PostgreSQL soit prêt...
:wait_postgres
docker-compose exec postgres pg_isready -U postgres -d investment_portfolio >nul 2>&1
if %errorlevel% neq 0 (
    echo PostgreSQL n'est pas encore prêt, attente...
    timeout /t 2 >nul
    goto wait_postgres
)

echo ✅ PostgreSQL est prêt!

REM Configurer les variables d'environnement pour Alembic
set DATABASE_URL=postgresql://postgres:postgres@localhost:5432/investment_portfolio

REM Créer la migration initiale avec Alembic
echo 🔄 Création de la migration initiale...
alembic revision --autogenerate -m "Initial migration"

REM Appliquer les migrations
echo 🚀 Application des migrations...
alembic upgrade head

REM Vérifier que les tables ont été créées
echo 🔍 Vérification de la création des tables...
python -c "import psycopg2; conn = psycopg2.connect('postgresql://postgres:postgres@localhost:5432/investment_portfolio'); cur = conn.cursor(); cur.execute('SELECT table_name FROM information_schema.tables WHERE table_schema = \'public\';'); tables = cur.fetchall(); print('📋 Tables créées:'); [print(f'  - {table[0]}') for table in tables]; conn.close()"

REM Optionnel : Démarrer pgAdmin
echo 🌐 Démarrage de pgAdmin (optionnel)...
docker-compose up -d pgadmin

echo 🎉 Configuration terminée!
echo.
echo 📊 Accès aux services:
echo   - PostgreSQL: localhost:5432
echo   - pgAdmin: http://localhost:8080 (admin@investment-portfolio.com / admin)
echo   - Redis: localhost:6379
echo.
echo 🔧 Commandes utiles:
echo   - Arrêter les services: docker-compose down
echo   - Voir les logs: docker-compose logs -f
echo   - Créer une nouvelle migration: alembic revision --autogenerate -m "Description"
echo   - Appliquer les migrations: alembic upgrade head
echo   - Revenir en arrière: alembic downgrade -1
echo.
echo 🚀 Prêt pour le développement!

pause
