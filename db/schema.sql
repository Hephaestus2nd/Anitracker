CREATE TABLE IF NOT EXISTS movies (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  genre TEXT NOT NULL,
  release_year INT NOT NULL,
  rating NUMERIC(2,1) NOT NULL,
  director TEXT NOT NULL,
  synopsis TEXT NOT NULL
);
