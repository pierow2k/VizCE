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


struct PreviewContentView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var content = RecognizedContent.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()

                Button {
                    PreviewWindowController.shared.close()
                } label: {
                    Label("Close preview", systemImage: "x.circle.fill")
                }
                .buttonStyle(SimpleButtonStyle(help: "Close", color: .primary, size: 14))
            }
            .padding(2)

            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(content.items, id: \.id) { item in
                        let text = item.text
                        let trimmedText = text.last == "\n" ? String(text.dropLast()) : text
                        Text(trimmedText)
                            .textSelection(.enabled)
                    }
                }
            }
            .scrollIndicators(.visible)
            .padding([.horizontal, .bottom])
            .frame(minWidth: 200)

            Spacer()


            if !appState.cmdOutput.isEmpty {
                HStack(spacing: 0) {
                    Rectangle()
                        .frame(height: 1)
                        .opacity(0.2)

                    Text("Processing Output")
                        .textCase(.uppercase)
                        .font(.footnote)
                        .opacity(0.6)
                        .padding(.horizontal, 10)
                        .frame(minWidth: 150)

                    Rectangle()
                        .frame(height: 1)
                        .opacity(0.2)
                }
                .frame(minHeight: 35)

                ScrollView {
                    Text(appState.cmdOutput)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.visible)
                .padding([.horizontal, .bottom])


            }
        }
        .foregroundColor(.primary)
        .material(.sidebar)
    }
}


struct ColorPreviewView: View {

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()

                Button {
                    PreviewWindowController.shared.close()
                } label: {
                    Label("Close preview", systemImage: "x.circle.fill")
                }
                .buttonStyle(SimpleButtonStyle(help: "Close", color: .primary, size: 14))
            }
            .padding(2)

            VStack(alignment: .leading) {
                Text("Hex: \(AppState.shared.colorSample.hex)")
                Text("RGB: \(AppState.shared.colorSample.rgb)")
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppState.shared.colorSample.color)
            }
            .padding([.horizontal, .bottom])
        }
        .foregroundColor(.primary)
        .material(.sidebar)
    }
}





@MainActor
func showPreviewWindow<Content: View>(contentView: Content) {
    PreviewWindowController.shared.show(contentView)
}
