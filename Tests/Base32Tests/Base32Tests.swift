import XCTest
@testable import Base32

final class Base32Tests: XCTestCase {
    
    let vectors: [(String, String)] = [
        ("f", "CR"),
        ("foobar", "CSQPYRK1E8"),
        ("Hello, world!", "91JPRV3F5GG7EVVJDHJ22"),
        ("The quick brown fox jumps over the lazy dog.",
         "AHM6A83HENMP6TS0C9S6YXVE41K6YY10D9TPTW3K41QQCSBJ41T6GS90DHGQMY90CHQPEBG")
    ]
    
    func testExample() {
        for (encodeStr, decodeStr) in vectors {
            let encodeData = encodeStr.data(using: .ascii)!
            let decodeData = decodeStr.data(using: .ascii)!
            XCTAssertEqual(Base32.encode(encodeData), decodeData)
            XCTAssertEqual(Base32.decode(decodeData)!, encodeData)
        }
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
