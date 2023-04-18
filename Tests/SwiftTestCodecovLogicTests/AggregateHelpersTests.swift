//
//  AggregateHelpersTests.swift
//  
//
//  Created by Eric DeLabar on 12/12/22.
//

import XCTest
@testable import SwiftTestCodecovLib
@testable import SwiftTestCodecovLogic

final class AggregateHelpersTests: XCTestCase {
    
    func testMinimalDisplay() throws {
        
        let aggregate = Aggregate(
            coveragePerFile: [:],
            totalCount: 100,
            overallCoverage: 0.50,
            coveredProperty: .lines
        )
        
        let aggregateWithDelta = Aggregate(
            coveragePerFile: [:],
            totalCount: 100,
            overallCoverage: 0.50,
            overallCoverageDelta: 0.25,
            coveredProperty: .lines
        )
        
        let aggregateWithNegativeDelta = Aggregate(
            coveragePerFile: [:],
            totalCount: 100,
            overallCoverage: 0.50,
            overallCoverageDelta: -0.25,
            coveredProperty: .lines
        )
        
        let aggregateWithNoDelta = Aggregate(
            coveragePerFile: [:],
            totalCount: 100,
            overallCoverage: 0.50,
            overallCoverageDelta: 0.0,
            coveredProperty: .lines
        )

        
        XCTAssertEqual(aggregate.minimalDisplay, "50.00%")
        XCTAssertEqual(aggregateWithDelta.minimalDisplay, "50.00% (+25.00%)")
        XCTAssertEqual(aggregateWithNegativeDelta.minimalDisplay, "50.00% (-25.00%)")
        XCTAssertEqual(aggregateWithNoDelta.minimalDisplay, "50.00% (0.00%)")
        
    }
    
    func testNumericDisplay() throws {
        
        let aggregate = Aggregate(
            coveragePerFile: [:],
            totalCount: 100,
            overallCoverage: 0.50,
            coveredProperty: .lines
        )
        
        let aggregateWithDelta = Aggregate(
            coveragePerFile: [:],
            totalCount: 100,
            overallCoverage: 0.50,
            overallCoverageDelta: 0.25,
            coveredProperty: .lines
        )
        
        let aggregateWithNegativeDelta = Aggregate(
            coveragePerFile: [:],
            totalCount: 100,
            overallCoverage: 0.50,
            overallCoverageDelta: -0.25,
            coveredProperty: .lines
        )
        
        let aggregateWithNoDelta = Aggregate(
            coveragePerFile: [:],
            totalCount: 100,
            overallCoverage: 0.50,
            overallCoverageDelta: 0.0,
            coveredProperty: .lines
        )
        
        XCTAssertEqual(aggregate.numericDisplay, 50.0)
        XCTAssertEqual(aggregateWithDelta.numericDisplay, 25.0)
        XCTAssertEqual(aggregateWithNegativeDelta.numericDisplay, -25.0)
        XCTAssertEqual(aggregateWithNoDelta.numericDisplay, 0.0)
        
    }

}
