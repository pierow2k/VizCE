import Foundation

/// User-visible failures when GitHub does not return a usable release list.
enum ReleaseFetchError: LocalizedError {
    case invalidResponse
    /// An unsuccessful HTTP status returned by the release endpoint.
    case httpStatus(Int)
    case invalidReleaseData

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            String(localized: "GitHub returned an invalid response while loading releases.")
        case let .httpStatus(statusCode):
            String(localized: "GitHub returned HTTP \(statusCode) while loading releases.")
        case .invalidReleaseData:
            String(localized: "GitHub returned release data that could not be read.")
        }
    }
}
