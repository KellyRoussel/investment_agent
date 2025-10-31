# Guide de Déploiement - Investment Portfolio API

## Vue d'ensemble

Ce guide couvre le déploiement de l'Investment Portfolio API en environnement de développement, staging et production. L'application est conçue pour être déployée dans des conteneurs Docker avec orchestration Kubernetes ou Docker Compose.

## Prérequis

### Environnement de développement
- Python 3.9+
- Docker & Docker Compose
- Git
- IDE (VS Code, PyCharm, etc.)

### Environnement de production
- Kubernetes cluster (ou Docker Swarm)
- PostgreSQL 13+
- Redis 6+
- Nginx (reverse proxy)
- Certificats SSL/TLS
- Monitoring (Prometheus/Grafana)

## Structure de déploiement

```
deployment/
├── docker/
│   ├── Dockerfile
│   ├── Dockerfile.prod
│   └── docker-compose.yml
├── kubernetes/
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secrets.yaml
│   ├── postgresql.yaml
│   ├── redis.yaml
│   ├── app.yaml
│   ├── nginx.yaml
│   └── ingress.yaml
├── scripts/
│   ├── build.sh
│   ├── deploy.sh
│   └── migrate.sh
└── monitoring/
    ├── prometheus.yaml
    ├── grafana.yaml
    └── alertmanager.yaml
```

## Configuration des environnements

### Variables d'environnement

#### Développement (.env.development)
```bash
# Application
DEBUG=True
LOG_LEVEL=DEBUG
API_V1_STR=/api/v1
SECRET_KEY=dev-secret-key-change-in-production

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/investment_dev
DATABASE_POOL_SIZE=5
DATABASE_MAX_OVERFLOW=10

# Redis
REDIS_URL=redis://localhost:6379/0
REDIS_PASSWORD=

# External APIs
YAHOO_FINANCE_API_KEY=your_yahoo_api_key
OPENAI_API_KEY=your_openai_api_key
NEWS_API_KEY=your_news_api_key

# Celery
CELERY_BROKER_URL=redis://localhost:6379/1
CELERY_RESULT_BACKEND=redis://localhost:6379/2

# Email (development)
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_TLS=False

# Rate Limiting
RATE_LIMIT_PER_MINUTE=100
RATE_LIMIT_PER_HOUR=1000

# CORS
ALLOWED_ORIGINS=["http://localhost:3000", "http://localhost:8080"]
```

#### Production (.env.production)
```bash
# Application
DEBUG=False
LOG_LEVEL=INFO
API_V1_STR=/api/v1
SECRET_KEY=${SECRET_KEY}

# Database
DATABASE_URL=${DATABASE_URL}
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=30

# Redis
REDIS_URL=${REDIS_URL}
REDIS_PASSWORD=${REDIS_PASSWORD}

# External APIs
YAHOO_FINANCE_API_KEY=${YAHOO_FINANCE_API_KEY}
OPENAI_API_KEY=${OPENAI_API_KEY}
NEWS_API_KEY=${NEWS_API_KEY}

# Celery
CELERY_BROKER_URL=${REDIS_URL}/1
CELERY_RESULT_BACKEND=${REDIS_URL}/2

# Email
SMTP_HOST=${SMTP_HOST}
SMTP_PORT=${SMTP_PORT}
SMTP_USERNAME=${SMTP_USERNAME}
SMTP_PASSWORD=${SMTP_PASSWORD}
SMTP_TLS=True

# Rate Limiting
RATE_LIMIT_PER_MINUTE=60
RATE_LIMIT_PER_HOUR=1000

# CORS
ALLOWED_ORIGINS=${ALLOWED_ORIGINS}

# Monitoring
PROMETHEUS_ENDPOINT=/metrics
HEALTH_CHECK_ENDPOINT=/health
```

## Déploiement avec Docker

### 1. Dockerfile de développement

```dockerfile
FROM python:3.9-slim

# Variables d'environnement
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Dépendances système
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Répertoire de travail
WORKDIR /app

# Dépendances Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Code source
COPY . .

# Port d'exposition
EXPOSE 8000

# Commande par défaut
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

### 2. Dockerfile de production

```dockerfile
FROM python:3.9-slim as builder

# Variables d'environnement
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Dépendances système pour la compilation
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Répertoire de travail
WORKDIR /app

# Dépendances Python
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Image de production
FROM python:3.9-slim

# Utilisateur non-root
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Dépendances système runtime
RUN apt-get update && apt-get install -y \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copier les dépendances Python depuis l'image builder
COPY --from=builder /root/.local /home/appuser/.local

