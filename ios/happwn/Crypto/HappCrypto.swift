import Foundation

struct DecryptResult: Equatable {
    let mode: String
    let value: String
}

enum HappCryptoError: Error, LocalizedError {
    case nullResult
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .nullResult:
            return "Внутренняя ошибка дешифровки"
        case .failed(let m):
            return m.isEmpty ? "Не удалось расшифровать ссылку" : m
        }
    }
}

enum HappCrypto {
    private struct Envelope: Decodable {
        let ok: Bool
        let mode: String?
        let value: String?
        let error: String?
    }

    static func decrypt(_ link: String) throws -> DecryptResult {
        guard let ptr = happwn_decrypt(link) else { throw HappCryptoError.nullResult }
        defer { happwn_free(ptr) }
        let json = String(cString: ptr)
        let env = try JSONDecoder().decode(Envelope.self, from: Data(json.utf8))
        if env.ok, let mode = env.mode, let value = env.value {
            return DecryptResult(mode: mode, value: value)
        }
        throw HappCryptoError.failed(env.error ?? "")
    }
}
