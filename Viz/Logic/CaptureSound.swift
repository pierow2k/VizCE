import AppKit
import SwiftUI

@MainActor
func playCaptureSound() {
    @AppStorage("mute") var mute: Bool = false
    guard !mute else { return }
    if let sound = NSSound(named: "water") {
        sound.play()
    }
}
