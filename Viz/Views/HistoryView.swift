import SwiftUI
import AlinFoundation

struct HistoryView: View {
    @ObservedObject private var historyState: HistoryState
    @State private var feedbackResetID: UInt64 = 0
    @State private var filterSelection = HistoryFilter.all

    init(historyState: HistoryState? = nil) {
        self.historyState = historyState ?? .shared
    }

    private var filteredItems: [HistoryEntry] {
        historyState.historyItems.reversed().filter { entry in
            switch entry {
            case .text: filterSelection.includes(isText: true)
            case .color: filterSelection.includes(isText: false)
            }
        }
    }

    var body: some View {
        let items = filteredItems
        VStack(spacing: 0) {
            Text("History").font(.title).padding(.vertical)
            if historyState.repository.isLoading { ProgressView("Loading history") }
            if let failure = historyState.repository.failure {
                VStack {
                    Text(failure).foregroundStyle(.red)
                    Button("Retry") { historyState.repository.retry() }
                }.padding()
            }
            Spacer()
            HistoryListContentView(
                entries: items,
                emptyMessage: filterSelection.emptyMessage,
                feedbackResetID: feedbackResetID,
                delete: { historyState.delete(id: $0) }
            )
            Spacer()
            HStack {
                Picker("Capture type", selection: $filterSelection) {
                    ForEach(HistoryFilter.allCases) { filter in Text(filter.title).tag(filter) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Spacer()
                Button(role: .destructive) {
                    clearClipboard(historyState: historyState)
                    feedbackResetID &+= 1
                } label: {
                    Label("Clear history and clipboard", systemImage: "trash").labelStyle(.iconOnly)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .help("Clear history and clipboard")
            }
            .padding(.vertical)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
        .background(Color("bg"))
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
    }
}

func isRecognizedURLFormat(_ text: String) -> Bool {
    let pattern = #"^(https?:\/\/)?(www\.)?[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}.*$"#
    return text.range(of: pattern, options: .regularExpression) != nil
}
