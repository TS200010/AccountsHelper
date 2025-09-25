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
}

