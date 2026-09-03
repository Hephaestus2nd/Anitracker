
CREATE TYPE if not exists watch_status AS ENUM (
    'Watching',
    'Completed',
    'On Hold',
    'Dropped',
    'Plan to Watch'
);

CREATE TABLE if not exists my_anime (
    
    mal_id INT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    total_episodes INT,
    score DECIMAL(4, 3) DEFAULT NULL,
    episodes_watched INT DEFAULT 0,
    watch_status watch_status DEFAULT 'Plan to Watch',
    cover_image_url VARCHAR(500),
    background_image_url VARCHAR(500),
    synopsis TEXT
);
--we don't need this table for now, but we can add it later if we want to add notes for each episode
--if it isn't commented that then that means that we COULD use it.
CREATE TABLE if not exists episode_notes (
    id SERIAL PRIMARY KEY,
    mal_id INT REFERENCES my_anime(mal_id) ON DELETE CASCADE,
    episode_number INT NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);