#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y postgresql

PG_VERSION=$(ls /etc/postgresql | head -n1)
PG_CONF="/etc/postgresql/${PG_VERSION}/main/postgresql.conf"
PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"

sudo sed -i "s/^#\?listen_addresses\s*=.*/listen_addresses = '*'/" "$PG_CONF"

if ! sudo grep -q "^host\s\+imdb\s\+imdb\s\+10\.10\.10\.11/32\s\+md5$" "$PG_HBA"; then
  echo "host imdb imdb 10.10.10.11/32 md5" | sudo tee -a "$PG_HBA" >/dev/null
fi

sudo systemctl restart postgresql

sudo -u postgres psql -v ON_ERROR_STOP=1 <<'SQLEOF'
DO
$$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'imdb') THEN
    CREATE ROLE imdb WITH LOGIN PASSWORD 'imdbpass';
  END IF;
END
$$;
SQLEOF

if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='imdb'" | grep -q 1; then
  sudo -u postgres createdb -O imdb imdb
fi

sudo -u postgres psql -v ON_ERROR_STOP=1 -d imdb -f /vagrant/db/schema.sql
sudo -u postgres psql -v ON_ERROR_STOP=1 -d imdb -f /vagrant/db/seed.sql
