//
//  Decimal+Rounded.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/09/2025.
//

import Foundation

// MARK: --- Decimal rounding extension
extension Decimal {
    
    // Round a decimal to a given scale using a rounding mode
    func rounded(scale: Int, roundingMode: NSDecimalNumber.RoundingMode) -> Decimal {
        var result = Decimal()
        var value = self
        NSDecimalRound(&result, &value, scale, roundingMode)
        return result
    }
}
