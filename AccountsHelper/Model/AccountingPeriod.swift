//
//  AccountingPeriod.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 25/09/2025.
//

import Foundation

struct AccountingPeriod: Hashable {
    let year: Int
    let month: Int

    var displayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let comps = DateComponents(year: year, month: month)
        return formatter.string(from: Calendar.current.date(from: comps)!)
    }

    var displayStringWithOpening: String {
        // Treat year 1 as opening balances
        if year <= 1 {
            return "Opening Balances"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateFormat = "MMMM yyyy"
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            if let date = Calendar.current.date(from: comps) {
                return formatter.string(from: date)
            }
            return "\(month)/\(year)"
        }
    }
}
