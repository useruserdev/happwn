import Foundation

@MainActor
final class ExtractionViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case success(ExtractionResultView)
        case failure(String)
    }

    /// Equatable, view-friendly snapshot of an ExtractionResult.
    struct ExtractionResultView: Equatable {
        let mode: String
        let source: String
        let configs: [ConfigEntry]
        let rawBody: String?
    }

    @Published var link: String = ""
    @Published private(set) var state: State = .idle

    private let service: ExtractionService

    init(service: ExtractionService = ExtractionService()) {
        self.service = service
    }

    func extract(userAgent: String, hwid: String) async {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state = .loading
        do {
            let r = try await service.run(link: trimmed, userAgent: userAgent, hwid: hwid)
            state = .success(.init(mode: r.mode, source: r.source, configs: r.configs, rawBody: r.rawBody))
        } catch {
            state = .failure(error.localizedDescription)
        }
    }
}
