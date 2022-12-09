//
//  SortOrder.swift
//  
//
//  Created by Eric DeLabar on 12/12/22.
//

import Foundation

/// How to sort the coverage table results (if `PrintFormat` is `.table`).
public enum SortOrder: String, CaseIterable {
    case filename
    case coverageAsc = "+cov"
    case coverageDesc = "-cov"
}
