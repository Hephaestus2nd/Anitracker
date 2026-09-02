package imdb;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class MovieSortTest {

  @Test
  void defaultsToTitleForUnknownValues() {
    assertEquals("title", MovieSort.toSqlColumn(null));
    assertEquals("title", MovieSort.toSqlColumn(""));
    assertEquals("title", MovieSort.toSqlColumn("DROP TABLE movies"));
  }

  @Test
  void mapsKnownSortFields() {
    assertEquals("title", MovieSort.toSqlColumn("title"));
    assertEquals("release_year", MovieSort.toSqlColumn("year"));
    assertEquals("rating", MovieSort.toSqlColumn("rating"));
  }
}
