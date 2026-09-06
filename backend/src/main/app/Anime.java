package app;

public class Anime {
    private Integer malId;
    private String title;
    private Integer totalEpisodes;
    private Integer episodesWatched;
    private WatchStatus watchStatus;
    private String coverImageUrl;
    private String backgroundImageUrl;
    private String synopsis;

    public Integer getMalId() {
        return malId;
    }
    public void setMalId(Integer malId) {
        this.malId = malId;
    }

    public String getTitle() {
        return title;
    }
    public void setTitle(String title) {
        this.title = title;
    }

    public Integer getTotalEpisodes() {
        return totalEpisodes;
    }
    public void setTotalEpisodes(Integer totalEpisodes) {
        this.totalEpisodes = totalEpisodes;
    }

    public Integer getEpisodesWatched() {
        return episodesWatched;
    }
    public void setEpisodesWatched(Integer episodesWatched) {
        this.episodesWatched = episodesWatched;
    }

    public String getWatchStatus() {
        return (watchStatus == null) ? null : watchStatus.getDatabaseValue();
    }
    public void setWatchStatus(String watchStatus) {
        this.watchStatus = (watchStatus == null) ? null : WatchStatus.fromValue(watchStatus);
    }

    public String getCoverImageUrl() {
        return coverImageUrl;
    }
    public void setCoverImageUrl(String coverImageUrl) {
        this.coverImageUrl = coverImageUrl;
    }

    public String getBackgroundImageUrl() {
        return backgroundImageUrl;
    }
    public void setBackgroundImageUrl(String backgroundImageUrl) {
        this.backgroundImageUrl = backgroundImageUrl;
    }

    public String getSynopsis() {
        return synopsis;
    }
    public void setSynopsis(String synopsis) {
        this.synopsis = synopsis;
    }
}