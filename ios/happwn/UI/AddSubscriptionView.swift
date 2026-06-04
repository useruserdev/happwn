import SwiftUI
import UIKit

struct AddSubscriptionView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var settings: Settings
    @Environment(\.dismiss) private var dismiss

    @State private var link = ""
    @State private var name = ""
    @State private var isSaving = false
    @State private var error: String?

    private var canSave: Bool {
        !link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("happ://… или https://…", text: $link, axis: .vertical)
                        .font(.system(.callout, design: .monospaced))
                        .lineLimit(2...5)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button {
                        if let s = UIPasteboard.general.string { link = s }
                    } label: {
                        Label("Вставить из буфера", systemImage: "doc.on.clipboard")
                    }
                } header: {
                    Text("Ссылка")
                } footer: {
                    Text("happ://-ссылка или обычный URL подписки. happwn вытащит конфиги и сообщит, когда они изменятся.")
                }

                Section("Название (необязательно)") {
                    TextField("например, мой провайдер", text: $name)
                        .autocorrectionDisabled()
                }

                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("Новая подписка")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDoneButton()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Сохранить") { save() }
                            .disabled(!canSave)
                    }
                }
            }
        }
    }

    private func save() {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        error = nil
        isSaving = true
        Task {
            do {
                let result = try await ExtractionService().run(
                    link: trimmed, userAgent: settings.userAgent, hwid: settings.hwid)
                let now = Date()
                let chosenName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let sub = SavedSubscription(
                    name: chosenName.isEmpty ? SavedSubscription.defaultName(from: result.source) : chosenName,
                    link: trimmed,
                    lastConfigs: result.configs.map(\.uri),
                    mode: result.mode,
                    source: result.source,
                    lastCheckedAt: now,
                    lastChangedAt: now
                )
                store.add(sub)
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            isSaving = false
        }
    }
}
