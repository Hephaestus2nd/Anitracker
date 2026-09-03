#!/usr/bin/env bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx curl ca-certificates
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

mkdir -p /var/www/anitracker
cp -r /vagrant/frontend/. /tmp/anitracker-frontend/
cd /tmp/anitracker-frontend
npm ci
npm run build
cp -r dist/. /var/www/anitracker/

cat <<'EOF' >/etc/nginx/sites-available/anitracker
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root /var/www/anitracker;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /api/ {
        proxy_pass http://192.168.56.11:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/anitracker /etc/nginx/sites-enabled/anitracker
nginx -t
systemctl enable --now nginx
