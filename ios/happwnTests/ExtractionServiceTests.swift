import XCTest
@testable import happwn

private struct MockFetcher: HTTPFetching {
    var handler: (URLRequest) throws -> (Data, URLResponse)
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try handler(request)
    }
}

final class ExtractionServiceTests: XCTestCase {
    func testDecryptThenFetchThenParse() async throws {
        let subList = "vless://uuid@host:443#A\ntrojan://p@host:443#B"
        let service = ExtractionService(
            decryptLink: { _ in DecryptResult(mode: "crypt4", value: "https://sub.example/x") },
            client: SubscriptionClient(session: MockFetcher { req in
                XCTAssertEqual(req.url?.absoluteString, "https://sub.example/x")
                return (Data(subList.utf8),
                        HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
            })
        )
        let result = try await service.run(link: "happ://crypt4/x", userAgent: "Happ/1", hwid: "HW")
        XCTAssertEqual(result.mode, "crypt4")
        XCTAssertEqual(result.configs.count, 2)
        XCTAssertNil(result.rawBody)
    }

    func testInlineConfigsSkipFetch() async throws {
        let service = ExtractionService(
            decryptLink: { _ in DecryptResult(mode: "crypt", value: "vless://uuid@host:443#A") },
            client: SubscriptionClient(session: MockFetcher { _ in
                XCTFail("should not fetch for inline config")
                throw SubscriptionError.empty
            })
        )
        let result = try await service.run(link: "happ://crypt/x", userAgent: "a", hwid: "b")
        XCTAssertEqual(result.configs.first?.scheme, "vless")
    }
}
