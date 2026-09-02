#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y nginx curl

sudo mkdir -p /var/www/imdb
sudo rsync -a --delete /vagrant/frontend/ /var/www/imdb/

sudo cp /vagrant/frontend/nginx.conf /etc/nginx/sites-available/default
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx
