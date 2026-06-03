import XCTest
@testable import happwn

private struct StubFetcher: HTTPFetching {
    var handler: (URLRequest) throws -> (Data, URLResponse)
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try handler(request)
    }
}

/// A plain http(s) subscription URL should skip decryption, fetch directly,
/// and parse configs.
final class PlainURLExtractionTests: XCTestCase {
    func testPlainURLSkipsDecryptionAndFetches() async throws {
        let body = "vless://uuid@host:443#A\nvmess://x"
        let service = ExtractionService(
            decryptLink: { _ in
                XCTFail("plain URL must not be decrypted")
                throw SubscriptionError.empty
            },
            client: SubscriptionClient(session: StubFetcher { req in
                XCTAssertEqual(req.url?.absoluteString, "https://sub.example/list")
                return (Data(body.utf8),
                        HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
            })
        )
        let result = try await service.run(link: "https://sub.example/list", userAgent: "u", hwid: "h")
        XCTAssertEqual(result.mode, "url")
        XCTAssertEqual(result.source, "https://sub.example/list")
        XCTAssertEqual(result.configs.count, 2)
        XCTAssertEqual(result.configs.first?.scheme, "vless")
    }
}
