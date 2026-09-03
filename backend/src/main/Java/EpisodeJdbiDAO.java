
import java.util.List;

import org.jdbi.v3.sqlobject.config.RegisterBeanMapper;
import org.jdbi.v3.sqlobject.customizer.Bind;
import org.jdbi.v3.sqlobject.customizer.BindBean;
import org.jdbi.v3.sqlobject.statement.GetGeneratedKeys;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;

@RegisterBeanMapper(Episode.class)
public interface EpisodeJdbiDAO {

    @SqlQuery("SELECT * FROM episode_notes ORDER BY id")
    List<Episode> getAllEpisodes();

    @SqlQuery("SELECT * FROM episode_notes WHERE id = :id")
    Episode getEpisodeById(@Bind("id") int id);

    @SqlQuery("SELECT * FROM episode_notes WHERE anime_id = :animeId ORDER BY episode_number")
    List<Episode> getEpisodesByAnimeId(@Bind("animeId") int animeId);

    @SqlUpdate("INSERT INTO episode_notes (anime_id, episode_number, notes) " +
            "VALUES (:animeId, :episodeNumber, :notes)")
    @GetGeneratedKeys
    int insertEpisode(@BindBean Episode episode);

    @SqlUpdate("UPDATE episode_notes SET " +
            "anime_id = :animeId, " +
            "episode_number = :episodeNumber, " +
            "notes = :notes " +
            "WHERE id = :id")
    void updateEpisode(@BindBean Episode episode);

    @SqlUpdate("DELETE FROM episode_notes WHERE id = :id")
    void deleteEpisode(@Bind("id") int id);
}
