-- Manual seed data for COSC349 Assignment 1
INSERT INTO my_anime (mal_id, title, total_episodes, episodes_watched, watch_status, cover_image_url, synopsis) VALUES 
(52991, 'Frieren: Beyond Journey''s End', 28, 5, 'Watching', 'https://cdn.myanimelist.net/images/anime/1015/138006.jpg', 'An elf mage reflects on her past journey and the mortality of her human companions.'),
(40748, 'Jujutsu Kaisen 2nd Season', 23, 23, 'Completed', 'https://cdn.myanimelist.net/images/anime/1412/127999.jpg', 'The hidden past of Gojo and Geto comes to light, followed by the harrowing Shibuya Incident.'),
(11061, 'Hunter x Hunter (2011)', 148, 40, 'Watching', 'https://cdn.myanimelist.net/images/anime/1337/99013.jpg', 'Gon Freecss aspires to become a Hunter in order to find his missing father.');

/* 

To prevent external API rate-limits and 504 Gateway timeouts during automated builds, anime metadata was structured into a static SQL seed file, ensuring robust offline-capable deployment
Since Jikan happens to be down a lot of the time we don't use it and just have a seed instead.
*/
