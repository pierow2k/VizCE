import AppKit

extension NSTextView {
    // SwiftUI creates the text views, so this override applies caret styling to those instances.
    /// The text view frame; each update reapplies the named `mode` color to the insertion point.
    override open var frame: CGRect { // swiftlint:disable:this override_in_extension
        didSet {
            insertionPointColor = NSColor(named: "mode")
        }
    }
}
