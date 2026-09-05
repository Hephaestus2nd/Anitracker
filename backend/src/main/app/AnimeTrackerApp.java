package app;


import java.util.Map;
import io.jooby.jackson.JacksonModule;
import io.jooby.Jooby;
import io.jooby.StatusCode;
import org.jdbi.v3.core.Jdbi;
import org.jdbi.v3.sqlobject.SqlObjectPlugin;

public class AnimeTrackerApp extends Jooby {
    public AnimeTrackerApp() {
install(new JacksonModule());

        String dbUrl = System.getenv().getOrDefault("DB_URL", "jdbc:postgresql://192.168.56.10:5432/anitracker");
        String dbUser = System.getenv().getOrDefault("DB_USER", "app_user");
        String dbPassword = System.getenv().getOrDefault("DB_PASSWORD", "AppPass123");


        
        Jdbi jdbi = Jdbi.create(dbUrl, dbUser, dbPassword);
        jdbi.installPlugin(new SqlObjectPlugin());
        AnimeJdbiDAO animeDao = jdbi.onDemand(AnimeJdbiDAO.class);
        AniListClient aniListClient = new AniListClient(
                System.getenv().getOrDefault("ANILIST_GRAPHQL_URL", "https://graphql.anilist.co"));

        get("/health", ctx -> {
            try {
                jdbi.withHandle(handle -> handle.createQuery("SELECT 1").mapTo(Integer.class).one());
                return Map.of(
                    "status", "ok",
                    "database", "connected",
                    "service", "anime-tracker"
                );
            } catch (RuntimeException exception) {
                ctx.setResponseCode(StatusCode.SERVICE_UNAVAILABLE);
                return Map.of(
                    "status", "error",
                    "database", "unavailable",
                    "service", "anime-tracker"
                );
            }
        });

        get("/anime", ctx -> animeDao.getAllAnime());

        get("/anime/{malId}", ctx -> {
            int malId = ctx.path("malId").intValue();
            Anime anime = animeDao.getAnimeByMalId(malId);
            if (anime == null) {
                ctx.setResponseCode(StatusCode.NOT_FOUND);
                return Map.of("error", "Anime not found");
            }
            return anime;
        });

        post("/anime", ctx -> {
            Anime anime = ctx.body(Anime.class);
            String validationError = validateAnime(anime);
            if (validationError != null) {
                ctx.setResponseCode(StatusCode.BAD_REQUEST);
                return Map.of("error", validationError);
            }

            normalizeEpisodeCounts(anime);
            try {
                anime.setBackgroundImageUrl(aniListClient.getBannerImage(anime.getMalId()));
            } catch (IllegalStateException exception) {
                ctx.setResponseCode(StatusCode.BAD_GATEWAY);
                return Map.of("error", exception.getMessage());
            }

            animeDao.addAnime(anime);
            return animeDao.getAnimeByMalId(anime.getMalId());
        });
    }

    private static String validateAnime(Anime anime) {
        if (anime == null) {
            return "Request body is required";
        }
        if (anime.getMalId() == null || anime.getMalId() <= 0) {
            return "malId must be a positive integer";
        }
        if (anime.getTitle() == null || anime.getTitle().isBlank()) {
            return "title is required";
        }
        if (anime.getWatchStatus() == null) {
            return "watchStatus is invalid";
        }
        if (anime.getTotalEpisodes() != null && anime.getTotalEpisodes() < 0) {
            return "totalEpisodes cannot be negative";
        }
        if (anime.getEpisodesWatched() != null && anime.getEpisodesWatched() < 0) {
            return "episodesWatched cannot be negative";
        }
        return null;
    }

//This works for now . If we want to make it better we can use an enum for watchStatus and validate against that.
//we do already have enums but it'll be a lot of overhead.
    // private static boolean isValidWatchStatus(String status) {
    //     return status.equals("Watching")
    //             || status.equals("Completed")
    //             || status.equals("On-Hold")
    //             || status.equals("Dropped")
    //             || status.equals("Plan to Watch");
    // }


    private static void normalizeEpisodeCounts(Anime anime) {
        int episodesWatched = anime.getEpisodesWatched() == null ? 0 : anime.getEpisodesWatched();
        Integer totalEpisodes = anime.getTotalEpisodes();
        if (totalEpisodes != null && totalEpisodes > 0) {
            episodesWatched = Math.min(episodesWatched, totalEpisodes);
        }
        anime.setEpisodesWatched(episodesWatched);
    }

    public static void main(String[] args) {
        Jooby.runApp(args, AnimeTrackerApp::new);
    }
}