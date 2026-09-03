#!/usr/bin/env bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y openjdk-17-jdk gradle curl

mkdir -p /opt/anitracker
cp -r /vagrant/backend /opt/anitracker/backend
cp -r /vagrant/build.gradle /opt/anitracker/build.gradle
cp -r /vagrant/settings.gradle /opt/anitracker/settings.gradle

cd /opt/anitracker
gradle installDist

cat <<'EOF' >/etc/systemd/system/anitracker-api.service
[Unit]
Description=Anitracker API service
After=network.target

[Service]
WorkingDirectory=/opt/anitracker
ExecStart=/opt/anitracker/build/install/Anitracker/bin/Anitracker
Environment=DB_URL=jdbc:postgresql://192.168.56.10:5432/Anitracker
Environment=DB_USER=app_user
Environment=DB_PASSWORD=AppPass123
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now anitracker-api.service
