import AppKit

extension NSTextView {
    /// The text view frame; each update reapplies the named `mode` color to the insertion point.
    open override var frame: CGRect {
        didSet {
            insertionPointColor = NSColor(named: "mode")
        }
    }
}
