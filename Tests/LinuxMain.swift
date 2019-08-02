import XCTest

import swift_test_codecovTests

var tests = [XCTestCaseEntry]()
tests += swift_test_codecovTests.__allTests()

XCTMain(tests)
