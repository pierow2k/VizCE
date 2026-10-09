protocol WebcamAuthorizing: Sendable {
    func isAuthorized() async -> Bool
}
