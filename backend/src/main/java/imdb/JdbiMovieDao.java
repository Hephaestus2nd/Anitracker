package imdb;

import org.jdbi.v3.core.Jdbi;

import java.util.List;
import java.util.Optional;

public class JdbiMovieDao {
  private final Jdbi jdbi;

  public JdbiMovieDao(Jdbi jdbi) {
    this.jdbi = jdbi;
  }

  public List<Movie> listMovies(String sortBy, String genreFilter) {
    String sortColumn = MovieSort.toSqlColumn(sortBy);

    return jdbi.withHandle(handle -> {
      var query = handle.createQuery("""
            SELECT id, title, genre, release_year, rating, director, synopsis
            FROM movies
            WHERE (:genreFilter IS NULL OR LOWER(genre) = LOWER(:genreFilter))
            ORDER BY %s ASC, id ASC
          """.formatted(sortColumn))
          .bind("genreFilter", normalizeGenreFilter(genreFilter));

      return query.map((rs, ctx) -> new Movie(
          rs.getLong("id"),
          rs.getString("title"),
          rs.getString("genre"),
          rs.getInt("release_year"),
          rs.getDouble("rating"),
          rs.getString("director"),
          rs.getString("synopsis")
      )).list();
    });
  }

  public Optional<Movie> getMovieById(long id) {
    return jdbi.withHandle(handle -> handle.createQuery("""
          SELECT id, title, genre, release_year, rating, director, synopsis
          FROM movies
          WHERE id = :id
        """)
        .bind("id", id)
        .map((rs, ctx) -> new Movie(
            rs.getLong("id"),
            rs.getString("title"),
            rs.getString("genre"),
            rs.getInt("release_year"),
            rs.getDouble("rating"),
            rs.getString("director"),
            rs.getString("synopsis")
        ))
        .findOne());
  }

  private String normalizeGenreFilter(String genreFilter) {
    if (genreFilter == null || genreFilter.isBlank()) {
      return null;
    }
    return genreFilter.trim();
  }
}
