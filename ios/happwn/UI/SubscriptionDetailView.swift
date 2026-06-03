import SwiftUI

struct SubscriptionDetailView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var coordinator: RefreshCoordinator
    @Environment(\.dismiss) private var dismiss

    let id: UUID

    private var sub: SavedSubscription? { store.items.first { $0.id == id } }

    var body: some View {
        Group {
            if let sub {
                content(sub)
            } else {
                Color.clear.onAppear { dismiss() }
            }
        }
        .navigationTitle(sub?.name ?? "Подписка")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.markSeen(id) }
    }

    private func content(_ sub: SavedSubscription) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                nameSection(sub)
                statusSection(sub)

                PrimaryButton(title: "Обновить", isLoading: coordinator.isRefreshing) {
                    Task { await coordinator.refreshAll() }
                }
                .disabled(coordinator.isRefreshing)

                if let source = sub.source, !source.isEmpty {
                    VStack(alignment: .leading, spacing: Layout.rowSpacing) {
                        SectionLabel("Источник подписки")
                        SourceCard(source: source)
                    }
                }

                if let error = sub.lastError {
                    GroupedCard {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                    }
                }

                if !sub.lastConfigs.isEmpty {
                    VStack(alignment: .leading, spacing: Layout.rowSpacing) {
                        SectionLabel(sub.mode.map { "Конфиги · \($0)" } ?? "Конфиги") {
                            ConfigsHeaderActions(mode: sub.mode ?? "", uris: sub.lastConfigs)
                        }
                        ConfigListCard(uris: sub.lastConfigs)
                    }
                }

                deleteButton
            }
            .padding(Layout.screenPadding)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func nameSection(_ sub: SavedSubscription) -> some View {
        VStack(alignment: .leading, spacing: Layout.rowSpacing) {
            SectionLabel("Название")
            GroupedCard {
                TextField("Название", text: nameBinding(sub))
                    .autocorrectionDisabled()
                    .padding(14)
            }
        }
    }

    private func statusSection(_ sub: SavedSubscription) -> some View {
        VStack(alignment: .leading, spacing: Layout.rowSpacing) {
            SectionLabel("Состояние")
            GroupedCard {
                infoRow("Проверено", RelativeTime.string(sub.lastCheckedAt))
                Divider().padding(.leading, 14)
                infoRow("Изменено", RelativeTime.string(sub.lastChangedAt))
                Divider().padding(.leading, 14)
                Toggle(isOn: notifyBinding(sub)) {
                    Text("Уведомлять об обновлениях")
                }
                .padding(14)
            }
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
        .padding(14)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            store.remove(id)
            dismiss()
        } label: {
            Label("Удалить подписку", systemImage: "trash")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
        }
        .buttonStyle(.bordered)
        .tint(.red)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func nameBinding(_ sub: SavedSubscription) -> Binding<String> {
        Binding(
            get: { store.items.first { $0.id == id }?.name ?? sub.name },
            set: { newValue in
                var s = sub
                s.name = newValue
                store.update(s)
            }
        )
    }

    private func notifyBinding(_ sub: SavedSubscription) -> Binding<Bool> {
        Binding(
            get: { store.items.first { $0.id == id }?.notify ?? sub.notify },
            set: { newValue in
                var s = sub
                s.notify = newValue
                store.update(s)
            }
        )
    }
}
