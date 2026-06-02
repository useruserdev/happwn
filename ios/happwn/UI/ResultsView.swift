import SwiftUI

struct ResultsView: View {
    let result: ExtractionViewModel.ExtractionResultView

    private var allConfigs: String {
        result.configs.map(\.uri).joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(result.mode) · \(result.configs.count) конфигов")
                    .font(.subheadline).foregroundColor(.secondary)
                Spacer()
                if !result.configs.isEmpty {
                    Button {
                        UIPasteboard.general.string = allConfigs
                    } label: {
                        Label("Копировать всё", systemImage: "doc.on.doc")
                    }
                    .font(.subheadline)
                    ShareLink(item: allConfigs) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }

            if let raw = result.rawBody {
                Text("Не удалось распознать конфиги. Сырой ответ:")
                    .font(.footnote).foregroundColor(.secondary)
                ScrollView {
                    Text(raw).font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                List(result.configs) { config in
                    Text(config.uri)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                        .textSelection(.enabled)
                        .onTapGesture { UIPasteboard.general.string = config.uri }
                }
                .listStyle(.plain)
            }
        }
    }
}
