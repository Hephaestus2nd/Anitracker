import java.util.List;
import java.util.Optional;

public interface EpisodeDAO {
    List<Episode> getAllEpisodes();

    Optional<Episode> getEpisodeById(int id);

    void insertEpisode(Episode episode);

    void updateEpisode(Episode episode);

    void deleteEpisode(int id);
}
