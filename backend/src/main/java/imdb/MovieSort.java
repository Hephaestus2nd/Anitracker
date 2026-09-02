package imdb;

import java.util.Map;

public final class MovieSort {
  private static final Map<String, String> SORT_COLUMNS = Map.of(
      "title", "title",
      "year", "release_year",
      "rating", "rating"
  );

  private MovieSort() {
  }

  public static String toSqlColumn(String sortBy) {
    if (sortBy == null) {
      return "title";
    }
    return SORT_COLUMNS.getOrDefault(sortBy.toLowerCase(), "title");
  }
}
