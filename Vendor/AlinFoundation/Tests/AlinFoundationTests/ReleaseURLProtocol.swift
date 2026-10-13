import Foundation

/// Returns a GitHub release fixture only for updater regression-test requests.
final class ReleaseURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.path.hasPrefix("/repos/VizCEUpdaterTests/") == true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    /// Delivers a successful release response without making a network request.
    override func startLoading() {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let tag = url.path.contains("/current-") ? "v0.0.0" : "v3.0.0"
        let data = Data(#"[{"id":411006752,"tag_name":"\#(tag)","name":"\#(tag)","body":"Initial release","assets":[]}]"#.utf8)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
