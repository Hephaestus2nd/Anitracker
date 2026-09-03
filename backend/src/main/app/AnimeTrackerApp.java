package app;


import java.util.Map;

import io.jooby.Jooby;
import io.jooby.StatusCode;
import org.jdbi.v3.core.Jdbi;
import org.jdbi.v3.sqlobject.SqlObjectPlugin;

public class AnimeTrackerApp extends Jooby {
    public AnimeTrackerApp() {
        String dbUrl = System.getenv().getOrDefault("DB_URL", "jdbc:postgresql://192.168.56.10:5432/anitracker");
        String dbUser = System.getenv().getOrDefault("DB_USER", "app_user");
        String dbPassword = System.getenv().getOrDefault("DB_PASSWORD", "AppPass123");

        Jdbi jdbi = Jdbi.create(dbUrl, dbUser, dbPassword);
        jdbi.installPlugin(new SqlObjectPlugin());
        AnimeJdbiDAO animeDao = jdbi.onDemand(AnimeJdbiDAO.class);

        get("/health", ctx -> Map.of(
            "status", "ok",
            "database", "connected",
            "service", "anime-tracker"
        ));

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
            animeDao.insertAnime(anime);
            return animeDao.getAnimeByMalId(anime.getMalId());
        });
    }

    public static void main(String[] args) {
        Jooby.runApp(args, AnimeTrackerApp::new);
    }
}