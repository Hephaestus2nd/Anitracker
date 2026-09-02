#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk maven rsync curl

sudo mkdir -p /opt/imdb-api
sudo rsync -a --delete /vagrant/backend/ /opt/imdb-api/

cat <<'ENVEOF' | sudo tee /etc/default/imdb-api >/dev/null
DB_URL=jdbc:postgresql://10.10.10.12:5432/imdb
DB_USER=imdb
DB_PASSWORD=imdbpass
ENVEOF

cat <<'SERVICEEOF' | sudo tee /etc/systemd/system/imdb-api.service >/dev/null
[Unit]
Description=Simple IMDB API
After=network.target

[Service]
WorkingDirectory=/opt/imdb-api
EnvironmentFile=/etc/default/imdb-api
ExecStart=/usr/bin/java -jar /opt/imdb-api/target/imdb-api.jar
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICEEOF

cd /opt/imdb-api
mvn -q -DskipTests=true package

sudo systemctl daemon-reload
sudo systemctl enable imdb-api
sudo systemctl restart imdb-api

for i in {1..30}; do
  if curl -fsS http://127.0.0.1:8080/api/health >/dev/null; then
    exit 0
  fi
  sleep 1
done

echo "API failed health check" >&2
exit 1
