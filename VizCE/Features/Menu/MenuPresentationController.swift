import Foundation

/// The main-actor dismissal action registered by the currently installed menu view.
@MainActor
final class MenuPresentationController {
    static let shared = MenuPresentationController()
    /// The current menu identity, used to ignore unregistration from a replaced menu view.
    private var registration: UUID?
    private var dismissAction: (@MainActor () -> Void)?

    /// Replaces the menu dismissal action and returns the token used to unregister this view.
    func register(_ action: @escaping @MainActor () -> Void) -> UUID {
        let id = UUID()
        registration = id
        dismissAction = action
        return id
    }

    /// Clears the dismissal action only when the token belongs to the current menu registration.
    func unregister(_ id: UUID) {
        guard registration == id else { return }
        registration = nil
        dismissAction = nil
    }

    /// Invokes the installed menu dismissal action when one is registered.
    func dismiss() { dismissAction?() }
}
