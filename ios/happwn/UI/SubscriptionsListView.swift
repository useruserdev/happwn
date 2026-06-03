import SwiftUI

struct SubscriptionsListView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var coordinator: RefreshCoordinator
    @State private var showingAdd = false

    var body: some View {
        Group {
            if store.items.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Подписки")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) { AddSubscriptionView() }
    }

    private var list: some View {
        List {
            ForEach(store.items) { sub in
                NavigationLink {
                    SubscriptionDetailView(id: sub.id)
                } label: {
                    row(sub)
                }
            }
            .onDelete { store.remove(atOffsets: $0) }
        }
        .refreshable { await coordinator.refreshAll() }
    }

    private func row(_ sub: SavedSubscription) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(sub.hasUnseenUpdate ? Color.accentColor : .clear)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(sub.name).font(.body.weight(.semibold))
                Text("\(sub.configCount) конфигов · обновлено \(RelativeTime.string(sub.lastCheckedAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if sub.lastError != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.footnote)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)
            Text("Нет сохранённых подписок")
                .font(.headline)
            Text("Добавь happ://-ссылку, чтобы следить за обновлениями конфигов.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showingAdd = true
            } label: {
                Label("Добавить подписку", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .padding(40)
    }
}

/// Shared relative-time formatting for "обновлено N назад".
enum RelativeTime {
    private static let formatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.unitsStyle = .full
        return f
    }()

    static func string(_ date: Date?) -> String {
        guard let date else { return "никогда" }
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
