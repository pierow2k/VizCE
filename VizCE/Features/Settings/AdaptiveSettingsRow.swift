import SwiftUI

/// A labeled settings row that stacks its controls when horizontal space is insufficient.
struct AdaptiveSettingsRow<Controls: View>: View {
    let title: LocalizedStringResource
    let controls: Controls

    /// Creates a labeled row and evaluates the controls builder once for adaptive layouts.
    ///
    /// - Parameters:
    ///   - title: The localized label describing the controls.
    ///   - controls: The view builder used in either the horizontal or stacked layout.
    init(_ title: LocalizedStringResource, @ViewBuilder controls: () -> Controls) {
        self.title = title
        self.controls = controls()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Text(title)
                Spacer()
                controls
            }
            .fixedSize(horizontal: true, vertical: false)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                controls
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
