import AppKit

// Hide blinking textfield caret
extension NSTextView {
    open override var frame: CGRect {
        didSet {
            insertionPointColor = NSColor(named: "mode")//.clear
        }
    }
}
