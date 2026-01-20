//
//  CounterTrigger.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 20/10/2025.
//

import Foundation

// MARK: - Counter Trigger Model
struct CounterTrigger {
    let paymentMethod: ReconcilableAccounts
    let category: Category
    let suggestedCounterPayment: ReconcilableAccounts
}

struct CounterTriggers {
    static let all: [CounterTrigger] = [
        .init(paymentMethod: .BofSPV, category: .VisaPayment, suggestedCounterPayment: .VISA),
        .init(paymentMethod: .BofSPV, category: .AMEXPayment, suggestedCounterPayment: .AMEX),
        .init(paymentMethod: .BofSPV, category: .ToYenCash,   suggestedCounterPayment: .CashYEN),
        .init(paymentMethod: .BofSPV, category: .ToGBPCash,   suggestedCounterPayment: .CashGBP)
    ]
    
    static func trigger(for paymentMethod: ReconcilableAccounts, category: Category) -> ReconcilableAccounts? {
        all.first { $0.paymentMethod == paymentMethod && $0.category == category }?.suggestedCounterPayment
    }
}
