package app;

import java.util.Map;
import io.jooby.jackson.JacksonModule;
import io.jooby.Jooby;
import io.jooby.StatusCode;
import org.jdbi.v3.core.Jdbi;
import org.jdbi.v3.sqlobject.SqlObjectPlugin;

public class AnimeTrackerApp extends Jooby {
    private static final Map<String, String> env = System.getenv();

    private static Map<String, String> healthResponse(String status, String dbStatus) {
        return Map.of(
            "status", status,
            "database", dbStatus,
            "service", "anime-tracker"
        );
    }

    private static Map<String, String> errorResponse(String errorMsg) {
        return Map.of("error", errorMsg);
    }

    private static String validateAnime(Anime anime) {
        if (anime == null) {
            return "Request body is required.";
        }

        if (anime.getMalId() == null || anime.getMalId() <= 0) {
            return "malId must be a positive integer.";
        }

        if (anime.getTitle() == null || anime.getTitle().isBlank()) {
            return "title is required.";
        }

        if (anime.getWatchStatus() == null) {
            return "watchStatus is invalid.";
        }

        if (anime.getTotalEpisodes() != null && anime.getTotalEpisodes() < 0) {
            return "totalEpisodes cannot be negative.";
        }

        if (anime.getEpisodesWatched() != null && anime.getEpisodesWatched() < 0) {
            return "episodesWatched cannot be negative.";
        }

        return null;
    }

    private static void normalizeEpisodeCounts(Anime anime) {
        int episodesWatched = (anime.getEpisodesWatched() == null) ? 0 : anime.getEpisodesWatched();

        Integer totalEpisodes = anime.getTotalEpisodes();
        if (totalEpisodes != null && totalEpisodes > 0) {
            episodesWatched = Math.min(episodesWatched, totalEpisodes);
        }

        anime.setEpisodesWatched(episodesWatched);
    }

    public AnimeTrackerApp() {
        install(new JacksonModule());

        // Get env info
        String dbUrl = env.getOrDefault("DB_URL", "jdbc:postgresql://192.168.56.10:5432/anitracker");
        String dbUser = env.getOrDefault("DB_USER", "app_user");
        String dbPassword = env.getOrDefault("DB_PASSWORD", "AppPass123");

        // JDBI
        Jdbi jdbi = Jdbi.create(dbUrl, dbUser, dbPassword);
        jdbi.installPlugin(new SqlObjectPlugin());

        // Actual DAO
        AnimeJdbiDAO animeDao = jdbi.onDemand(AnimeJdbiDAO.class);

        // API Endpoints
        get("/health", ctx -> {
            try {
                jdbi.withHandle(handle -> handle.createQuery("SELECT 1")
                        .mapTo(Integer.class).one());

                return healthResponse("ok", "connected");
            } catch (RuntimeException exception) {
                ctx.setResponseCode(StatusCode.SERVICE_UNAVAILABLE);
                return healthResponse("error", "unavailable");
            }
        });

        get("/anime", ctx -> animeDao.getAllAnime());

        get("/anime/{malId}", ctx -> {
            int malId = ctx.path("malId").intValue();
            Anime anime = animeDao.getAnimeByMalId(malId);

            if (anime == null) {
                ctx.setResponseCode(StatusCode.NOT_FOUND);
                return errorResponse("Anime not found");
            }

            return anime;
        });

        delete("/anime/{malId}", ctx -> {
            int malId = ctx.path("malId").intValue();
            int rowsAffected = animeDao.deleteAnime(malId);

            if (rowsAffected == 0) {
                ctx.setResponseCode(StatusCode.NOT_FOUND);
                return errorResponse("Anime not found");
            }

            ctx.setResponseCode(StatusCode.NO_CONTENT);
            return ""; // Standard format for DELETE
        });

        post("/anime", ctx -> {
            Anime anime = ctx.body(Anime.class);
            String validationError = validateAnime(anime);

            if (validationError != null) {
                ctx.setResponseCode(StatusCode.BAD_REQUEST);
                return errorResponse(validationError);
            }

            normalizeEpisodeCounts(anime);

            animeDao.addAnime(anime);
            return animeDao.getAnimeByMalId(anime.getMalId());
        });

        put("/anime/{malId}", ctx -> {
            int malId = ctx.path("malId").intValue();
            Anime anime = ctx.body(Anime.class);

            if (anime == null) {
                ctx.setResponseCode(StatusCode.BAD_REQUEST);
                return errorResponse("Request body is required.");
            }

            if (anime.getMalId() != null && anime.getMalId() != malId) {
                ctx.setResponseCode(StatusCode.BAD_REQUEST);
                return errorResponse("malId in the URL and request body must match.");
            }

            anime.setMalId(malId);

            String validationError = validateAnime(anime);
            if (validationError != null) {
                ctx.setResponseCode(StatusCode.BAD_REQUEST);
                return errorResponse(validationError);
            }

            if (animeDao.getAnimeByMalId(malId) == null) {
                ctx.setResponseCode(StatusCode.NOT_FOUND);
                return errorResponse("Anime not found");
            }

            normalizeEpisodeCounts(anime);

            animeDao.updateAnime(anime);
            return animeDao.getAnimeByMalId(malId);
        });
    }

    public static void main(String[] args) {
        Jooby.runApp(args, AnimeTrackerApp::new);
    }
}