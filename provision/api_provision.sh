#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y openjdk-17-jdk gradle curl postgresql-client

DB_HOST="192.168.56.10"
DB_NAME="anitracker"

mkdir -p /opt/anitracker
cp -r /vagrant/backend /opt/anitracker/backend
cp -r /vagrant/build.gradle /opt/anitracker/build.gradle
cp -r /vagrant/settings.gradle /opt/anitracker/settings.gradle

cd /opt/anitracker
gradle installDist

cat <<'EOF' >/etc/systemd/system/anitracker-api.service
[Unit]
Description=Anitracker API service
Wants=network-online.target
After=network-online.target

[Service]
WorkingDirectory=/opt/anitracker
ExecStart=/opt/anitracker/build/install/anitracker/bin/anitracker
ExecStartPre=/bin/sh -c 'for attempt in $(seq 1 60); do pg_isready -h 192.168.56.10 -p 5432 -d anitracker && exit 0; sleep 1; done; exit 1'
Environment=DB_URL=jdbc:postgresql://192.168.56.10:5432/anitracker
Environment=DB_USER=app_user
Environment=DB_PASSWORD=AppPass123
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable anitracker-api.service
systemctl restart anitracker-api.service

for attempt in $(seq 1 30); do
	if curl -fsS http://127.0.0.1:8080/health >/dev/null; then
		break
	fi
	if [ "$attempt" -eq 30 ]; then
		echo "Anitracker API did not become ready" >&2
		exit 1
	fi
	sleep 1
done
