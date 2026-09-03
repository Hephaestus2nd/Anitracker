#!/usr/bin/env bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx

mkdir -p /var/www/movie-tracker
cp -r /vagrant/frontend/. /var/www/movie-tracker/

cat <<'EOF' >/etc/nginx/sites-available/movie-tracker
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root /var/www/movie-tracker;
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
ln -sf /etc/nginx/sites-available/movie-tracker /etc/nginx/sites-enabled/movie-tracker
nginx -t
systemctl enable --now nginx
