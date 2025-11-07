//
//  CounterPair.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 20/10/2025.
//

import Foundation

struct CounterPair: Identifiable, Hashable {
    let id = UUID()
    let from: PaymentMethod
    let to: PaymentMethod
    let name: String

    func involves(_ method: PaymentMethod) -> Bool {
        from == method || to == method
    }

    func counterparty(for method: PaymentMethod) -> PaymentMethod? {
        if from == method { return to }
        if to == method { return from }
        return nil
    }
}
