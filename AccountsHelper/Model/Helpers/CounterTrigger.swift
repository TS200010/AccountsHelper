//
//  CounterTrigger.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 20/10/2025.
//

import Foundation

// MARK: - Counter Trigger Model
struct CounterTrigger {
    let paymentMethod: PaymentMethod
    let category: Category
    let suggestedCounterPayment: PaymentMethod
}

struct CounterTriggers {
    static let all: [CounterTrigger] = [
        .init(paymentMethod: .BofSPV, category: .VisaPayment, suggestedCounterPayment: .VISA),
        .init(paymentMethod: .BofSPV, category: .AMEXPayment, suggestedCounterPayment: .AMEX),
        .init(paymentMethod: .BofSPV, category: .TFBofSToCash, suggestedCounterPayment: .CashGBP)
    ]
    
    static func trigger(for paymentMethod: PaymentMethod, category: Category) -> PaymentMethod? {
        all.first { $0.paymentMethod == paymentMethod && $0.category == category }?.suggestedCounterPayment
    }
}
