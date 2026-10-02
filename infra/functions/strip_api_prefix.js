// Viewer-request function for the /api/* behaviour.
// The backend serves /health, /anime, ... so drop the /api prefix (same as Nginx proxy_pass .../;).
function handler(event) {
    var request = event.request;
    request.uri = request.uri.replace(/^\/api/, '') || '/';
    return request;
}
