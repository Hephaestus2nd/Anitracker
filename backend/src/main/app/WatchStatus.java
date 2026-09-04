package app;

public enum WatchStatus {
    WATCHING("Watching"),
    COMPLETED("Completed"),
    ON_HOLD("On-Hold"),
    DROPPED("Dropped"),
    PLAN_TO_WATCH("Plan to Watch");

    private final String databaseValue;

    WatchStatus(String databaseValue) {
        this.databaseValue = databaseValue;
    }

    public static WatchStatus fromValue(String value) {
        for (WatchStatus status : values()) {
            if (status.databaseValue.equals(value)) {
                return status;
            }
        }
        throw new IllegalArgumentException("Invalid watch status: " + value);
    }

    public String getDatabaseValue() {
        return databaseValue;
    }

    @Override
    public String toString() {
        return databaseValue;
    }
}
