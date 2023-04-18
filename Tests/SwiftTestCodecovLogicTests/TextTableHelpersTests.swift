//
//  TextTableHelpersTests.swift
//  
//
//  Created by Eric DeLabar on 12/12/22.
//

import XCTest
import TextTable
@testable import SwiftTestCodecovLib
@testable import SwiftTestCodecovLogic

final class ColumnExtensionsTests: XCTestCase {
    
    func testIncludeIf() throws {
        
        let cut = Column(title: "Title", value: "Value")
        
        XCTAssertNil(cut.includeIf(false))
        XCTAssertNotNil(cut.includeIf(true))
        
    }
    
}
