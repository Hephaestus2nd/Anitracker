package app;
import java.util.List;

import org.jdbi.v3.sqlobject.config.RegisterBeanMapper;
import org.jdbi.v3.sqlobject.customizer.Bind;
import org.jdbi.v3.sqlobject.customizer.BindBean;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;

@RegisterBeanMapper(Anime.class)
public interface AnimeJdbiDAO {

    @SqlQuery("SELECT * FROM my_anime ORDER BY title")
    List<Anime> getAllAnime();

    @SqlQuery("SELECT * FROM my_anime WHERE mal_id = :malId")
    Anime getAnimeByMalId(@Bind("malId") int malId);

    @SqlQuery("SELECT * FROM my_anime WHERE title = :title")
    Anime getAnimeByTitle(@Bind("title") String title);

    @SqlUpdate("INSERT INTO my_anime (mal_id, title, total_episodes, episodes_watched, watch_status, " +
            "cover_image_url, background_image_url, synopsis) " +
        "VALUES (:malId, :title, :totalEpisodes, :episodesWatched, CAST(:watchStatus AS watch_status), " +
            ":coverImageUrl, :backgroundImageUrl, :synopsis)")
    void addAnime(@BindBean Anime anime);

    @SqlUpdate("UPDATE my_anime SET " +
            "title = :title, " +
            "total_episodes = :totalEpisodes, " +
            "episodes_watched = :episodesWatched, " +
            "watch_status = CAST(:watchStatus AS watch_status), " +
            "cover_image_url = :coverImageUrl, " +
            "background_image_url = :backgroundImageUrl, " +
            "synopsis = :synopsis " +
            "WHERE mal_id = :malId")
    void updateAnime(@BindBean Anime anime);

    @SqlUpdate("DELETE FROM my_anime WHERE mal_id = :malId")
    int deleteAnime(@Bind("malId") int malId);
}
