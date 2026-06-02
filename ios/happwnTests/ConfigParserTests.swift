import XCTest
@testable import happwn

final class ConfigParserTests: XCTestCase {
    func testParsesPlainList() {
        let body = """
        vless://uuid@host:443?type=tcp#A
        vmess://abc
        not-a-config
        trojan://pass@host:443#B
        """
        let configs = ConfigParser.parse(Data(body.utf8))
        XCTAssertEqual(configs.map(\.uri), [
            "vless://uuid@host:443?type=tcp#A",
            "vmess://abc",
            "trojan://pass@host:443#B",
        ])
    }

    func testParsesBase64WrappedList() {
        let inner = "vless://uuid@host:443#A\ntrojan://pass@host:443#B"
        let body = Data(Data(inner.utf8).base64EncodedString().utf8)
        let configs = ConfigParser.parse(body)
        XCTAssertEqual(configs.count, 2)
        XCTAssertEqual(configs.first?.scheme, "vless")
    }

    func testReturnsEmptyWhenNothingRecognised() {
        XCTAssertTrue(ConfigParser.parse(Data("hello world".utf8)).isEmpty)
    }
}
