#!/bin/bash
# ==============================================================================
# User Data Script - Moodle EC2 Instance Setup
# ==============================================================================
# Este script é executado na primeira inicialização da instância EC2
# Instala Docker, Docker Compose e inicializa o Moodle
# ==============================================================================

set -e  # Exit on error

# ------------------------------------------------------------------------------
# Logging
# ------------------------------------------------------------------------------

exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "========================================="
echo "Moodle EC2 Setup - Starting"
echo "========================================="
date

# ------------------------------------------------------------------------------
# System Update
# ------------------------------------------------------------------------------

echo "[1/6] Updating system packages..."
dnf update -y

# ------------------------------------------------------------------------------
# Install Docker
# ------------------------------------------------------------------------------

echo "[2/6] Installing Docker..."
dnf install -y docker
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Verify Docker installation
docker --version

# ------------------------------------------------------------------------------
# Install Docker Compose v2
# ------------------------------------------------------------------------------

echo "[3/6] Installing Docker Compose v2..."

# Get latest version
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')

# Download and install
curl -SL "https://github.com/docker/compose/releases/download/$${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" \
  -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

# Create symlink for 'docker compose' command
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installation
docker-compose --version

# ------------------------------------------------------------------------------
# Setup Moodle Directory
# ------------------------------------------------------------------------------

echo "[4/6] Setting up Moodle directory structure..."

MOODLE_DIR="/opt/moodle"
mkdir -p $MOODLE_DIR

# Create docker-compose.yml
cat > $MOODLE_DIR/docker-compose.yml <<'EOF'
version: '3.8'

services:
  moodle:
    image: bitnami/moodle:4
    container_name: moodle
    restart: unless-stopped
    ports:
      - "80:8080"
    environment:
      - MOODLE_DATABASE_TYPE=pgsql
      - MOODLE_DATABASE_HOST=${db_host%%:*}
      - MOODLE_DATABASE_PORT_NUMBER=5432
      - MOODLE_DATABASE_NAME=${db_name}
      - MOODLE_DATABASE_USER=${db_user}
      - MOODLE_DATABASE_PASSWORD=${db_password}
      - MOODLE_SITE_NAME=Moodle DevOps
      - MOODLE_USERNAME=admin
      - MOODLE_PASSWORD=Admin123!
      - MOODLE_EMAIL=admin@example.com
      - BITNAMI_DEBUG=true
      - MOODLE_SKIP_BOOTSTRAP=no
    volumes:
      - moodle_data:/bitnami/moodle
      - moodledata:/bitnami/moodledata
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s

volumes:
  moodle_data:
    driver: local
  moodledata:
    driver: local
EOF

# Set ownership
chown -R ec2-user:ec2-user $MOODLE_DIR

# ------------------------------------------------------------------------------
# Start Moodle
# ------------------------------------------------------------------------------

echo "[5/6] Starting Moodle containers..."
cd $MOODLE_DIR

# Wait for RDS to be available
echo "Waiting for database to be ready..."

# Extract hostname from endpoint (remove :port if present)
DB_HOST="${db_host%%:*}"

for i in {1..30}; do
  if docker run --rm postgres:15 pg_isready -h "$DB_HOST" -U ${db_user} > /dev/null 2>&1; then
    echo "Database is ready!"
    break
  fi
  echo "Attempt $i/30: Database not ready yet, waiting..."
  sleep 10
done

# Start containers
docker-compose up -d

# ------------------------------------------------------------------------------
# Setup Systemd Service
# ------------------------------------------------------------------------------

echo "[6/6] Creating systemd service for Moodle..."

cat > /etc/systemd/system/moodle.service <<EOF
[Unit]
Description=Moodle Docker Compose Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$MOODLE_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable moodle.service

# ------------------------------------------------------------------------------
# Completion
# ------------------------------------------------------------------------------

echo "========================================="
echo "Moodle EC2 Setup - Completed Successfully"
echo "========================================="
echo "Moodle will be available in ~5 minutes at:"
echo "http://$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)"
echo ""
echo "Default credentials:"
echo "Username: admin"
echo "Password: Admin123!"
echo "========================================="
date
