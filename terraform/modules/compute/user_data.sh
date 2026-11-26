#!/bin/bash
# ==============================================================================
# User Data Script - Moodle EC2 Instance Setup
# ==============================================================================
# Este script é executado na primeira inicialização da instância EC2
# Instala Docker, Docker Compose e inicializa o Moodle
# ==============================================================================

set -Eeuo pipefail

exec > >(tee /var/log/user-data.log) 2>&1

MOODLE_DIR="/opt/moodle"
DB_HOST="${db_host}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"

log() {
  echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*"
}

log "Moodle EC2 setup started"

dnf update -y
dnf install -y docker curl

systemctl enable --now docker
usermod -aG docker ec2-user

mkdir -p /usr/local/lib/docker/cli-plugins
curl -fL \
  "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod 0755 /usr/local/lib/docker/cli-plugins/docker-compose
ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

docker --version
docker compose version

mkdir -p "${MOODLE_DIR}"

cat > "${MOODLE_DIR}/docker-compose.yml" <<EOF
services:
  moodle:
    image: bitnami/moodle:4
    container_name: moodle
    restart: unless-stopped
    ports:
      - "80:8080"
    environment:
      MOODLE_DATABASE_TYPE: pgsql
      MOODLE_DATABASE_HOST: "${DB_HOST}"
      MOODLE_DATABASE_PORT_NUMBER: "5432"
      MOODLE_DATABASE_NAME: "${DB_NAME}"
      MOODLE_DATABASE_USER: "${DB_USER}"
      MOODLE_DATABASE_PASSWORD: "${DB_PASSWORD}"
      MOODLE_SITE_NAME: "Moodle DevOps"
      MOODLE_USERNAME: admin
      MOODLE_PASSWORD: "Admin123!"
      MOODLE_EMAIL: admin@example.com
      MOODLE_SKIP_BOOTSTRAP: "no"
    volumes:
      - moodle_data:/bitnami/moodle
      - moodledata:/bitnami/moodledata
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8080 || exit 1"]
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

chmod 0644 "${MOODLE_DIR}/docker-compose.yml"

log "Waiting for RDS PostgreSQL"
DB_READY=false
for attempt in $(seq 1 30); do
  if docker run --rm postgres:15 pg_isready -h "${DB_HOST}" -p 5432 -U "${DB_USER}" -d "${DB_NAME}" >/dev/null 2>&1; then
    DB_READY=true
    log "RDS PostgreSQL is ready"
    break
  fi
  log "Database attempt ${attempt}/30 failed; retrying in 10 seconds"
  sleep 10
done

if [ "${DB_READY}" != "true" ]; then
  log "RDS did not become ready within 5 minutes"
  exit 1
fi

cd "${MOODLE_DIR}"
docker compose pull
docker compose up -d

cat > /etc/systemd/system/moodle.service <<EOF
[Unit]
Description=Moodle Docker Compose Service
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${MOODLE_DIR}
ExecStart=/usr/local/lib/docker/cli-plugins/docker-compose up -d
ExecStop=/usr/local/lib/docker/cli-plugins/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable moodle.service

PUBLIC_DNS=$(curl -fsS --retry 3 \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60" \
  http://169.254.169.254/latest/meta-data/public-hostname 2>/dev/null || true)

log "Moodle setup completed"
log "Application URL: http://${PUBLIC_DNS:-localhost}"
log "Default Moodle administrator: admin"
log "Initial password: change it after the first login"
