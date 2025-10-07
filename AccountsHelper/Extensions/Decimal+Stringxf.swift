//
//  Decimal+Stringxf.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 06/10/2025.
//

import Foundation

// MARK: --- Decimal to String formatting extensions
extension Decimal {
    
    /// Format decimal with 2 decimal places
    var string2f: String {
        String(format: "%.2f", NSDecimalNumber(decimal: self).doubleValue)
    }
}

extension Decimal {
    
    /// Format decimal with no decimal places
    var string0f: String {
        String(format: "%.0f", NSDecimalNumber(decimal: self).doubleValue)
    }
}
