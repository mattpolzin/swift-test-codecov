//
//  AggregateTests.swift
//  
//
//  Created by Eric DeLabar on 12/9/22.
//

import XCTest
import Regex
@testable import SwiftTestCodecovLib

final class AggregateHelperFunctionTests: XCTestCase {

    func testIsExcludedPath() throws {
        
        let helpExampleRegex = Regex("Mock\\.swift|View\\.swift")
        
        XCTAssertFalse(isExcludedPath(".build/Sources/Project/MyModel.swift", regex: helpExampleRegex))
        XCTAssertFalse(isExcludedPath(".build/Sources/Project/View/ViewName.swift", regex: helpExampleRegex))
        XCTAssertFalse(isExcludedPath(".build/Sources/Project/Mock/MockName.swift", regex: helpExampleRegex))
        XCTAssertTrue(isExcludedPath(".build/Sources/Project/MyView.swift", regex: helpExampleRegex))
        XCTAssertTrue(isExcludedPath(".build/Sources/Project/MyMock.swift", regex: helpExampleRegex))
    }
    
    func testIsExcludedPath_NoRegex() throws {
        
        XCTAssertFalse(isExcludedPath(".build/Sources/Project/MyModel.swift", regex: nil))
        XCTAssertFalse(isExcludedPath(".build/Sources/Project/View/ViewName.swift", regex: nil))
        XCTAssertFalse(isExcludedPath(".build/Sources/Project/Mock/MockName.swift", regex: nil))
        XCTAssertFalse(isExcludedPath(".build/Sources/Project/MyView.swift", regex: nil))
        XCTAssertFalse(isExcludedPath(".build/Sources/Project/MyMock.swift", regex: nil))
    }

}

final class AggregateTests: XCTestCase {
    
    func testInit_BaseWithDifferentCoveredProperty() throws {
        
        let base = try Aggregate(
            coverage: CodeCov(version: "", type: "", data: []),
            property: .functions,
            includeDependencies: false,
            includeTests: false,
            excludeRegexString: nil,
            fromBase: nil
        )
        
        do {
            _ = try Aggregate(
                coverage: CodeCov(version: "", type: "", data: []),
                property: .lines,
                includeDependencies: false,
                includeTests: false,
                excludeRegexString: nil,
                fromBase: base
            )
            XCTFail("Aggregate contructor should have thrown")
        } catch {
            if let error = error as? AggregateError {
                XCTAssertEqual(error, .invalidBaseAggregate("functions"))
            } else {
                XCTFail("Invalid AggregateError type")
            }
        }
        
    }
    
    func testOverallCoveragePercent() throws {
        
        let cut = Aggregate(
            coveragePerFile: [:],
            totalCount: 1000,
            overallCoverage: 0.95,
            coveredProperty: .lines
        )
        
        XCTAssertEqual(cut.overallCoveragePercent, 95, accuracy: 0.01)
        
    }
    
    func testOverallCoveragePercentDelta() throws {
        
        let cut = Aggregate(
            coveragePerFile: [:],
            totalCount: 1000,
            overallCoverage: 0.95,
            overallCoverageDelta: 0.10,
            coveredProperty: .lines
        )
        
        XCTAssertEqual(cut.overallCoveragePercentDelta!, 10, accuracy: 0.01)
        
    }
    
    func testOverallCoveragePercentDelta_NoBase() throws {
        
        let cut = try! Aggregate(
            coverage: CodeCov(version: "", type: "", data: []),
            property: .lines,
            includeDependencies: false,
            includeTests: false,
            excludeRegexString: nil,
            fromBase: nil
        )
        
        XCTAssertNil(cut.overallCoveragePercentDelta)
        
    }
    
    func testFormattedOverallCoveragePercent() throws {
        
        let cut = Aggregate(
            coveragePerFile: [:],
            totalCount: 1000,
            overallCoverage: 0.95,
            overallCoverageDelta: 0.10,
            coveredProperty: .lines
        )
        
        XCTAssertEqual(cut.formattedOverallCoveragePercent, "95.00%")
        
    }
    
    func testFormattedOverallCoveragePercentDelta() throws {
        
        let cut = Aggregate(
            coveragePerFile: [:],
            totalCount: 1000,
            overallCoverage: 0.95,
            overallCoverageDelta: 0.10,
            coveredProperty: .lines
        )
        
        XCTAssertEqual(cut.formattedOverallCoveragePercentDelta!, "+10.00%")
        
    }
    
    func testFormattedOverallCoveragePercentDelta_NoBase() throws {
        
        let cut = try! Aggregate(
            coverage: CodeCov(version: "", type: "", data: []),
            property: .lines,
            includeDependencies: false,
            includeTests: false,
            excludeRegexString: nil,
            fromBase: nil
        )
        
        XCTAssertNil(cut.formattedOverallCoveragePercentDelta)
        
    }
    
