//
//  Notification.swift
//  Grabber
//
//  Created by Alin Lupascu on 4/5/24.
//

import Foundation
import AppKit
import SwiftUI
import AlinFoundation

@MainActor var cmdOutputWindow: NSWindow?
@MainActor var colorWindow: NSWindow?


@MainActor
func showPreviewWindow<Content: View>(contentView: Content) {
    PreviewWindowController.shared.show(contentView)
}
