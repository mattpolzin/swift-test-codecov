//
//  TextTableHelpers.swift
//  
//
//  Created by Eric DeLabar on 12/12/22.
//

import Foundation
import TextTable

public extension Column {
    
    func includeIf(_ shouldShow: Bool) -> Column? {
        shouldShow ? self : nil
    }
    
}
