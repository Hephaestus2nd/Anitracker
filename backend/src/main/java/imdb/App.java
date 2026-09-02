package imdb;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import io.jooby.Jooby;
import io.jooby.StatusCode;
import io.jooby.exception.StatusCodeException;
import io.jooby.jackson.JacksonModule;
import org.jdbi.v3.core.Jdbi;

import java.util.Map;

public class App extends Jooby {
  public App() {
    install(new JacksonModule());

    HikariConfig hikariConfig = new HikariConfig();
    hikariConfig.setJdbcUrl(getEnv("DB_URL", "jdbc:postgresql://10.10.10.12:5432/imdb"));
    hikariConfig.setUsername(getEnv("DB_USER", "imdb"));
    hikariConfig.setPassword(getEnv("DB_PASSWORD", "imdbpass"));

    HikariDataSource dataSource = new HikariDataSource(hikariConfig);
    Jdbi jdbi = Jdbi.create(dataSource);
    JdbiMovieDao dao = new JdbiMovieDao(jdbi);

    get("/api/health", ctx -> Map.of("status", "ok"));

    get("/api/movies", ctx -> dao.listMovies(ctx.query("sort").valueOrNull(), ctx.query("genre").valueOrNull()));

    get("/api/movies/{id}", ctx -> {
      long id = ctx.path("id").longValue();
      return dao.getMovieById(id)
          .orElseThrow(() -> new StatusCodeException(StatusCode.NOT_FOUND, "Movie not found"));
    });
  }

  private static String getEnv(String key, String defaultValue) {
    String value = System.getenv(key);
    return value == null || value.isBlank() ? defaultValue : value;
  }

  public static void main(String[] args) {
    runApp(args, App::new);
  }
}
