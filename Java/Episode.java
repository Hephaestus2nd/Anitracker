package Java;

public class Episode {
    private int episodeId;
    private int seasonId;
    private int episodeNumber;
    private String title;
    private String releaseDate;
    private String overview;
    private double rating;
    private int votes;
    private String stillPath;

    /**
     * Gets the unique identifier for the episode.
     *
     * @return the episode ID
     */
    public int getEpisodeId() {
        return episodeId;
    }

    /**
     * Sets the unique identifier for the episode.
     *
     * @param episodeId the episode ID to set
     */
    public void setEpisodeId(int episodeId) {
        this.episodeId = episodeId;
    }

    /**
     * Gets the season identifier the episode belongs to.
     *
     * @return the season ID
     */
    public int getSeasonId() {
        return seasonId;
    }

    /**
     * Sets the season identifier the episode belongs to.
     *
     * @param seasonId the season ID to set
     */
    public void setSeasonId(int seasonId) {
        this.seasonId = seasonId;
    }

    /**
     * Gets the numbered position of the episode within its season.
     *
     * @return the episode number
     */
    public int getEpisodeNumber() {
        return episodeNumber;
    }

    /**
     * Sets the numbered position of the episode within its season.
     *
     * @param episodeNumber the episode number to set
     */
    public void setEpisodeNumber(int episodeNumber) {
        this.episodeNumber = episodeNumber;
    }

    /**
     * Gets the title of the episode.
     *
     * @return the episode title
     */
    public String getTitle() {
        return title;
    }

    /**
     * Sets the title of the episode.
     *
     * @param title the episode title to set
     */
    public void setTitle(String title) {
        this.title = title;
    }

    /**
     * Gets the release date of the episode.
     *
     * @return the episode release date
     */
    public String getReleaseDate() {
        return releaseDate;
    }

    /**
     * Sets the release date of the episode.
     *
     * @param releaseDate the episode release date to set
     */
    public void setReleaseDate(String releaseDate) {
        this.releaseDate = releaseDate;
    }

    /**
     * Gets the overview or plot summary for the episode.
     *
     * @return the episode overview description
     */
    public String getOverview() {
        return overview;
    }

    /**
     * Sets the overview or plot summary for the episode.
     *
     * @param overview the episode overview to set
     */
    public void setOverview(String overview) {
        this.overview = overview;
    }

    /**
     * Gets the average rating for the episode.
     *
     * @return the episode rating
     */
    public double getRating() {
        return rating;
    }

    /**
     * Sets the average rating for the episode.
     *
     * @param rating the episode rating to set
     */
    public void setRating(double rating) {
        this.rating = rating;
    }

    /**
     * Gets the number of votes for the episode.
     *
     * @return the vote count
     */
    public int getVotes() {
        return votes;
    }

    /**
     * Sets the number of votes for the episode.
     *
     * @param votes the vote count to set
     */
    public void setVotes(int votes) {
        this.votes = votes;
    }

    /**
     * Gets the path to the episode still image.
     *
     * @return the still image path
     */
    public String getStillPath() {
        return stillPath;
    }

    /**
     * Sets the path to the episode still image.
     *
     * @param stillPath the still image path to set
     */
    public void setStillPath(String stillPath) {
        this.stillPath = stillPath;
    }
}
