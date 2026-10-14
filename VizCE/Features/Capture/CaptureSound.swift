import AppKit
import SwiftUI

/// Plays the named capture sound when it exists and the saved mute preference is disabled.
@MainActor
func playCaptureSound() {
    @AppStorage("mute")
    var mute: Bool = false
    guard !mute else { return }
    if let sound = NSSound(named: "water") {
        sound.play()
    }
}
