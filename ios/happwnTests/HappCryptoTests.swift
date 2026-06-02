import XCTest
@testable import happwn

final class HappCryptoTests: XCTestCase {
    private let crypt4 = "happ://crypt4/LOlGv0ZXi8lPDPNEPT4NjoA5GOck+iV4io1Rhmd8GS13HmQ0h7mHwylUdicX6/JFvXeAq/H/XoHbYNU1DT9pVaUjY82tmTqh42FkxZ5GzHmu45tobtPeM5fjabS3JcGTiNVO/a8YtBhpcnLFD/wZ7Ie3koAJlrWXUDmeDAxLsL649WLBE0JtN3Yehnsxh+0MG8BHSvUQDrxAW5X4A6JvRvGjZ2Nt/vvSuLQNrY8intgYlcATaDNhAcGZWIcXESe6sf8CGTbY5KIRmr2+uBERoDOvulDtHzeZxUxODoq3qPbVjURI5vUYm6o4p5KAaTDPQG2ZbJWA2uEsOogbaRCo9oxIkF/vMIBMd5IKy6KQd4Ug6KR0qqHByhcQtJc3CcPQnix7dDYLYEcnK0qP+eCYMtdLl4+o4eKPrmx5dPPdrKcp83SOvhYbm9g6MGlyqyCfh8IdO5zfGQB6MnjTzpRUKan32iFiuTBPDzFOL1aAyoA17/ZloRG+jVUYPNjqxczvUxPojruZkmA0I9FJFL/zgtE5FAUd7WBHTwBkSKHOEiPMePZfHizP+J22ZlSgSCnTOiwcyKYGiQLf7TbKsuUmqn29zidStjmMkKOEkjk21yuiD6QUDnZnGko79Jg67m3/hk4/km12ZOqH9V64T+p67/NqR0/KVIXA/jrvbtL4H2s="

    func testDecryptsCrypt4ToSubURL() throws {
        let result = try HappCrypto.decrypt(crypt4)
        XCTAssertEqual(result.mode, "crypt4")
        XCTAssertEqual(result.value, "https://premiumt.shop/sub/5ESXeShpoSc_mbKK")
    }

    func testInvalidLinkThrows() {
        XCTAssertThrowsError(try HappCrypto.decrypt("happ://nope/x"))
    }
}
