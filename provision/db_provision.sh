#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y postgresql postgresql-contrib curl

DB_NAME="anitracker"

if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='app_user'" | grep -q 1; then
  sudo -u postgres psql -c "CREATE ROLE app_user WITH LOGIN PASSWORD 'AppPass123';"
fi

if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
  sudo -u postgres createdb -O app_user "$DB_NAME"
fi

sudo -u postgres psql -d "$DB_NAME" -c "ALTER ROLE app_user WITH LOGIN;"

PG_CONF="/etc/postgresql/$(ls /etc/postgresql | head -n 1)/main/postgresql.conf"
PG_HBA="/etc/postgresql/$(ls /etc/postgresql | head -n 1)/main/pg_hba.conf"

if ! grep -q "listen_addresses = '\*'" "$PG_CONF"; then
  echo "listen_addresses = '*'" >> "$PG_CONF"
fi

if ! grep -q "host    all             all             192.168.56.0/24        md5" "$PG_HBA"; then
  echo "host    all             all             192.168.56.0/24        md5" >> "$PG_HBA"
fi

systemctl restart postgresql

for attempt in $(seq 1 30); do
  if pg_isready -h 127.0.0.1 -p 5432 -d "$DB_NAME"; then
    break
  fi
  if [ "$attempt" -eq 30 ]; then
    echo "PostgreSQL did not become ready" >&2
    exit 1
  fi
  sleep 1
done
sudo -u postgres psql -v ON_ERROR_STOP=1 -d "$DB_NAME" -f /vagrant/schema.sql
sudo -u postgres psql -v ON_ERROR_STOP=1 -d "$DB_NAME" -f /vagrant/seed_data.sql

sudo -u postgres psql -v ON_ERROR_STOP=1 -d "$DB_NAME" <<'SQL'
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO app_user;
SQL




cat <<'EOF' >/etc/profile.d/anitracker-db-env.sh
export DB_HOST=192.168.56.10
export DB_NAME=anitracker
export DB_USER=app_user
export DB_PASSWORD=AppPass123
EOF

chmod 0644 /etc/profile.d/anitracker-db-env.sh