    func testCoverageDecreased() throws {
        
        let increase = Aggregate(
            coveragePerFile: [:],
            totalCount: 1000,
            overallCoverage: 0.95,
            overallCoverageDelta: 0.10,
            coveredProperty: .lines
        )
        
        XCTAssertFalse(increase.coverageDecreased)
        
        let decrease = Aggregate(
            coveragePerFile: [:],
            totalCount: 1000,
            overallCoverage: 0.95,
            overallCoverageDelta: -0.10,
            coveredProperty: .lines
        )
        
        XCTAssertTrue(decrease.coverageDecreased)
        
        let noChange = Aggregate(
            coveragePerFile: [:],
            totalCount: 1000,
            overallCoverage: 0.95,
            overallCoverageDelta: 0,
            coveredProperty: .lines
        )
        
        XCTAssertFalse(noChange.coverageDecreased)
        
    }
    
    func testCoverageDecreased_NoBase() throws {
        
        let noBase = Aggregate(
            coveragePerFile: [:],
            totalCount: 1000,
            overallCoverage: 0.95,
            coveredProperty: .lines
        )
        
        XCTAssertFalse(noBase.coverageDecreased)
        
    }
    
    func testHasDeltas() throws {
        
        XCTAssertFalse(Aggregate(
            coveragePerFile: [:],
            totalCount: 10,
            totalCountDelta: 1,
            overallCoverage: 1.0,
            overallCoverageDelta: 0.1,
            coveredProperty: .functions
        ).hasDeltas)
        
        XCTAssertFalse(Aggregate(
            coveragePerFile: [:],
            coverageDeltaPerFile: [:],
            totalCount: 10,
            overallCoverage: 1.0,
            overallCoverageDelta: 0.1,
            coveredProperty: .functions
        ).hasDeltas)
        
        XCTAssertFalse(Aggregate(
            coveragePerFile: [:],
            coverageDeltaPerFile: [:],
            totalCount: 10,
            totalCountDelta: 1,
            overallCoverage: 1.0,
            coveredProperty: .functions
        ).hasDeltas)
        
        XCTAssertTrue(Aggregate(
            coveragePerFile: [:],
            coverageDeltaPerFile: [:],
            totalCount: 10,
            totalCountDelta: 1,
            overallCoverage: 1.0,
            overallCoverageDelta: 0.1,
            coveredProperty: .functions
        ).hasDeltas)
        
    }
    
    func testHasDeltas_NoBase() throws {
        
        let noBase = Aggregate(
            coveragePerFile: [:],
            totalCount: 1000,
            overallCoverage: 0.95,
            coveredProperty: .lines
        )
        
        XCTAssertFalse(noBase.hasDeltas)
        
    }
    
}

final class String_CodeCovFileCoverage_Dictionary_ExtensionTests: XCTestCase {
    
    func testEmptyDelta() throws {
        
        let cut = [String: CodeCov.File.Coverage]()
        let base = [String: CodeCov.File.Coverage]()
        
        let delta = cut.delta(base)
        
        XCTAssertTrue(delta.isEmpty)
        
    }
    
    func testAddDelta() throws {
        
        let cut = [
            "Filename.swift": CodeCov.File.Coverage(
                count: 10,
                covered: 9,
                percent: 0.9
            )
        ]
        let base = [String: CodeCov.File.Coverage]()
        
        let delta = cut.delta(base)
        
        XCTAssertEqual(delta, [
            "Filename.swift": .fileAdded(newCoverage:
                CodeCov.File.Coverage(
                    count: 10,
                    covered: 9,
                    percent: 0.9
                )
            )
        ])
        
    }
    
    func testRemoveDelta() throws {
        
        let cut = [String: CodeCov.File.Coverage]()
        let base = [
            "Filename.swift": CodeCov.File.Coverage(
                count: 10,
                covered: 9,
                percent: 0.9
            )
        ]
        
        let delta = cut.delta(base)
        
        XCTAssertEqual(delta, [
            "Filename.swift": .fileRemoved
        ])
        
    }
    
    func testNoChangeDelta() throws {
        
        let cut = [
            "Filename.swift": CodeCov.File.Coverage(
                count: 10,
                covered: 9,
                percent: 0.9
            )
        ]
        let base = [
            "Filename.swift": CodeCov.File.Coverage(
                count: 10,
                covered: 9,
                percent: 0.9
            )
        ]
        
        let delta = cut.delta(base)
        
        XCTAssertEqual(delta, [
            "Filename.swift": .noChange
        ])
        
    }
    
    func testNoPercentageChangeDelta() throws {
        
        let cut = [
            "Filename.swift": CodeCov.File.Coverage(
                count: 100,
                covered: 90,
                percent: 0.9
            )
        ]
        let base = [
            "Filename.swift": CodeCov.File.Coverage(
                count: 10,
                covered: 9,
                percent: 0.9
            )
        ]
        
        let delta = cut.delta(base)
        
        XCTAssertEqual(delta, [
            "Filename.swift": .delta(coverageChange:
                CodeCov.File.Coverage(
                    count: 90,
                    covered: 81,
                    percent: 0.0
                )
            )
        ])
        
    }
    
