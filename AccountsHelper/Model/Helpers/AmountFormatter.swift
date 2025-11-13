//
//  AmountFormatter.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/11/2025.
//

import Foundation

// MARK: --- AmountFormatter
struct AmountFormatter {
    
    static func anyAmountAsString( amount: Decimal, currency: Currency, withSymbol: ShowCurrencySymbolsEnum = .always ) -> String {
        let amount = NSDecimalNumber(decimal: amount)
        if amount == 0 { return gDefaultZeroAmountRepresentation }
        if withSymbol.show(currency: currency) {
            return amount.decimalValue.formattedAsCurrency(currency)
        } else {
            return String(format: "%.2f", amount.doubleValue)
        }
    }
    
}
