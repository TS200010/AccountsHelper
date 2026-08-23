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
        .init(account: .BofSPV_82, category: .VisaPayment, suggestedCounterPayment: .VISA),
        .init(account: .BofSPV_82, category: .AMEXPayment, suggestedCounterPayment: .AMEX),
        .init(account: .BofSPV_82, category: .ToCashYEN,   suggestedCounterPayment: .CashYEN),
        .init(account: .BofSPV_82, category: .ToCashUKL,   suggestedCounterPayment: .CashUKL)
    ]
    
    static func trigger(for account: ReconcilableAccounts, category: Category) -> ReconcilableAccounts? {
        all.first { $0.account == account && $0.category == category }?.suggestedCounterPayment
    }
}
