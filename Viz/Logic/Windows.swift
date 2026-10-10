//
//  Windows.swift
//  Viz
//
//  Created by Alin Lupascu on 3/27/25.
//

import SwiftUI
import AlinFoundation
import AVFoundation

@MainActor
func openHistory() {
    WindowManager.shared.open(id: "history", with: HistoryView(), width: 500, height: 600)
}

@MainActor
func openWebcamCapture() {
    WebcamWindowController.shared.show()
}
