import AVFoundation

/// Camera authorization that requests access only when the user has not decided yet.
struct SystemWebcamAuthorization: WebcamAuthorizing {
    /// Checks camera access, requesting permission when authorization is undetermined.
    func isAuthorized() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }
}
