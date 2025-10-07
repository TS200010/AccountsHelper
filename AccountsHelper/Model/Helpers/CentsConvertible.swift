//
//  CentsConvertible.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 25/09/2025.
//

import Foundation

// MARK: --- CentsConvertible
/// Protocol for types that can convert Decimal values to cents (Int32)
protocol CentsConvertible {
    /// Converts a Decimal value (e.g., 12.34) into cents (1234)
    /// - Parameter value: Decimal value to convert
    /// - Returns: Int32 representing the value in cents
    func decimalToCents(_ value: Decimal) -> Int32
}

extension CentsConvertible {
    // MARK: --- DecimalToCents
    /// Default implementation: multiplies by 100 and rounds to nearest integer
    func decimalToCents(_ value: Decimal) -> Int32 {
        // Scale the decimal by 100 to get cents
        var scaled = value * 100
        var rounded = Decimal()
        // Round to nearest integer using plain rounding mode
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        // Convert to Int32
        return Int32(truncating: NSDecimalNumber(decimal: rounded))
    }
}
