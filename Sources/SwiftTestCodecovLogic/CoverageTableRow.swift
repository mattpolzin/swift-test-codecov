//
//  CoverageTableRow.swift
//  
//
//  Created by Eric DeLabar on 12/12/22.
//

import Foundation
import SwiftTestCodecovLib

public struct CoverageTableRow {
    
    public let dependency: Bool?
    public let filename: String
    public let coverage: Double
    public let delta: CoverageDelta?
    
    public init(dependency: Bool? = nil, filename: String, coverage: Double, delta: CoverageDelta? = nil) {
        self.dependency = dependency
        self.filename = filename
        self.coverage = coverage
        self.delta = delta
    }
}

extension CoverageTableRow: Equatable {}

public extension CoverageTableRow {
    
    static var blank = CoverageTableRow(dependency: nil, filename: "", coverage: -1, delta: nil)
    static var divider = CoverageTableRow(dependency: nil, filename: "=-=-=-=-=-=-=-=-=", coverage: -1, delta: nil)
    
    var coverageDeltaString: String {
        guard let delta else {
            return ""
        }
        switch delta {
        case .fileRemoved:
            return "(Removed)"
        case .fileAdded(let coverage):
            return "\(coverage.percent.toTwoPlaces)%"
        case .delta(let coverage):
            guard coverage.percent != 0 else {
                return "-"
            }
            return "\(coverage.percent.toTwoPlacesWithSign)%"
        }
    }
    
    var coverageString: String {
        coverage >= 0 ? "\(coverage.toTwoPlaces)%" : ""
    }
    
    var isDependencyString: String {
        (dependency ?? false)  ? "✓" : ""
    }
    
}

public extension [CoverageTableRow] {
    
    func splitOutTests() -> [CoverageTableRow] {
        
        var sourceCoverages = [CoverageTableRow]()
        var testCoverages = [CoverageTableRow]()
        for fileCoverage in self {
            if fileCoverage.filename.contains("Tests") {
                testCoverages.append(fileCoverage)
            } else {
                sourceCoverages.append(fileCoverage)
            }
        }
        
        return sourceCoverages + [CoverageTableRow.blank, CoverageTableRow.divider, CoverageTableRow.blank] + testCoverages
        
    }
    
}

public extension Aggregate {
    
    func asTableData(includeDependencies: Bool, projectName: String?, sortOrder: SortOrder) -> [CoverageTableRow] {
        
        let coverage = coveragePerFile
        let deltas = coverageDeltaPerFile
        var fileCoverages: [CoverageTableRow] = coverage.map { kvp in
            let fileDelta = deltas?[kvp.key]
            return CoverageTableRow(
                dependency: includeDependencies ? isDependencyPath(kvp.key, projectName: projectName) : nil,
                filename: URL(fileURLWithPath: kvp.key).lastPathComponent,
                coverage: kvp.value.percent,
                delta: hasDeltas ? fileDelta : nil
            )
        }
        if let deltas {
            fileCoverages.append(contentsOf: deltas.filter { $0.value == .fileRemoved }.map { kvp in
                CoverageTableRow(
                    dependency: includeDependencies ? isDependencyPath(kvp.key, projectName: projectName) : nil,
                    filename: URL(fileURLWithPath: kvp.key).lastPathComponent,
                    coverage: -1,
                    delta: hasDeltas ? kvp.value : nil
                )
            })
        }

        let sortedCoverage : [CoverageTableRow]
        switch sortOrder {
        case .filename:
            // we always sort by filename above, even if we subsequently sort by another field.
            sortedCoverage = fileCoverages.sorted { $0.filename < $1.filename }
        case .coverageAsc:
            sortedCoverage = fileCoverages.sorted { $0.coverage < $1.coverage }
        case .coverageDesc:
            sortedCoverage = fileCoverages.sorted { $0.coverage > $1.coverage }
        }
        
        return sortedCoverage
        
    }
    
}
