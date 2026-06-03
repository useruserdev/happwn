import SwiftUI
import UIKit

struct ResultsView: View {
    let result: ExtractionViewModel.ExtractionResultView

    @State private var copiedID: UUID?
    @State private var sourceCopied = false

    private var allConfigs: String {
        result.configs.map(\.uri).joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if !result.source.isEmpty {
                sourceSection
            }

            if let raw = result.rawBody {
                rawSection(raw)
            } else {
                configsSection
            }
        }
    }

    // MARK: Source

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: Layout.rowSpacing) {
            SectionLabel("Источник подписки")
            GroupedCard {
                HStack(spacing: 12) {
                    IconBadge(systemName: "link", color: .accentColor)
                    Text(result.source)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        UIPasteboard.general.string = result.source
                        Haptics.tap()
                        sourceCopied = true
                        resetSourceCopied()
                    } label: {
                        Image(systemName: sourceCopied ? "checkmark" : "doc.on.doc")
                            .foregroundStyle(sourceCopied ? Color.green : Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
            }
        }
    }

    // MARK: Configs

    private var configsSection: some View {
        VStack(alignment: .leading, spacing: Layout.rowSpacing) {
            SectionLabel("Конфиги") {
                HStack(spacing: 14) {
                    Text("\(result.mode) · \(result.configs.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.14), in: Capsule())
                    if !result.configs.isEmpty {
                        Button {
                            UIPasteboard.general.string = allConfigs
                            Haptics.tap()
                        } label: {
                            Text("Копировать всё").font(.caption.weight(.semibold))
                        }
                        ShareLink(item: allConfigs) {
                            Image(systemName: "square.and.arrow.up").font(.caption)
                        }
                    }
                }
            }

            GroupedCard {
                ForEach(Array(result.configs.enumerated()), id: \.element.id) { index, config in
                    if index > 0 {
                        Divider().padding(.leading, 55)
                    }
                    configRow(config)
                }
            }
        }
    }

    private func configRow(_ config: ConfigEntry) -> some View {
        Button {
            UIPasteboard.general.string = config.uri
            Haptics.tap()
            copiedID = config.id
            resetCopied(config.id)
        } label: {
            HStack(spacing: 12) {
                IconBadge(
                    systemName: "",
                    color: ProtocolStyle.color(for: config.scheme),
                    text: ProtocolStyle.badge(for: config.scheme)
                )
                Text(config.uri)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: copiedID == config.id ? "checkmark" : "doc.on.doc")
                    .font(.footnote)
                    .foregroundStyle(copiedID == config.id ? Color.green : Color.secondary)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Raw fallback

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

    // MARK: Transient copy feedback

    private func resetCopied(_ id: UUID) {
        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            if copiedID == id { copiedID = nil }
        }
    }

    private func resetSourceCopied() {
        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            sourceCopied = false
        }
    }
}
