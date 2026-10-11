import AlinFoundation
import Foundation
import SwiftUI

/// A captured color with clipboard representations and a stable history identifier.
struct ColorItem: Identifiable, Codable {
    let id: String
    /// The sampled color as `#RRGGBB`, or an empty string for an unsuccessful sample.
    let hex: String
    /// The sampled color as an integer `(red,green,blue)` tuple, or an empty string for an unsuccessful sample.
    let rgb: String
    /// The SwiftUI color parsed from `hex`, falling back to white when parsing fails.
    var color: Color { Color(hex: hex) ?? Color.white }

    /// Creates a captured color with its formatted clipboard values and stable identity.
    ///
    /// - Parameters:
    ///   - hex: The hexadecimal representation used for the swatch and clipboard.
    ///   - rgb: The formatted RGB component tuple displayed in history.
    ///   - id: The history identifier, generated for a new capture unless supplied.
    init(hex: String, rgb: String, id: String = UUID().uuidString) {
        self.id = id
        self.hex = hex
        self.rgb = rgb
    }
}
