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
        includeDependencies: Bool
    ) {
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
