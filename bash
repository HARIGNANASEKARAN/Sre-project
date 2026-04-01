#!/bin/bash
# ================================================
# SRE Project Setup Script
# Sets up Python app + Prometheus + Grafana + Alertmanager
# ================================================

# Exit on any error
set -e

# -----------------------------
# 1️⃣ Create project folder
# -----------------------------
echo "Creating project folder..."
mkdir -p sre-project/app
mkdir -p sre-project/prometheus
mkdir -p sre-project/alertmanager
cd sre-project

# -----------------------------
# 2️⃣ Create Python app
# -----------------------------
echo "Creating Python app..."
cat > app/app.py << 'EOF'
from flask import Flask
from prometheus_client import start_http_server, Counter

app = Flask(__name__)

REQUEST_COUNT = Counter('app_requests_total', 'Total App Requests')

@app.route("/")
def home():
    REQUEST_COUNT.inc()
    return "Hello, SRE World!"

@app.route("/error")
def error():
    REQUEST_COUNT.inc()
    return "Error!", 500

if __name__ == "__main__":
    start_http_server(8000)  # Prometheus metrics
    app.run(host="0.0.0.0", port=5000)
EOF

cat > app/requirements.txt << 'EOF'
flask
prometheus_client
EOF

cat > app/Dockerfile << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "app.py"]
EOF

# -----------------------------
# 3️⃣ Create Prometheus configs
# -----------------------------
echo "Creating Prometheus config..."
cat > prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 5s

rule_files:
  - "alert.rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

scrape_configs:
  - job_name: 'sre-app'
    static_configs:
      - targets: ['host.docker.internal:8000']  # Windows/Mac
      # For Linux, use 'localhost:8000'
EOF

cat > prometheus/alert.rules.yml << 'EOF'
groups:
  - name: sre-alerts
    rules:
      - alert: HighErrorRate
        expr: increase(app_requests_total[1m]) > 5
        for: 10s
        labels:
          severity: critical
        annotations:
          summary: "High request rate detected"
          description: "Too many requests in short time"
EOF

# -----------------------------
# 4️⃣ Create Alertmanager config
# -----------------------------
echo "Creating Alertmanager config..."
cat > alertmanager/alertmanager.yml << 'EOF'
global:
  resolve_timeout: 5m

route:
  receiver: "console"

receivers:
  - name: "console"
    webhook_configs:
      - url: "http://localhost:9093"
EOF

# -----------------------------
# 5️⃣ Create docker-compose.yml
# -----------------------------
echo "Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3'
services:
  sre-app:
    build: ./app
    container_name: sre-app
    ports:
      - "5000:5000"
      - "8000:8000"

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus:/etc/prometheus
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
    ports:
      - "9093:9093"
EOF

# -----------------------------
# 6️⃣ Create README.md
# -----------------------------
echo "Creating README.md..."
cat > README.md << 'EOF'
# SRE Project

**Description:**  
Python web app with Prometheus monitoring, Grafana dashboard, and Alertmanager alerting. Demonstrates SRE concepts like metrics, alerts, and SLOs.

## How to Run

```bash
docker compose up -d

URLs
Web App: http://localhost:5000
Metrics: http://localhost:8000
Prometheus: http://localhost:9090
Grafana: http://localhost:3000
Alertmanager: http://localhost:9093
Features
Web app endpoints: / and /error
Prometheus metrics scraping
Grafana dashboards
Alertmanager firing alerts
SLO visualization

Build and start Docker containers
-----------------------------

echo "Building and starting Docker containers..."
docker compose build
docker compose up -d

echo "🎉 SRE Project setup complete!"
echo "Visit the URLs to check your app, metrics, dashboards, and alerts."


---

### ✅ How to Use

1. Save the above as `setup_sre_project.sh`  
2. Make it executable:
```bash
chmod +x setup_sre_project.sh

./setup_sre_project.sh

Open your browsers for:
App → http://localhost:5000
Prometheus → http://localhost:9090
Grafana → http://localhost:3000
Alertmanager → http://localhost:9093