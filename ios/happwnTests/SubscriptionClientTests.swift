import XCTest
@testable import happwn

private struct MockFetcher: HTTPFetching {
    var handler: (URLRequest) throws -> (Data, URLResponse)
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try handler(request)
    }
}

final class SubscriptionClientTests: XCTestCase {
    private func response(_ url: URL, _ code: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: nil)!
    }

    func testSendsUserAgentAndHwidHeaders() async throws {
        var seen: URLRequest?
        let client = SubscriptionClient(session: MockFetcher { req in
            seen = req
            return (Data("vless://x".utf8), self.response(req.url!, 200))
        })
        _ = try await client.fetch(urlString: "https://e.x/sub", userAgent: "Happ/1.2", hwid: "HW-9")
        XCTAssertEqual(seen?.value(forHTTPHeaderField: "User-Agent"), "Happ/1.2")
        XCTAssertEqual(seen?.value(forHTTPHeaderField: "X-HWID"), "HW-9")
    }

    func testRejectedStatusThrows() async {
        let client = SubscriptionClient(session: MockFetcher { req in
            (Data(), self.response(req.url!, 403))
        })
        do {
            _ = try await client.fetch(urlString: "https://e.x/sub", userAgent: "a", hwid: "b")
            XCTFail("expected rejection")
        } catch {
            guard case SubscriptionError.rejected(403) = error else {
                return XCTFail("wrong error: \(error)")
            }
        }
    }

    func testEmptyBodyThrows() async {
        let client = SubscriptionClient(session: MockFetcher { req in
            (Data(), self.response(req.url!, 200))
        })
        do {
            _ = try await client.fetch(urlString: "https://e.x/sub", userAgent: "a", hwid: "b")
            XCTFail("expected empty error")
        } catch {
            guard case SubscriptionError.empty = error else {
                return XCTFail("wrong error: \(error)")
            }
        }
    }
}
