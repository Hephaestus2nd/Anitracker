package app;


import java.util.List;

import org.jdbi.v3.sqlobject.config.RegisterBeanMapper;
import org.jdbi.v3.sqlobject.customizer.Bind;
import org.jdbi.v3.sqlobject.customizer.BindBean;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;

@RegisterBeanMapper(Episode.class)
public interface EpisodeJdbiDAO {

    @SqlQuery("SELECT * FROM episode_notes ORDER BY id")
    List<Episode> getAllEpisodes();

    @SqlQuery("SELECT * FROM episode_notes WHERE id = :id")
    Episode getEpisodeById(@Bind("id") int id);

    @SqlQuery("SELECT * FROM episode_notes WHERE mal_id = :malId ORDER BY episode_number")
    List<Episode> getEpisodesByMalId(@Bind("malId") int malId);

    @SqlUpdate("INSERT INTO episode_notes (mal_id, episode_number, notes) " +
            "VALUES (:malId, :episodeNumber, :notes)")
    void insertEpisode(@BindBean Episode episode);

    @SqlUpdate("UPDATE episode_notes SET " +
            "mal_id = :malId, " +
            "episode_number = :episodeNumber, " +
            "notes = :notes " +
            "WHERE id = :id")
    void updateEpisode(@BindBean Episode episode);

    @SqlUpdate("DELETE FROM episode_notes WHERE id = :id")
    void deleteEpisode(@Bind("id") int id);
}
