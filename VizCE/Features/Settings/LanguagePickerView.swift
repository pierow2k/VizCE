import SwiftUI

/// Supported recognition languages with loading, retry, and unavailable-selection feedback.
struct LanguagePickerView: View {
    @ObservedObject var appState = AppState.shared
    @Environment(\.locale) private var locale

    var body: some View {
        let selectionIsUnavailable =
            appState.selectedLanguageCode != "All"
            && !appState.languages.codes.contains(appState.selectedLanguageCode)
        VStack(alignment: .leading) {
            Picker("OCR language", selection: $appState.selectedLanguageCode) {
                Text("All").tag("All")
                ForEach(appState.languages.codes, id: \.self) { code in
                    Text(RecognitionLanguageName.displayName(for: code, locale: locale)).tag(code)
                }
                if selectionIsUnavailable {
                    Text(
                        """
                        \(RecognitionLanguageName.displayName(for: appState.selectedLanguageCode, locale: locale)) \
                        (Unavailable)
                        """
                    )
                    .tag(appState.selectedLanguageCode)
                    .disabled(true)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .disabled(appState.languages.isLoading)
            if let failure = appState.languages.failure {
                Text(failure).font(.caption)
                Button("Retry") { appState.refreshLanguages() }
            } else if !appState.languages.isLoading, selectionIsUnavailable {
                Text("This language is unavailable at the selected quality. Recognition will use All languages.")
                    .font(.caption)
            }
        }
    }
}
