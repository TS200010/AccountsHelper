//
//  Decimal+FormattedAsCurrency.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 11/10/2025.
//

import Foundation

extension Decimal {
    func formattedAsCurrency(_ currency: Currency) -> String {
        .init(
            self.formatted(
                .currency(code: currency.code)
                .locale(currency.localeForCurrency)
            )
        )
    }
}

