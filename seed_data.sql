-- Manual seed data for COSC349 Assignment 1
INSERT INTO my_anime (mal_id, title, total_episodes, episodes_watched, watch_status, cover_image_url, background_image_url, synopsis) VALUES
(52991, 'Frieren: Beyond Journey''s End', 28, 5, 'Watching', 'https://cdn.myanimelist.net/images/anime/1015/138006.jpg', NULL, 'An elf mage reflects on her past journey and the mortality of her human companions.'),
(40748, 'Jujutsu Kaisen 2nd Season', 23, 23, 'Completed', 'https://cdn.myanimelist.net/images/anime/1412/127999.jpg', NULL, 'The hidden past of Gojo and Geto comes to light, followed by the harrowing Shibuya Incident.'),
(11061, 'Hunter x Hunter (2011)', 148, 40, 'Watching', 'https://cdn.myanimelist.net/images/anime/1337/99013.jpg', NULL, 'Gon Freecss aspires to become a Hunter in order to find his missing father.'),
(52193, 'Akiba Maid War', 12, 0, 'Plan to Watch', 'https://cdn.myanimelist.net/images/anime/1448/126252.jpg', NULL, 'In 1999 Akihabara, a new maid joins a struggling maid cafe and discovers that the maid world is far more violent than it appears.'),
(59260, 'Uma Musume: Cinderella Gray', 13, 0, 'Plan to Watch', 'https://cdn.myanimelist.net/images/anime/1175/147255.jpg', NULL, 'A local Uma Musume from Kasamatsu races toward the national stage and strives to become the fastest legend in Japan.');









/* 

To prevent external API rate-limits and 504 Gateway timeouts during automated builds, anime metadata was structured into a static SQL seed file, ensuring robust offline-capable deployment
Since Jikan happens to be down a lot of the time we don't use it and just have a seed instead.
*/
