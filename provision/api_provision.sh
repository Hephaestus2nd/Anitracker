#!/usr/bin/env bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y openjdk-17-jdk gradle curl

mkdir -p /opt/movie-tracker
cp -r /vagrant/backend /opt/movie-tracker/backend
cp -r /vagrant/build.gradle /opt/movie-tracker/build.gradle
cp -r /vagrant/settings.gradle /opt/movie-tracker/settings.gradle

cd /opt/movie-tracker
gradle installDist

cat <<'EOF' >/etc/systemd/system/movie-tracker-api.service
[Unit]
Description=Movie tracker API service
After=network.target

[Service]
WorkingDirectory=/opt/movie-tracker
ExecStart=/opt/movie-tracker/build/install/movie-tracker/bin/movie-tracker
Environment=DB_URL=jdbc:postgresql://192.168.56.10:5432/movietracker
Environment=DB_USER=app_user
Environment=DB_PASSWORD=AppPass123
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now movie-tracker-api.service
