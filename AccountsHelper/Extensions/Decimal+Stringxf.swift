//
//  Decimal+Stringxf.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 06/10/2025.
//

import Foundation


extension Decimal {
    var string2f: String {
        String(format: "%.2f", NSDecimalNumber(decimal: self).doubleValue)
    }
}

extension Decimal {
    var string0f: String {
        String(format: "%.0f", NSDecimalNumber(decimal: self).doubleValue)
    }
}
