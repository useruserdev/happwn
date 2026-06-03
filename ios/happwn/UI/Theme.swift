import SwiftUI
import UIKit

// MARK: - Accent

/// Selectable global tint, persisted by id.
enum AppAccent: String, CaseIterable, Identifiable {
    case indigo, blue, teal, green, orange, pink, purple, red

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .indigo: return .indigo
        case .blue:   return .blue
        case .teal:   return .teal
        case .green:  return .green
        case .orange: return .orange
        case .pink:   return .pink
        case .purple: return .purple
        case .red:    return .red
        }
    }
}

// MARK: - Appearance

/// Light / dark / follow-system preference.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "Система"
        case .light:  return "Светлая"
        case .dark:   return "Тёмная"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - Protocol styling

/// Per-scheme colour + short badge for config rows.
enum ProtocolStyle {
    static func color(for scheme: String) -> Color {
        switch scheme.lowercased() {
        case "vless":                 return .green
        case "vmess":                 return .orange
        case "trojan":                return .pink
        case "ss", "ssr":             return .cyan
        case "hysteria", "hysteria2", "hy2": return .purple
        case "tuic":                  return .blue
        case "wireguard":             return .teal
        default:                      return .gray
        }
    }

    /// 1–2 char badge, e.g. "VL", "VM", "TR".
    static func badge(for scheme: String) -> String {
        switch scheme.lowercased() {
        case "vless":      return "VL"
        case "vmess":      return "VM"
        case "trojan":     return "TR"
        case "ss":         return "SS"
        case "ssr":        return "SR"
        case "hysteria", "hysteria2", "hy2": return "HY"
        case "tuic":       return "TU"
        case "wireguard":  return "WG"
        default:           return scheme.prefix(2).uppercased()
        }
    }
}

// MARK: - Layout tokens

enum Layout {
    static let cardRadius: CGFloat = 16
    static let rowSpacing: CGFloat = 10
    static let screenPadding: CGFloat = 16
}

// MARK: - Reusable components

/// Section label above a grouped card (uppercase, secondary).
struct SectionLabel: View {
    let title: String
    var trailing: AnyView? = nil

    init(_ title: String) {
        self.title = title
        self.trailing = nil
    }

    init<T: View>(_ title: String, @ViewBuilder trailing: () -> T) {
        self.title = title
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            Spacer()
            trailing
        }
        .padding(.horizontal, 6)
    }
}

/// Inset-grouped card container drawn on the grouped background.
struct GroupedCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
    }
}

/// Coloured rounded glyph used as a leading icon in cells.
struct IconBadge: View {
    let systemName: String
    let color: Color
    var text: String? = nil

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(color)
            .frame(width: 29, height: 29)
            .overlay {
                if let text {
                    Text(text)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: systemName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
    }
}

/// Prominent accent action button with an optional loading state.
struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isLoading ? 0 : 1)
                if isLoading { ProgressView().tint(.white) }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Haptics

enum Haptics {
    static func tap() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }
}
