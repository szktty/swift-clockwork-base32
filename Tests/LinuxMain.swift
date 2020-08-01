import XCTest

import Base32Tests

var tests = [XCTestCaseEntry]()
tests += Base32Tests.allTests()
XCTMain(tests)