# Répertoire de travail
WORKDIR /app

# Copier le code source
COPY --chown=appuser:appuser . .

# Changer vers l'utilisateur non-root
USER appuser

# Ajouter le répertoire local au PATH
ENV PATH=/home/appuser/.local/bin:$PATH

# Port d'exposition
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Commande par défaut
CMD ["gunicorn", "app.main:app", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]
```

### 3. Docker Compose pour développement

```yaml
version: '3.8'

services:
  # Base de données PostgreSQL
  postgres:
    image: postgres:13
    environment:
      POSTGRES_DB: investment_dev
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Cache Redis
  redis:
    image: redis:6-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Application FastAPI
  app:
    build:
      context: .
      dockerfile: docker/Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/investment_dev
      - REDIS_URL=redis://redis:6379/0
      - CELERY_BROKER_URL=redis://redis:6379/1
    volumes:
      - .:/app
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

  # Worker Celery
  celery-worker:
    build:
      context: .
      dockerfile: docker/Dockerfile
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/investment_dev
      - REDIS_URL=redis://redis:6379/0
      - CELERY_BROKER_URL=redis://redis:6379/1
    volumes:
      - .:/app
    depends_on:
      - postgres
      - redis
    command: ["celery", "-A", "app.core.celery", "worker", "--loglevel=info"]

  # Beat Celery (scheduler)
  celery-beat:
    build:
      context: .
      dockerfile: docker/Dockerfile
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/investment_dev
      - REDIS_URL=redis://redis:6379/0
      - CELERY_BROKER_URL=redis://redis:6379/1
    volumes:
      - .:/app
    depends_on:
      - postgres
      - redis
    command: ["celery", "-A", "app.core.celery", "beat", "--loglevel=info"]

  # Monitoring Prometheus
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yaml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'

  # Monitoring Grafana
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning

volumes:
  postgres_data:
  redis_data:
  prometheus_data:
  grafana_data:
```

## Déploiement Kubernetes

### 1. Namespace

```yaml
# kubernetes/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: investment-portfolio
  labels:
    name: investment-portfolio
```

### 2. ConfigMap

```yaml
# kubernetes/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: investment-portfolio-config
  namespace: investment-portfolio
data:
  DEBUG: "False"
  LOG_LEVEL: "INFO"
  API_V1_STR: "/api/v1"
  DATABASE_POOL_SIZE: "20"
  DATABASE_MAX_OVERFLOW: "30"
  RATE_LIMIT_PER_MINUTE: "60"
  RATE_LIMIT_PER_HOUR: "1000"
  PROMETHEUS_ENDPOINT: "/metrics"
  HEALTH_CHECK_ENDPOINT: "/health"
```

### 3. Secrets

```yaml
# kubernetes/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: investment-portfolio-secrets
  namespace: investment-portfolio
type: Opaque
data:
  SECRET_KEY: <base64-encoded-secret-key>
  DATABASE_URL: <base64-encoded-database-url>
  REDIS_URL: <base64-encoded-redis-url>
  YAHOO_FINANCE_API_KEY: <base64-encoded-api-key>
  OPENAI_API_KEY: <base64-encoded-api-key>
  NEWS_API_KEY: <base64-encoded-api-key>
  SMTP_HOST: <base64-encoded-smtp-host>
  SMTP_USERNAME: <base64-encoded-smtp-username>
  SMTP_PASSWORD: <base64-encoded-smtp-password>
```

### 4. PostgreSQL

```yaml
# kubernetes/postgresql.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: investment-portfolio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: investment_prod
        - name: POSTGRES_USER
          value: postgres
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secrets
              key: password
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: investment-portfolio
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: investment-portfolio
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
```

### 5. Redis

```yaml
# kubernetes/redis.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: investment-portfolio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:6-alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "250m"

---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: investment-portfolio
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
```

### 6. Application

```yaml
# kubernetes/app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: investment-portfolio-api
  namespace: investment-portfolio
spec:
  replicas: 3
  selector:
    matchLabels:
      app: investment-portfolio-api
  template:
    metadata:
      labels:
        app: investment-portfolio-api
    spec:
      containers:
      - name: api
        image: investment-portfolio:latest
        ports:
        - containerPort: 8000
        envFrom:
        - configMapRef:
            name: investment-portfolio-config
        - secretRef:
            name: investment-portfolio-secrets
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: investment-portfolio-api-service
  namespace: investment-portfolio
spec:
  selector:
    app: investment-portfolio-api
  ports:
  - port: 8000
    targetPort: 8000
  type: ClusterIP
