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



@MainActor
func showPreviewWindow<Content: View>(contentView: Content) {
    PreviewWindowController.shared.show(contentView)
}
