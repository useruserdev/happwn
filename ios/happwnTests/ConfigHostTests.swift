import XCTest
@testable import happwn

final class ConfigHostTests: XCTestCase {
    func testVlessIP() {
        XCTAssertEqual(ConfigEntry(uri: "vless://uuid@1.2.3.4:443?type=tcp&security=reality#name").host, "1.2.3.4")
    }

    func testTrojanDomain() {
        XCTAssertEqual(ConfigEntry(uri: "trojan://pass@example.com:8443?sni=a.b#tag").host, "example.com")
    }

    func testSSWithUserinfo() {
        XCTAssertEqual(ConfigEntry(uri: "ss://YWVzOnB3@9.9.9.9:8388#node").host, "9.9.9.9")
    }

    func testIPv6Literal() {
        XCTAssertEqual(ConfigEntry(uri: "vless://uuid@[2001:db8::1]:443#y").host, "2001:db8::1")
    }

    func testVmessBase64() {
        let json = "{\"add\":\"5.6.7.8\",\"port\":\"443\",\"id\":\"uuid\"}"
        let b64 = Data(json.utf8).base64EncodedString()
        XCTAssertEqual(ConfigEntry(uri: "vmess://\(b64)").host, "5.6.7.8")
    }

    func testNoHost() {
        XCTAssertNil(ConfigEntry(uri: "not-a-uri").host)
    }
}
