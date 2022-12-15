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

public enum CoverageDelta: Codable, Equatable {
    case fileAdded(newCoverage: CodeCov.File.Coverage)
    case fileRemoved
    case delta(coverageChange: CodeCov.File.Coverage)
}

public enum AggregateError: Error, Equatable {
    case invalidBaseAggregate(String)
}

public struct Aggregate: Codable {
    
    /// The coverage data per-file.
    public let coveragePerFile: [String: CodeCov.File.Coverage]
    /// The coverage delta per-file if a difference Aggregate is provided during initialization.
    public let coverageDeltaPerFile: [String: CoverageDelta]?
    
    /// The total number of whatever aggregate property is chosen
    ///
    /// For example, the number of lines (in total, not with coverage).
    public let totalCount: Int
    /// The difference between this and a different Aggregate provided on initialization.
    public let totalCountDelta: Int?
    
    /// Overall coverage -- a number between 0.0 and 1.0
    public let overallCoverage: Double
    /// The difference in overallCoverage between this and a different Aggregate provided on initialization.
    public let overallCoverageDelta: Double?
    
    private let _coveredProperty: CodeCov.AggregateProperty?
    
    /// The aggregate property that this struct is built on
    public var coveredProperty: CodeCov.AggregateProperty { _coveredProperty ?? .lines }
    
    enum CodingKeys: String, CodingKey {
        case coveragePerFile
        case coverageDeltaPerFile
        case totalCount
        case totalCountDelta
        case overallCoverage
        case overallCoverageDelta
        case _coveredProperty = "coveredProperty"
    }
    
    public init(
        coverage: CodeCov,
        property: CodeCov.AggregateProperty,
        includeDependencies: Bool,
        includeTests: Bool,
        excludeRegexString: String?,
        projectName: String? = nil,
        fromBase base: Aggregate?
    ) throws {
        var coverage = coverage
        
        let regex = try Regex(optionalString: excludeRegexString)

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
        
        _coveredProperty = property
        
        if let base {
            guard property == base.coveredProperty else {
                throw AggregateError.invalidBaseAggregate(base.coveredProperty.rawValue)
            }
            coverageDeltaPerFile = coveragePerFile.delta(base.coveragePerFile)
            totalCountDelta = totalCount - base.totalCount
            overallCoverageDelta = overallCoverage - base.overallCoverage
        } else {
            coverageDeltaPerFile = nil
            totalCountDelta = nil
            overallCoverageDelta = nil
        }
    }
}

extension Aggregate {
    
    internal init(
        coveragePerFile: [String : CodeCov.File.Coverage],
        coverageDeltaPerFile: [String : CoverageDelta]? = nil,
        totalCount: Int,
        totalCountDelta: Int? = nil,
        overallCoverage: Double,
        overallCoverageDelta: Double? = nil,
        coveredProperty: CodeCov.AggregateProperty
    ) {
        self.coveragePerFile = coveragePerFile
        self.coverageDeltaPerFile = coverageDeltaPerFile
        self.totalCount = totalCount
        self.totalCountDelta = totalCountDelta
        self.overallCoverage = overallCoverage
        self.overallCoverageDelta = overallCoverageDelta
        self._coveredProperty = coveredProperty
    }
    
}

extension Aggregate {
    
    /// Overall coverage -- a number between 0.0 and 100.0
    public var overallCoveragePercent: Double {
        overallCoverage.asPercent
    }
    
    /// Overall coverage -- a number between 0.0 and 100.0
    public var overallCoveragePercentDelta: Double? {
        guard let overallCoverageDelta else {
            return nil
        }
        return overallCoverageDelta.asPercent
    }

    /// A String-formatted coverage percentage, out to two decimal places.
    public var formattedOverallCoveragePercent: String {
        "\(overallCoverage.asPercentToTwoPlaces)"
    }
    
    /// A String-formatted coverage percentage, out to two decimal places.
    public var formattedOverallCoveragePercentDelta: String? {
        guard let overallCoverageDelta else {
            return nil
        }
        return "\(overallCoverageDelta.asPercent.toTwoPlacesWithSign)%"
    }
    
    public var coverageDecreased: Bool {
        overallCoverageDelta ?? 0 < 0
    }
    
    public var hasDeltas: Bool {
        coverageDeltaPerFile != nil && totalCountDelta != nil && overallCoverageDelta != nil
    }
    
}

extension [String: CodeCov.File.Coverage] {
    
    func delta(_ base: [String: CodeCov.File.Coverage]) -> [String: CoverageDelta] {
        let baseKeys = Set(base.keys)
        let currentKeys = Set(keys)
        
        let removedFiles = baseKeys.subtracting(currentKeys)
        
        let result = removedFiles.reduce([String: CoverageDelta]()) { partialResult, removedFile in
            var result = partialResult
            result[removedFile] = .fileRemoved
            return result
        }
        
        return reduce(result) { partialResult, element in
            var result = partialResult
            result[element.key] = element.value.delta(base[element.key])
            return result
        }
    }
    
}

extension CodeCov.File.Coverage {
    
    func delta(_ base: CodeCov.File.Coverage?) -> CoverageDelta {
        guard let base else {
            return .fileAdded(newCoverage: self)
        }
        
        return .delta(coverageChange: CodeCov.File.Coverage(
            count: count - base.count,
            covered: covered - base.covered,
            percent: percent - base.percent
        ))
    }
    
}

public extension Double {
    
    var sign: String {
        self > 0 ? "+" : ""
    }
    
    var asPercent: Double {
        self * 100
    }
    
    var asPercentToTwoPlaces: String {
        "\(asPercent.toTwoPlaces)%"
    }
    
    var toTwoPlaces: String {
        String(format: "%.2f", self)
    }
    
    var toTwoPlacesWithSign: String {
        "\(sign)\(toTwoPlaces)"
    }
    
}

extension Regex {
    
    init?(optionalString: String?) throws {
        guard let string = optionalString else {
            return nil
        }
        try self.init(string: string)
    }
    
}
