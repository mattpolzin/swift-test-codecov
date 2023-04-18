//
//  CoverageTableRowTestHelpers.swift
//  
//
//  Created by Eric DeLabar on 12/12/22.
//

import Foundation
@testable import SwiftTestCodecovLogic
@testable import SwiftTestCodecovLib

extension CoverageTableRow {

    static func testRow(
        dependency: Bool? = nil,
        filename: String = "/Users/Test/myFile.swift",
        coverage: Double = 95.00,
        delta: CoverageDelta? = nil
    ) -> CoverageTableRow {
        CoverageTableRow(
            dependency: dependency,
            filename: filename,
            coverage: coverage,
            delta: delta
        )
    }

}
