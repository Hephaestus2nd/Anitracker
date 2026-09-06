package app;
import java.util.List;

public interface AnimeDAO {
    List<Anime> getAllAnime();
    Anime getAnimeByMalId(int malId);
    Anime getAnimeByTitle(String title);
    void addAnime(Anime anime);
    void updateAnime(Anime anime);
    void deleteAnime(int malId);
}
