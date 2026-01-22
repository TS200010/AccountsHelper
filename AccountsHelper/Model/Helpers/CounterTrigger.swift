//
//  CounterTrigger.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 20/10/2025.
//

import Foundation

// MARK: - Counter Trigger Model
struct CounterTrigger {
    let account: ReconcilableAccounts
    let category: Category
    let suggestedCounterPayment: ReconcilableAccounts
}

struct CounterTriggers {
    static let all: [CounterTrigger] = [
        .init(account: .BofSPV, category: .VisaPayment, suggestedCounterPayment: .VISA),
        .init(account: .BofSPV, category: .AMEXPayment, suggestedCounterPayment: .AMEX),
        .init(account: .BofSPV, category: .ToYenCash,   suggestedCounterPayment: .CashYEN),
        .init(account: .BofSPV, category: .ToGBPCash,   suggestedCounterPayment: .CashGBP)
    ]
    
    static func trigger(for account: ReconcilableAccounts, category: Category) -> ReconcilableAccounts? {
        all.first { $0.account == account && $0.category == category }?.suggestedCounterPayment
    }
}
