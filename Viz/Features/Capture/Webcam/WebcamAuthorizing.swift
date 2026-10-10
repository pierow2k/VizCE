/// An asynchronous boundary for camera permission checks and requests.
protocol WebcamAuthorizing: Sendable {
    /// Checks or requests camera permission and returns whether video access is allowed.
    func isAuthorized() async -> Bool
}
