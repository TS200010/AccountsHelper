//
//  CounterPair.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 20/10/2025.
//

import Foundation

struct CounterPair: Identifiable, Hashable {
    let id = UUID()
    let from: ReconcilableAccounts
    let to: ReconcilableAccounts
    let name: String

    func involves(_ method: ReconcilableAccounts) -> Bool {
        from == method || to == method
    }

    func counterparty(for method: ReconcilableAccounts) -> ReconcilableAccounts? {
        if from == method { return to }
        if to == method { return from }
        return nil
    }
}