    func testAllDelta() throws {
        
        let cut = [
            "FilenameAdded.swift": CodeCov.File.Coverage(
                count: 100,
                covered: 90,
                percent: 0.9
            ),
            "Filename.swift": CodeCov.File.Coverage(
                count: 10,
                covered: 9,
                percent: 0.9
            )
        ]
        let base = [
            "Filename.swift": CodeCov.File.Coverage(
                count: 10,
                covered: 9,
                percent: 0.9
            ),
            "FilenameRemoved.swift": CodeCov.File.Coverage(
                count: 10,
                covered: 9,
                percent: 0.9
            )
        ]
        
        let delta = cut.delta(base)
        
        XCTAssertEqual(delta, [
            "FilenameAdded.swift": .fileAdded(newCoverage:
                CodeCov.File.Coverage(
                    count: 100,
                    covered: 90,
                    percent: 0.9
                )
            ),
            "Filename.swift": .noChange,
            "FilenameRemoved.swift": .fileRemoved,
        ])
        
    }
    
}

final class CodeCovFileCoverageExtensionTests: XCTestCase {
    
    func testDelta_Added() throws {
        
        let cut = CodeCov.File.Coverage(
            count: 100,
            covered: 75,
            percent: 0.75
        )
        
        let result = cut.delta(nil)
        
        XCTAssertEqual(result, .fileAdded(newCoverage:
            CodeCov.File.Coverage(
                count: 100,
                covered: 75,
                percent: 0.75
            )
        ))
        
    }
    
    func testDelta_Equal() throws {
        
        let cut = CodeCov.File.Coverage(
            count: 100,
            covered: 75,
            percent: 0.75
        )
        
        let base = CodeCov.File.Coverage(
            count: 100,
            covered: 75,
            percent: 0.75
        )
        
        let result = cut.delta(base)
        
        XCTAssertEqual(result, .noChange)
        
    }
    
    func testDelta_Lower() throws {
        
        let cut = CodeCov.File.Coverage(
            count: 100,
            covered: 75,
            percent: 0.75
        )
        
        let base = CodeCov.File.Coverage(
            count: 110,
            covered: 109,
            percent: 0.99
        )
        
        let result = cut.delta(base)
        
        switch result {
        case .delta(let coverageDelta):
            XCTAssertEqual(coverageDelta.count, -10)
            XCTAssertEqual(coverageDelta.covered, -34)
            XCTAssertEqual(coverageDelta.percent, -0.24, accuracy: 0.01)
        default:
            XCTFail("Incorrect Result")
        }
        
    }
    
    func testDelta_Higher() throws {
        
        let cut = CodeCov.File.Coverage(
            count: 110,
            covered: 109,
            percent: 0.99
        )
        
        let base = CodeCov.File.Coverage(
            count: 100,
            covered: 75,
            percent: 0.75
        )
        
        let result = cut.delta(base)
        
        switch result {
        case .delta(let coverageDelta):
            XCTAssertEqual(coverageDelta.count, 10)
            XCTAssertEqual(coverageDelta.covered, 34)
            XCTAssertEqual(coverageDelta.percent, 0.24, accuracy: 0.01)
        default:
            XCTFail("Incorrect Result")
        }
        
    }
    
}

final class DoublePercentExtensionTests: XCTestCase {

    func testSign() throws {
        
        XCTAssertEqual((1.0).sign, "+")
        XCTAssertEqual((0.0).sign, "")
        XCTAssertEqual((-1.0).sign, "") // Negative is provided natively by double string formatting
        
    }
    
    func testAsPercent() throws {
        
        let cut = 0.25
        
        XCTAssertEqual(cut.asPercent, 25, accuracy: 0.01)
        
    }
    
    func testAsPercentToTwoPlaces() throws {
        
        let cut = 0.25
        
        XCTAssertEqual(cut.asPercentToTwoPlaces, "25.00%")
        
    }
    
    func testToTwoPlaces() throws {
        
        let cut = 0.25
        
        XCTAssertEqual(cut.toTwoPlaces, "0.25")
        
    }
    
    func testToTwoPlacesWithSign() throws {
        
        XCTAssertEqual((0.25).toTwoPlacesWithSign, "+0.25")
        XCTAssertEqual((0.0).toTwoPlacesWithSign, "0.00")
        XCTAssertEqual((-0.25).toTwoPlacesWithSign, "-0.25")
        
    }
    
}

final class RegexExtensionTests: XCTestCase {
    
    func testInit() throws {
        let cut = try Regex(optionalString: "Test\\.swift")
        XCTAssertNotNil(cut)
    }
    
    func testInit_NilString() throws {
        let cut = try Regex(optionalString: nil)
        XCTAssertNil(cut)
    }
    
    func testInit_InvalidRegex() throws {
        var didThrow = false
        do {
            _ = try Regex(optionalString: "++")
            XCTFail("Regex should throw...")
        } catch {
            didThrow = true
        }
        XCTAssertTrue(didThrow)
    }
    
}
