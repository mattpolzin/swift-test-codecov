//
//  Aggregate.swift
//  
//
//  Created by Mathew Polzin on 1/8/21.
//

import Foundation

public func isDependencyPath(_ path: String) -> Bool {
    return path.contains(".build/")
}

public struct Aggregate: Encodable {
    /// The coverage data per-file.
    public let coveragePerFile: [String: CodeCov.File.Coverage]
    /// The total number of whatever aggregate property is chosen
    ///
    /// For example, the number of lines (in total, not with coverage).
    public let totalCount: Int
    /// Overall coverage -- a number between 0.0 and 1.0
    public let overallCoverage: Double

    /// Overall coverage -- a number between 0.0 and 100.0
    public var overallCoveragePercent: Double {
        overallCoverage * 100
    }

    public var formattedOverallCoveragePercent: String {
        "\(String(format: "%.2f", overallCoveragePercent))%"
    }

    public init(
        coverage: CodeCov,
        property: CodeCov.AggregateProperty,
        includeDependencies: Bool,
        includeTests: Bool
    ) {
        var coverage = coverage

        if !includeTests {
            var nonTestDataSet = [CodeCov.Data]()
            for datum in coverage.data {
                let nonTestFiles = datum.files.filter({ file in
                    !(file.filename.lowercased().contains("test"))
                })
                // If all files in this data instance were tests, ignore it altogether. Else add it to the array.
                if !nonTestFiles.isEmpty {
                    nonTestDataSet.append(CodeCov.Data(files: nonTestFiles))
                }
            }
            // Create a new CodeCov instance from the earlier one, minus the test files
            coverage = CodeCov(version: coverage.version, type: coverage.type, data: nonTestDataSet)
        }

        coveragePerFile = coverage
            .fileCoverages(for: property)
            .filter { filename, _ in
                includeDependencies ? true : !isDependencyPath(filename)
            }

        let total = coveragePerFile.reduce(0) { tot, next in
            tot + next.value.count
        }
        totalCount = total

        overallCoverage = coveragePerFile.reduce(0.0) { avg, next in
            avg + Double(next.value.covered) / Double(total)
        }
    }
}
