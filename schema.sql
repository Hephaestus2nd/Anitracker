
CREATE TYPE watch_status AS ENUM (
    'Watching',
    'Completed',
    'On Hold',
    'Dropped',
    'Plan to Watch'
);

CREATE TABLE my_anime (
    id SERIAL PRIMARY KEY,
    mal_id INT UNIQUE,
    title VARCHAR(255) NOT NULL,
    total_episodes INT,
    score DECIMAL(4, 3) DEFAULT NULL,
    episodes_watched INT DEFAULT 0,
    watch_status watch_status DEFAULT 'Plan to Watch',
    cover_image_url VARCHAR(500),
    synopsis TEXT
);
---we don't need this table for now, but we can add it later if we want to add notes for each episode
-- CREATE TABLE episode_notes (
--     id SERIAL PRIMARY KEY,
--     anime_id INT REFERENCES my_anime(id) ON DELETE CASCADE,
--     episode_number INT NOT NULL,
--     notes TEXT,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );