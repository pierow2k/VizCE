import Foundation
import SwiftUI
import AlinFoundation

struct ColorItem: Identifiable, Codable {
    let id: String
    let hex: String
    let rgb: String
    var color: Color { Color(hex: hex) ?? Color.white }

    init(hex: String, rgb: String, id: String = UUID().uuidString) {
        self.id = id
        self.hex = hex
        self.rgb = rgb
    }
}
