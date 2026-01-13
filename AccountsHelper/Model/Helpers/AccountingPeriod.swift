//
//  AccountingPeriod.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 25/09/2025.
//

import Foundation

/// Represents a specific accounting period identified by year and month.
struct AccountingPeriod: Hashable, Equatable, CustomStringConvertible {
    
    // MARK: --- Properties
    let year: Int
    let month: Int

    // MARK: --- Display Strings
    
    var description: String { displayString }
    
    var shortDescription: String { "\(month)/\(year)" }

    /// Returns a localized display string for the period, e.g., "September 2025"
    var displayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let comps = DateComponents(year: year, month: month)
        return formatter.string(from: Calendar.current.date(from: comps)!)
    }

    /// Returns a display string, treating year <= 1 as "Opening Balances"
    var displayStringWithOpening: String {
        // Treat year 1 or less as opening balances
        if year <= 1 {
            return "Opening Balances"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateFormat = "MMMM yyyy"
            
            // Clamp month to 1...12
            let clampedMonth = min(max(month, 1), 12)
            
            var comps = DateComponents()
            comps.year = year
            comps.month = clampedMonth
            
            if let date = Calendar.current.date(from: comps) {
                return formatter.string(from: date)
            }
            
            // Fallback (should rarely be reached now)
            return "\(clampedMonth)/\(year)"
        }
    }

}
