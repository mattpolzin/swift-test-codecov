//
//  AggregateHelpers.swift
//  
//
//  Created by Eric DeLabar on 12/12/22.
//

import Foundation
import SwiftTestCodecovLib

public extension Aggregate {
    
    var minimalDisplay: String {
        var result = formattedOverallCoveragePercent
        if let formattedOverallCoveragePercentDelta = formattedOverallCoveragePercentDelta {
            result += " (\(formattedOverallCoveragePercentDelta))"
        }
        
        return result
    }
    
    var numericDisplay: Double {
        if let delta = overallCoveragePercentDelta {
            return delta
        }
        return overallCoveragePercent
    }
    
}
