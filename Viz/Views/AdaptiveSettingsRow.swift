import SwiftUI

struct AdaptiveSettingsRow<Controls: View>: View {
    let title: LocalizedStringResource
    let controls: Controls

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
