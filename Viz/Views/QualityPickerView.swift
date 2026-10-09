import SwiftUI

struct QualityPickerView: View {
    @ObservedObject var appState = AppState.shared

    var body: some View {
        Picker("OCR quality", selection: $appState.selectedQuality) {
            Text("Fast").tag(TextRecognitionQuality.fast)
            Text("Accurate").tag(TextRecognitionQuality.accurate)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}