```

### 7. Celery Workers

```yaml
# kubernetes/celery-worker.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: celery-worker
  namespace: investment-portfolio
spec:
  replicas: 2
  selector:
    matchLabels:
      app: celery-worker
  template:
    metadata:
      labels:
        app: celery-worker
    spec:
      containers:
      - name: worker
        image: investment-portfolio:latest
        command: ["celery", "-A", "app.core.celery", "worker", "--loglevel=info"]
        envFrom:
        - configMapRef:
            name: investment-portfolio-config
        - secretRef:
            name: investment-portfolio-secrets
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "250m"

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: celery-beat
  namespace: investment-portfolio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: celery-beat
  template:
    metadata:
      labels:
        app: celery-beat
    spec:
      containers:
      - name: beat
        image: investment-portfolio:latest
        command: ["celery", "-A", "app.core.celery", "beat", "--loglevel=info"]
        envFrom:
        - configMapRef:
            name: investment-portfolio-config
        - secretRef:
            name: investment-portfolio-secrets
        resources:
          requests:
            memory: "128Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "100m"
```

### 8. Nginx Ingress

```yaml
# kubernetes/nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: investment-portfolio
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        - containerPort: 443
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
        - name: ssl-certs
          mountPath: /etc/ssl/certs
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config
      - name: ssl-certs
        secret:
          secretName: ssl-certificates

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: investment-portfolio
spec:
  selector:
    app: nginx
  ports:
  - name: http
    port: 80
    targetPort: 80
  - name: https
    port: 443
    targetPort: 443
  type: LoadBalancer

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: investment-portfolio
data:
  default.conf: |
    upstream api_backend {
        server investment-portfolio-api-service:8000;
    }
    
    server {
        listen 80;
        server_name api.investment-portfolio.com;
        
        # Redirect HTTP to HTTPS
        return 301 https://$server_name$request_uri;
    }
    
    server {
        listen 443 ssl http2;
        server_name api.investment-portfolio.com;
        
        ssl_certificate /etc/ssl/certs/tls.crt;
        ssl_certificate_key /etc/ssl/certs/tls.key;
        
        # SSL configuration
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        
        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        
        # Rate limiting
        limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
        limit_req zone=api burst=20 nodelay;
        
        location / {
            proxy_pass http://api_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Timeouts
            proxy_connect_timeout 30s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;
        }
        
        location /health {
            proxy_pass http://api_backend/health;
            access_log off;
        }
    }
```

## Scripts de déploiement

### 1. Script de build

```bash
#!/bin/bash
# scripts/build.sh

set -e

# Variables
IMAGE_NAME="investment-portfolio"
TAG=${1:-latest}
REGISTRY=${2:-"your-registry.com"}

echo "Building Docker image..."

# Build the image
docker build -f docker/Dockerfile.prod -t ${REGISTRY}/${IMAGE_NAME}:${TAG} .

# Push to registry
echo "Pushing to registry..."
docker push ${REGISTRY}/${IMAGE_NAME}:${TAG}

echo "Image built and pushed: ${REGISTRY}/${IMAGE_NAME}:${TAG}"
```

### 2. Script de déploiement

```bash
#!/bin/bash
# scripts/deploy.sh

set -e

# Variables
NAMESPACE="investment-portfolio"
IMAGE_TAG=${1:-latest}
REGISTRY=${2:-"your-registry.com"}

echo "Deploying to Kubernetes..."

# Apply Kubernetes manifests
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/postgresql.yaml
kubectl apply -f kubernetes/redis.yaml

# Wait for databases to be ready
echo "Waiting for databases to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n ${NAMESPACE}
kubectl wait --for=condition=available --timeout=300s deployment/redis -n ${NAMESPACE}

# Run database migrations
echo "Running database migrations..."
kubectl run migration-job --image=${REGISTRY}/investment-portfolio:${IMAGE_TAG} \
    --restart=Never \
    --rm -i \
    --namespace=${NAMESPACE} \
    --command -- alembic upgrade head

# Deploy application
kubectl apply -f kubernetes/app.yaml
kubectl apply -f kubernetes/celery-worker.yaml
kubectl apply -f kubernetes/celery-beat.yaml
kubectl apply -f kubernetes/nginx.yaml

# Wait for deployment to complete
echo "Waiting for deployment to complete..."
kubectl wait --for=condition=available --timeout=300s deployment/investment-portfolio-api -n ${NAMESPACE}

echo "Deployment completed successfully!"
```

### 3. Script de migration

```bash
#!/bin/bash
# scripts/migrate.sh

set -e

# Variables
NAMESPACE="investment-portfolio"
IMAGE_TAG=${1:-latest}
REGISTRY=${2:-"your-registry.com"}

