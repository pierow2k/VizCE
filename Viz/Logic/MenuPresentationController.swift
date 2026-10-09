import Foundation

/// Holds only the dismissal action registered by the currently installed menu view.
@MainActor
final class MenuPresentationController {
    static let shared = MenuPresentationController()
    private var registration: UUID?
    private var dismissAction: (@MainActor () -> Void)?

    func register(_ action: @escaping @MainActor () -> Void) -> UUID {
        let id = UUID()
        registration = id
        dismissAction = action
        return id
    }

    func unregister(_ id: UUID) {
        guard registration == id else { return }
        registration = nil
        dismissAction = nil
    }

    func dismiss() { dismissAction?() }
}
