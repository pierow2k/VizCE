import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// The screen capture shortcut, defaulting to Control-Command-1.
    static let captureContent = Self("captureContent", default: .init(.one, modifiers: [.command, .control]))
}

extension KeyboardShortcuts.Name {
    /// The webcam window shortcut, defaulting to Control-Command-2.
    static let captureWebcam = Self("captureWebcam", default: .init(.two, modifiers: [.command, .control]))
}

extension KeyboardShortcuts.Name {
    /// The color sampler shortcut, defaulting to Control-Command-3.
    static let eyedropper = Self("eyedropper", default: .init(.three, modifiers: [.command, .control]))
}

extension KeyboardShortcuts.Name {
    /// The history window shortcut, defaulting to Control-Command-4.
    static let history = Self("history", default: .init(.four, modifiers: [.command, .control]))
}

extension KeyboardShortcuts.Name {
    /// The history and clipboard reset shortcut, defaulting to Control-Command-5.
    static let clear = Self("clear", default: .init(.five, modifiers: [.command, .control]))
}
