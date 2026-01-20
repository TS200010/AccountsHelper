//
//  CounterRelationships.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 20/10/2025.
//

import Foundation

struct CounterRelationships {
    static let all: [CounterPair] = [
        .init(from: .BofSPV, to: .CashGBP, name: "ATM Withdrawal"),
        .init(from: .BofSPV, to: .AMEX,    name: "AMEX Payment"),
        .init(from: .BofSPV, to: .VISA,    name: "VISA Payment")
    ]

    static func matches(for method: ReconcilableAccounts) -> [CounterPair] {
        all.filter { $0.involves(method) }
    }

    static func suggestedCounter(for method: ReconcilableAccounts) -> ReconcilableAccounts? {
        matches(for: method).first?.counterparty(for: method)
    }

    static func transactionName(for from: ReconcilableAccounts, to: ReconcilableAccounts) -> String? {
        all.first { ($0.from == from && $0.to == to) || ($0.from == to && $0.to == from) }?.name
    }
}
