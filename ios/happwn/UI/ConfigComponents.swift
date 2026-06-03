import SwiftUI
import UIKit

/// Card showing a decrypted subscription source URL with a copy button.
struct SourceCard: View {
    let source: String
    @State private var copied = false

    var body: some View {
        GroupedCard {
            HStack(spacing: 12) {
                IconBadge(systemName: "link", color: .accentColor)
                Text(source)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(2)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    UIPasteboard.general.string = source
                    Haptics.tap()
                    copied = true
                    Task {
                        try? await Task.sleep(nanoseconds: 1_400_000_000)
                        copied = false
                    }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .foregroundStyle(copied ? Color.green : Color.accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
        }
    }
}

/// Inset-grouped list of config URIs with per-protocol icons and tap-to-copy.
struct ConfigListCard: View {
    let uris: [String]
    @State private var copiedIndex: Int?

    var body: some View {
        GroupedCard {
            ForEach(Array(uris.enumerated()), id: \.offset) { index, uri in
                if index > 0 {
                    Divider().padding(.leading, 55)
                }
                row(index: index, uri: uri)
            }
        }
    }

    private func row(index: Int, uri: String) -> some View {
        let scheme = ConfigEntry(uri: uri).scheme
        return Button {
            UIPasteboard.general.string = uri
            Haptics.tap()
            copiedIndex = index
            Task {
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                if copiedIndex == index { copiedIndex = nil }
            }
        } label: {
            HStack(spacing: 12) {
                IconBadge(systemName: "",
                          color: ProtocolStyle.color(for: scheme),
                          text: ProtocolStyle.badge(for: scheme))
                Text(uri)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: copiedIndex == index ? "checkmark" : "doc.on.doc")
                    .font(.footnote)
                    .foregroundStyle(copiedIndex == index ? Color.green : Color.secondary)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Accent pill showing the crypt mode and config count, plus copy-all / share.
struct ConfigsHeaderActions: View {
    let mode: String
    let uris: [String]

    private var joined: String { uris.joined(separator: "\n") }

    var body: some View {
        HStack(spacing: 14) {
            Text("\(mode) · \(uris.count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.14), in: Capsule())
            if !uris.isEmpty {
                Button {
                    UIPasteboard.general.string = joined
                    Haptics.tap()
                } label: {
                    Text("Копировать всё").font(.caption.weight(.semibold))
                }
                ShareLink(item: joined) {
                    Image(systemName: "square.and.arrow.up").font(.caption)
                }
            }
        }
    }
}
