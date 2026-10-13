import Foundation

/// Returns success and failure fixtures only for updater regression-test requests.
final class ReleaseURLProtocol: URLProtocol {
    private static let attempts = ReleaseRequestCounts()
    /// Allows overlap tests to wait until the first mocked request has actually started.
    static let requestStarted = Notification.Name("VizCEUpdaterTests.requestStarted")
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.path.hasPrefix("/repos/VizCEUpdaterTests/") == true
            || request.url?.path == "/repositories/0/releases"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    /// Delivers the response selected by the test URL and attempt number without network access.
    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let attempt = Self.attempts.next(for: url)
        NotificationCenter.default.post(name: Self.requestStarted, object: url)
        if url.path.contains("/offline-") {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        // Fail explicitly if the cache regression fixture receives a request that could use stale redirects.
        if url.path.contains("/cache-") && request.cachePolicy != .reloadIgnoringLocalCacheData {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let status: Int
        if url.path.contains("/http403-") {
            status = 403
        } else if url.path.contains("/http404-")
            || (url.path.contains("/retry-") && attempt == 1)
            || (url.path.contains("/preserve-") && attempt > 1)
            || (url.path.contains("/overlap-") && attempt == 1) {
            status = 404
        } else {
            status = 200
        }
        guard let httpResponse = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let response: URLResponse = url.path.contains("/nonhttp-")
            ? URLResponse(url: url, mimeType: "application/json", expectedContentLength: 0, textEncodingName: nil)
            : httpResponse
        let tag = url.path.contains("/current-") ? "v0.0.0" : "v3.0.0"
        let body: String
        if url.path.contains("/malformed-") {
            body = "not JSON"
        } else if url.path.contains("/empty-") || (url.path.contains("/emptyafter-") && attempt > 1) {
            body = "[]"
        } else {
            body = #"[{"id":411006752,"tag_name":"\#(tag)","name":"\#(tag)","body":"Initial release","assets":[]}]"#
        }
        let data = Data(body.utf8)
        if url.path.contains("/overlap-") && attempt == 1 {
            Task { @MainActor in
                try await Task.sleep(for: .milliseconds(200))
                self.deliver(response: response, data: data)
            }
        } else {
            deliver(response: response, data: data)
        }
    }

    /// Completes a mocked request with the specified response and body.
    private func deliver(response: URLResponse, data: Data) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
