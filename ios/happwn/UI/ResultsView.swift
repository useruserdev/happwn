import SwiftUI

struct ResultsView: View {
    let result: ExtractionViewModel.ExtractionResultView

    private var uris: [String] { result.configs.map(\.uri) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if !result.source.isEmpty {
                VStack(alignment: .leading, spacing: Layout.rowSpacing) {
                    SectionLabel("Источник подписки")
                    SourceCard(source: result.source)
                }
            }

            if let raw = result.rawBody {
                rawSection(raw)
            } else {
                VStack(alignment: .leading, spacing: Layout.rowSpacing) {
                    SectionLabel("Конфиги") {
                        ConfigsHeaderActions(mode: result.mode, uris: uris)
                    }
                    ConfigListCard(uris: uris)
                }
            }
        }
    }

    private func rawSection(_ raw: String) -> some View {
        VStack(alignment: .leading, spacing: Layout.rowSpacing) {
            SectionLabel("Сырой ответ")
            Text("Не удалось распознать конфиги — показываю ответ как есть.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
            GroupedCard {
                Text(raw)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }
        }
    }
}
