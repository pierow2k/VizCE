//
//  WindowActions.swift
//  VizCE
//
//  Created by Alin Lupascu on 3/27/25.
//

import AlinFoundation
import AVFoundation
import SwiftUI

/// Opens the history window through the shared window manager.
@MainActor
func openHistory() {
    WindowManager.shared.open(id: "history", with: HistoryView(), width: 500, height: 600)
}

/// Shows or brings forward the shared webcam capture window.
@MainActor
func openWebcamCapture() {
    WebcamWindowController.shared.show()
}
