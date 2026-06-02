import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: Settings
    @StateObject private var vm = ExtractionViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("happ://crypt…", text: $vm.link, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Button {
                    Task { await vm.extract(userAgent: settings.userAgent, hwid: settings.hwid) }
                } label: {
                    Text("Извлечь").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                content
                Spacer()
            }
            .padding()
            .navigationTitle("happwn")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch vm.state {
        case .idle:
            EmptyView()
        case .loading:
            ProgressView().padding()
        case .success(let result):
            ResultsView(result: result)
        case .failure(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
        }
    }
}
