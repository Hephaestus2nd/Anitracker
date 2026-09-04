package app;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class AniListClient {
    private static final Pattern BANNER_IMAGE_PATTERN =
            Pattern.compile("\"bannerImage\"\\s*:\\s*\"([^\"]+)\"");

    private final HttpClient httpClient;
    private final URI endpoint;

    public AniListClient(String endpoint) {
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
        this.endpoint = URI.create(endpoint);
    }

    public String getBannerImage(int malId) {
        String requestBody = "{\"query\":\"query ($malId: Int) { Media(idMal: $malId, type: ANIME) { bannerImage } }\","
                + "\"variables\":{\"malId\":" + malId + "}}";

        HttpRequest request = HttpRequest.newBuilder(endpoint)
                .timeout(Duration.ofSeconds(10))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                .build();

        final HttpResponse<String> response;
        try {
            response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        } catch (IOException exception) {
            throw new IllegalStateException("Unable to reach AniList", exception);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("AniList request was interrupted", exception);
        }

        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IllegalStateException("AniList returned HTTP " + response.statusCode());
        }

        Matcher matcher = BANNER_IMAGE_PATTERN.matcher(response.body());
        if (!matcher.find() || matcher.group(1).isBlank()) {
            throw new IllegalStateException("AniList did not return a banner for MAL ID " + malId);
        }
        return matcher.group(1);
    }
}
