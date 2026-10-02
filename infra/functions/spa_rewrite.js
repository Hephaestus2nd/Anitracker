// Viewer-request function for the default (S3) behaviour.
// Vue Router uses history mode, so paths like /anime/123 must serve index.html
// (same as Nginx try_files $uri $uri/ /index.html). Paths with a file extension are real assets.
function handler(event) {
    var request = event.request;
    var lastSegment = request.uri.split('/').pop();

    if (lastSegment.indexOf('.') === -1) {
        request.uri = '/index.html';
    }

    return request;
}
