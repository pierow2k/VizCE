import SwiftUI

struct HistoryListContentView: View {
    let entries: [HistoryEntry]
    let emptyMessage: LocalizedStringResource
    let feedbackResetID: UInt64
    let delete: @MainActor (String) -> Void
    @StateObject private var feedback = CopyFeedbackController()

    var body: some View {
        Group {
            if entries.isEmpty {
                Text(emptyMessage).foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(entries) { entry in
                            HistoryRow(entry: entry, feedback: feedback) { delete(entry.id) }
                        }
                    }
                }
                .scrollIndicators(.never)
            }
        }
        .onChange(of: feedbackResetID) { feedback.clear() }
        .onDisappear { feedback.clear() }
    }
}
