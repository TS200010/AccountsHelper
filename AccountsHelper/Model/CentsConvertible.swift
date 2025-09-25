//
//  CentsConvertible.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 25/09/2025.
//

import Foundation

protocol CentsConvertible {
    func decimalToCents(_ value: Decimal) -> Int32
}

extension CentsConvertible {
    func decimalToCents(_ value: Decimal) -> Int32 {
        var scaled = value * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        return Int32(truncating: NSDecimalNumber(decimal: rounded))
    }
}
