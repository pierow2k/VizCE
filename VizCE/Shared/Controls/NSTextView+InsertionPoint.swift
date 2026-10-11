import AppKit

extension NSTextView {
    /// The text view frame; each update reapplies the named `mode` color to the insertion point.
    override open var frame: CGRect {
        didSet {
            insertionPointColor = NSColor(named: "mode")
        }
    }
}
