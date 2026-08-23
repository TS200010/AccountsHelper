//
//  FormatDecimal.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/01/2026.
//

import Foundation


// MARK: --- FormatDecimal
func formatDecimal(_ value: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter.string(from: value as NSDecimalNumber) ?? "0.00"
}
