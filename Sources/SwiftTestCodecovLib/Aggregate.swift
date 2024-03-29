//
//  Aggregate.swift
//
//  Created by Mathew Polzin on 1/8/21.
//

import Foundation
import Regex

public func isDependencyPath(_ path: String, projectName: String? = nil) -> Bool {
    let projectDir: String
    if let projectName = projectName {
        projectDir = projectName
    } else {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        projectDir = cwd.lastPathComponent
    }
    let isLocalDependency = projectDir != "" && !path.contains(projectDir)
    return isLocalDependency || path.contains(".build/")
}

public func isExcludedPath(_ path: String, regex: Regex?) -> Bool {
    guard let regex else {
        return false
    }
    return regex.matches(path)
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

    /// A String-formatted coverage percentage, out to two decimal places.
    public var formattedOverallCoveragePercent: String {
        "\(String(format: "%.2f", overallCoveragePercent))%"
    }

    public init(
        coverage: CodeCov,
        property: CodeCov.AggregateProperty,
        includeDependencies: Bool,
        includeTests: Bool,
        excludeRegexString: String?,
        projectName: String? = nil
    ) throws {
        var coverage = coverage
        
        let regex = try Regex(string: excludeRegexString)

        if !includeTests {
            var nonTestDataSet = [CodeCov.Data]()
            for datum in coverage.data {
                let nonTestFiles = datum.files.filter({ file in
                    let inTestsFolder = file.filename.lowercased().contains("/tests/")
                    let isTestFile = file.filename.lowercased().contains("tests.swift")
                    return !inTestsFolder || !isTestFile
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
                let included = includeDependencies ? true : !isDependencyPath(filename, projectName: projectName)
                let notExcludedByRegex = !isExcludedPath(filename, regex: regex)
                return included && notExcludedByRegex
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

extension Regex {
    
    init?(string: String?) throws {
        guard let string else {
            return nil
        }
        try self.init(string: string)
    }
    
}
