#!/usr/bin/env bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y postgresql postgresql-contrib curl

if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='app_user'" | grep -q 1; then
  sudo -u postgres psql -c "CREATE ROLE app_user WITH LOGIN PASSWORD 'AppPass123';"
fi

if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw Anitracker; then
  sudo -u postgres createdb -O app_user Anitracker
fi

sudo -u postgres psql -d Anitracker -c "ALTER ROLE app_user WITH LOGIN;"

PG_CONF="/etc/postgresql/$(ls /etc/postgresql | head -n 1)/main/postgresql.conf"
PG_HBA="/etc/postgresql/$(ls /etc/postgresql | head -n 1)/main/pg_hba.conf"

if ! grep -q "listen_addresses = '\*'" "$PG_CONF"; then
  echo "listen_addresses = '*'" >> "$PG_CONF"
fi

if ! grep -q "host    all             all             192.168.56.0/24        md5" "$PG_HBA"; then
  echo "host    all             all             192.168.56.0/24        md5" >> "$PG_HBA"
fi

sudo -u postgres psql -d Anitracker -f /vagrant/schema.sql
sudo -u postgres psql -d Anitracker -f /vagrant/seed_data.sql

systemctl restart postgresql

cat <<'EOF' >/etc/profile.d/anitracker-db-env.sh
export DB_HOST=192.168.56.10
export DB_NAME=Anitracker
export DB_USER=app_user
export DB_PASSWORD=AppPass123
EOF

chmod 0644 /etc/profile.d/anitracker-db-env.sh
