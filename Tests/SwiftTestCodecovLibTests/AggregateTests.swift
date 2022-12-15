//
//  AggregateTests.swift
//  
//
//  Created by Eric DeLabar on 12/9/22.
//

import XCTest
import Regex
@testable import SwiftTestCodecovLib

final class AggregateTests: XCTestCase {

    func testIsExcludedPath() throws {
        
        let helpExampleRegex = Regex("Mock\\.swift|View\\.swift")
        
        XCTAssertFalse(isExcludedPath(".build/Sources/Project/MyModel.swift", regex: helpExampleRegex))
        XCTAssertFalse(isExcludedPath(".build/Sources/Project/View/ViewName.swift", regex: helpExampleRegex))
        XCTAssertFalse(isExcludedPath(".build/Sources/Project/Mock/MockName.swift", regex: helpExampleRegex))
        XCTAssertTrue(isExcludedPath(".build/Sources/Project/MyView.swift", regex: helpExampleRegex))
        XCTAssertTrue(isExcludedPath(".build/Sources/Project/MyMock.swift", regex: helpExampleRegex))
    }

}
