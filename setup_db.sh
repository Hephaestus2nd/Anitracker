#!/bin/bash
# setup_db.sh

# ... (Postgres installation and user setup from previous steps goes here) ...

# 1. Create the tables
sudo -u postgres psql -d movietracker -c "
CREATE TABLE my_anime (
    id SERIAL PRIMARY KEY,
    mal_id INT UNIQUE, -- ID from MyAnimeList
    title VARCHAR(255) NOT NULL,
    total_episodes INT,
    episodes_watched INT DEFAULT 0,
    watch_status VARCHAR(50) DEFAULT 'Plan to Watch',
    cover_image_url VARCHAR(500),
    synopsis TEXT
);
"

# 2. Automatically load the seed data from the shared folder
echo "Loading demonstration data..."
sudo -u postgres psql -d movietracker -f /vagrant/seed_data.sql

echo "Database provisioning complete!"