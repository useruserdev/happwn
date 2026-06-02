import Foundation

protocol HTTPFetching {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPFetching {}

enum SubscriptionError: Error, LocalizedError {
    case invalidURL
    case rejected(Int)
    case empty

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL подписки"
        case .rejected(let code):
            return "Сервер отклонил запрос (\(code)) — проверь User-Agent и X-HWID"
        case .empty:
            return "Сервер вернул пустой ответ"
        }
    }
}

struct SubscriptionClient {
    private let session: HTTPFetching

    init(session: HTTPFetching = URLSession.shared) {
        self.session = session
    }

    func fetch(urlString: String, userAgent: String, hwid: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw SubscriptionError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(hwid, forHTTPHeaderField: "X-HWID")

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SubscriptionError.rejected(http.statusCode)
        }
        if data.isEmpty { throw SubscriptionError.empty }
        return data
    }
}
