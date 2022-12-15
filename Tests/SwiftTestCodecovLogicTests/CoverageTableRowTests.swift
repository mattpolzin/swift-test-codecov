//
//  CoverageTableRowTests.swift
//  
//
//  Created by Eric DeLabar on 12/12/22.
//

import XCTest
@testable import SwiftTestCodecovLib
@testable import SwiftTestCodecovLogic

final class CoverageTableRowTests: XCTestCase {

    func testCoverageDeltaString() throws {
        
        XCTAssertEqual(
            CoverageTableRow.testRow(delta: nil).coverageDeltaString,
            ""
        )

        XCTAssertEqual(
            CoverageTableRow.testRow(delta: .fileRemoved).coverageDeltaString,
            "(Removed)"
        )

        let exampleCoverageDelta = CodeCov.File.Coverage(count: 10, covered: 9)

        XCTAssertEqual(
            CoverageTableRow.testRow(delta: .fileAdded(newCoverage: exampleCoverageDelta)).coverageDeltaString,
            "90.00%"
        )

        XCTAssertEqual(
            CoverageTableRow.testRow(delta: .delta(coverageChange: exampleCoverageDelta)).coverageDeltaString,
            "+90.00%"
        )
        
        let exampleCoverageDeltaNoChange = CodeCov.File.Coverage(count: 10, covered: 0)
        
        XCTAssertEqual(
            CoverageTableRow.testRow(delta: .delta(coverageChange: exampleCoverageDeltaNoChange)).coverageDeltaString,
            "-"
        )
        
    }
    
    func testCoverageString() throws {
        
        XCTAssertEqual(
            CoverageTableRow.testRow(coverage: -1).coverageString,
            ""
        )
        
        XCTAssertEqual(
            CoverageTableRow.testRow(coverage: 0).coverageString,
            "0.00%"
        )
        
        XCTAssertEqual(
            CoverageTableRow.testRow(coverage: 90).coverageString,
            "90.00%"
        )
    }
    
    func testIsDependencyString() throws {
        
        XCTAssertEqual(
            CoverageTableRow.testRow(dependency: nil).isDependencyString,
            ""
        )
        
        XCTAssertEqual(
            CoverageTableRow.testRow(dependency: false).isDependencyString,
            ""
        )
        
        XCTAssertEqual(
            CoverageTableRow.testRow(dependency: true).isDependencyString,
            "✓"
        )
        
    }
    
    func testSplitOutTests() throws {
        
        let businessLogic = CoverageTableRow.testRow(filename: "BusinessLogic.swift")
        let businessLogicTests = CoverageTableRow.testRow(filename: "BusinessLogicTests.swift")
        let testHelper = CoverageTableRow.testRow(filename: "Tests/MockObject.swift")
        
        let cut: [CoverageTableRow] = [
            businessLogic,
            businessLogicTests,
            testHelper
        ]
        
        XCTAssertEqual(cut.splitOutTests(), [
            businessLogic,
            CoverageTableRow.blank,
            CoverageTableRow.divider,
            CoverageTableRow.blank,
            businessLogicTests,
            testHelper
        ])
        
    }
    
    func testSplitOutTests_Empty() throws {
        
        let cut: [CoverageTableRow] = []
        
        XCTAssertEqual(cut.splitOutTests(), [
            CoverageTableRow.blank,
            CoverageTableRow.divider,
            CoverageTableRow.blank
        ])
        
    }

}

final class AggregateExtensionTests: XCTestCase {
    
    static let testAggregate = Aggregate(
        coveragePerFile: [
            "C/C.swift": fileC100,
            "B/B.swift": fileB25,
            "A/A.swift": fileA50,
        ],
        totalCount: 7,
        overallCoverage: 3/7,
        coveredProperty: .lines
    )
    
