package imdb;

public record Movie(
    long id,
    String title,
    String genre,
    int releaseYear,
    double rating,
    String director,
    String synopsis
) {
}
