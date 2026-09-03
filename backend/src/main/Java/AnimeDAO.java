package main.java;

import java.util.List;

public interface AnimeDAO {

    List<Anime> getAllAnime();

    Anime getAnimeById(int id);

    Anime getAnimeByTitle(String title);

    void insertAnime(Anime anime);

    void updateAnime(Anime anime);

    void deleteAnime(int id);
}
