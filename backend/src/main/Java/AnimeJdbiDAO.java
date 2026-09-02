package com.example.anime;

import java.util.List;

import org.jdbi.v3.sqlobject.config.RegisterBeanMapper;
import org.jdbi.v3.sqlobject.customizer.Bind;
import org.jdbi.v3.sqlobject.customizer.BindBean;
import org.jdbi.v3.sqlobject.statement.GetGeneratedKeys;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;

@RegisterBeanMapper(Anime.class)
public interface AnimeJdbiDAO {

    @SqlQuery("SELECT * FROM my_anime ORDER BY id")
    List<Anime> getAllAnime();

    @SqlQuery("SELECT * FROM my_anime WHERE id = :id")
    Anime getAnimeById(@Bind("id") int id);

    @SqlQuery("SELECT * FROM my_anime WHERE title = :title")
    Anime getAnimeByTitle(@Bind("title") String title);

    @SqlUpdate("INSERT INTO my_anime (mal_id, title, total_episodes, episodes_watched, watch_status, cover_image_url, synopsis) " +
            "VALUES (:malId, :title, :totalEpisodes, :episodesWatched, :watchStatus, :coverImageUrl, :synopsis)")
    @GetGeneratedKeys
    int insertAnime(@BindBean Anime anime);

    @SqlUpdate("UPDATE my_anime SET " +
            "mal_id = :malId, " +
            "title = :title, " +
            "total_episodes = :totalEpisodes, " +
            "episodes_watched = :episodesWatched, " +
            "watch_status = :watchStatus, " +
            "cover_image_url = :coverImageUrl, " +
            "synopsis = :synopsis " +
            "WHERE id = :id")
    void updateAnime(@BindBean Anime anime);

    @SqlUpdate("DELETE FROM my_anime WHERE id = :id")
    void deleteAnime(@Bind("id") int id);
}