echo "Running database migrations..."

# Create migration job
kubectl run migration-job --image=${REGISTRY}/investment-portfolio:${IMAGE_TAG} \
    --restart=Never \
    --rm -i \
    --namespace=${NAMESPACE} \
    --command -- alembic upgrade head

echo "Migrations completed successfully!"
```

## Monitoring et observabilité

### 1. Prometheus Configuration

```yaml
# monitoring/prometheus.yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'investment-portfolio-api'
    static_configs:
      - targets: ['investment-portfolio-api-service:8000']
    metrics_path: '/metrics'
    scrape_interval: 10s

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']

  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx-exporter:9113']
```

### 2. Alert Rules

```yaml
# monitoring/alert_rules.yml
groups:
- name: investment-portfolio
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High error rate detected"
      description: "Error rate is {{ $value }} requests per second"

  - alert: HighResponseTime
    expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High response time"
      description: "95th percentile response time is {{ $value }} seconds"

  - alert: DatabaseConnectionFailure
    expr: up{job="postgres"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Database connection failed"
      description: "PostgreSQL database is down"

  - alert: RedisConnectionFailure
    expr: up{job="redis"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Redis connection failed"
      description: "Redis cache is down"
```

## Sécurité

### 1. Network Policies

```yaml
# kubernetes/network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: investment-portfolio-network-policy
  namespace: investment-portfolio
spec:
  podSelector:
    matchLabels:
      app: investment-portfolio-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: nginx
    ports:
    - protocol: TCP
      port: 8000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - podSelector:
        matchLabels:
          app: redis
    ports:
    - protocol: TCP
      port: 6379
  - to: [] # Allow external API calls
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
```

### 2. Pod Security Policy

```yaml
# kubernetes/pod-security-policy.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: investment-portfolio-psp
  namespace: investment-portfolio
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
```

## Backup et récupération

### 1. Script de backup PostgreSQL

```bash
#!/bin/bash
# scripts/backup.sh

set -e

# Variables
NAMESPACE="investment-portfolio"
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="investment_portfolio_${DATE}.sql"

echo "Starting backup..."

# Create backup
kubectl exec -n ${NAMESPACE} deployment/postgres -- \
    pg_dump -U postgres investment_prod > ${BACKUP_DIR}/${BACKUP_FILE}

# Compress backup
gzip ${BACKUP_DIR}/${BACKUP_FILE}

echo "Backup completed: ${BACKUP_DIR}/${BACKUP_FILE}.gz"
```

### 2. Script de restauration

```bash
#!/bin/bash
# scripts/restore.sh

set -e

# Variables
NAMESPACE="investment-portfolio"
BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup_file>"
    exit 1
fi

echo "Starting restore from ${BACKUP_FILE}..."

# Restore backup
gunzip -c ${BACKUP_FILE} | kubectl exec -i -n ${NAMESPACE} deployment/postgres -- \
    psql -U postgres investment_prod

echo "Restore completed successfully!"
```

## Tests de déploiement

### 1. Tests de santé

```bash
#!/bin/bash
# scripts/health-check.sh

set -e

# Variables
API_URL=${1:-"http://localhost:8000"}

echo "Running health checks..."

# Check API health
echo "Checking API health..."
curl -f ${API_URL}/health

# Check database connectivity
echo "Checking database connectivity..."
curl -f ${API_URL}/health/db

# Check Redis connectivity
echo "Checking Redis connectivity..."
curl -f ${API_URL}/health/redis

# Check external APIs
echo "Checking external APIs..."
curl -f ${API_URL}/health/external

echo "All health checks passed!"
```

### 2. Tests de charge

```bash
#!/bin/bash
# scripts/load-test.sh

set -e

# Variables
API_URL=${1:-"http://localhost:8000"}
USERS=${2:-100}
DURATION=${3:-60s}

echo "Running load tests..."

# Install k6 if not present
if ! command -v k6 &> /dev/null; then
    echo "Installing k6..."
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
    echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
    sudo apt-get update
    sudo apt-get install k6
fi

# Create load test script
cat > load-test.js << EOF
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  vus: ${USERS},
  duration: '${DURATION}',
};

export default function() {
  let response = http.get('${API_URL}/health');
  check(response, {
    'status is 200': (r) => r.status === 200,
  });
  sleep(1);
}
EOF

# Run load test
k6 run load-test.js

echo "Load test completed!"
```

Ce guide de déploiement couvre tous les aspects nécessaires pour déployer l'Investment Portfolio API en production de manière sécurisée et scalable.