    static let testAggregateWithDeltas = Aggregate(
        coveragePerFile: [
            "C/C.swift": fileC100,
            "B/B.swift": fileB25,
            "A/A.swift": fileA50,
        ],
        coverageDeltaPerFile: [
            "C/C.swift": fileC100Delta,
            "B/B.swift": fileB25Delta,
            "A/A.swift": fileA50Delta,
            "D/D.swift": CoverageDelta.fileRemoved
        ],
        totalCount: 7,
        totalCountDelta: 0,
        overallCoverage: 3/7,
        overallCoverageDelta: 3/7,
        coveredProperty: .lines
    )
    
    static let fileA50 = CodeCov.File.Coverage(count: 2, covered: 1)
    static let fileB25 = CodeCov.File.Coverage(count: 4, covered: 1)
    static let fileC100 = CodeCov.File.Coverage(count: 1, covered: 1)
    
    static let fileA50Delta = CodeCov.File.Coverage(count: 2, covered: 1).delta(CodeCov.File.Coverage(count: 2, covered: 0))
    static let fileB25Delta = CodeCov.File.Coverage(count: 4, covered: 1).delta(CodeCov.File.Coverage(count: 4, covered: 0))
    static let fileC100Delta = CodeCov.File.Coverage(count: 1, covered: 1).delta(CodeCov.File.Coverage(count: 1, covered: 0))
    
    func testAsTableData_Sort_FilenameOrder() throws {
        
        let result = Self.testAggregate.asTableData(
            includeDependencies: false,
            projectName: nil,
            sortOrder: .filename
        )
        
        XCTAssertEqual(result.map { $0.filename }, [
            "A.swift",
            "B.swift",
            "C.swift"
        ])
        
    }
    
    func testAsTableData_Sort_CoverageAscOrder() throws {
        
        let result = Self.testAggregate.asTableData(
            includeDependencies: false,
            projectName: nil,
            sortOrder: .coverageAsc
        )
        
        XCTAssertEqual(result.map { $0.filename }, [
            "B.swift",
            "A.swift",
            "C.swift"
        ])
        
    }
    
    func testAsTableData_Sort_CoverageDescOrder() throws {
        
        let result = Self.testAggregate.asTableData(
            includeDependencies: false,
            projectName: nil,
            sortOrder: .coverageDesc
        )
        
        XCTAssertEqual(result.map { $0.filename }, [
            "C.swift",
            "A.swift",
            "B.swift"
        ])
        
    }
    
    func testAsTableData_WithDeltas() throws {
        
        let result = Self.testAggregateWithDeltas.asTableData(
            includeDependencies: false,
            projectName: nil,
            sortOrder: .filename
        )
        
        XCTAssertEqual(result, [
            .testRow(filename: "A.swift", coverage: 50, delta: Self.fileA50Delta),
            .testRow(filename: "B.swift", coverage: 25, delta: Self.fileB25Delta),
            .testRow(filename: "C.swift", coverage: 100, delta: Self.fileC100Delta),
            .testRow(filename: "D.swift", coverage: -1, delta: .fileRemoved)
        ])
        
    }
    
    func testAsTableData_WithDependencies() throws {
        
        let result = Self.testAggregate.asTableData(
            includeDependencies: true,
            projectName: "A",
            sortOrder: .filename
        )
        
        XCTAssertEqual(result, [
            .testRow(dependency: false, filename: "A.swift", coverage: 50),
            .testRow(dependency: true, filename: "B.swift", coverage: 25),
            .testRow(dependency: true, filename: "C.swift", coverage: 100),
        ])
        
    }
    
    func testAsTableData_WithDependenciesAndDeltas() throws {
        
        let result = Self.testAggregateWithDeltas.asTableData(
            includeDependencies: true,
            projectName: "B",
            sortOrder: .filename
        )
        
        XCTAssertEqual(result, [
            .testRow(dependency: true, filename: "A.swift", coverage: 50, delta: Self.fileA50Delta),
            .testRow(dependency: false, filename: "B.swift", coverage: 25, delta: Self.fileB25Delta),
            .testRow(dependency: true, filename: "C.swift", coverage: 100, delta: Self.fileC100Delta),
            .testRow(dependency: true, filename: "D.swift", coverage: -1, delta: .fileRemoved),
        ])
        
    }
    
}
