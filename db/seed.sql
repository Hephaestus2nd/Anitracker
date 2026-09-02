INSERT INTO movies (title, genre, release_year, rating, director, synopsis)
VALUES
  ('The Matrix', 'Sci-Fi', 1999, 8.7, 'The Wachowskis', 'A hacker discovers reality is a simulation and joins a rebellion.'),
  ('Spirited Away', 'Fantasy', 2001, 8.6, 'Hayao Miyazaki', 'A young girl enters a spirit world and must find her way home.'),
  ('Arrival', 'Sci-Fi', 2016, 7.9, 'Denis Villeneuve', 'A linguist works to communicate with visitors from another world.'),
  ('The Grand Budapest Hotel', 'Comedy', 2014, 8.1, 'Wes Anderson', 'A concierge and lobby boy are caught in a caper at a famous hotel.')
ON CONFLICT DO NOTHING;
