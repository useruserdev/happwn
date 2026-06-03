import SwiftUI
import UIKit

struct ExtractView: View {
    @EnvironmentObject private var settings: Settings
    @StateObject private var vm = ExtractionViewModel()
    @FocusState private var fieldFocused: Bool

    private var isLoading: Bool {
        if case .loading = vm.state { return true }
        return false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Вставь happ://-ссылку — расшифрую и достану конфиги")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)

                linkSection
                PrimaryButton(title: "Извлечь конфиги", isLoading: isLoading) {
                    fieldFocused = false
                    Task { await vm.extract(userAgent: settings.userAgent, hwid: settings.hwid) }
                }
                .disabled(vm.link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)

                content
            }
            .padding(Layout.screenPadding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("happwn")
    }

    private var linkSection: some View {
        VStack(alignment: .leading, spacing: Layout.rowSpacing) {
            SectionLabel("Ссылка")
            GroupedCard {
                TextField("happ://crypt…", text: $vm.link, axis: .vertical)
                    .font(.system(.callout, design: .monospaced))
                    .lineLimit(3...6)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($fieldFocused)
                    .padding(14)

                Divider()

                Button {
                    if let s = UIPasteboard.general.string { vm.link = s }
                } label: {
                    Label("Вставить из буфера", systemImage: "doc.on.clipboard")
                        .font(.callout.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                }
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch vm.state {
        case .idle:
            emptyState
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        case .success(let result):
            ResultsView(result: result)
        case .failure(let message):
            errorCard(message)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 44, weight: .light))
            Text("Результат появится здесь")
                .font(.subheadline)
        }
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    private func errorCard(_ message: String) -> some View {
        GroupedCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                Text(message)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
        }
    }
}
