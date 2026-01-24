//
//  CounterTransactionView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/01/2026.
//

import Foundation
import SwiftUI
import ItMkLibrary

extension AddOrEditTransactionView {
    
    struct CounterTransactionView: View {
        @Binding var transactionData: TransactionStruct
        @Binding var counterTransaction: Bool
        @Binding var counterAccount: ReconcilableAccounts?
        @Binding var counterFXRate: Decimal
        
        // Suggested counter methods based on Account + Category
        private var suggestedCounterMethods: [ReconcilableAccounts] {
            if let suggested = CounterTriggers.trigger(
                for: transactionData.account,
                category: transactionData.category
            ) {
                return [suggested]
            }
            return []
        }
        
        var body: some View {
            GroupBox(label: Label("Counter Transaction", systemImage: "arrow.2.squarepath")) {
                VStack(spacing: 12) {
                    
                    Button(counterTransaction ? "Remove Counter Transaction" : "Add Counter Transaction") {
                        counterTransaction.toggle()
                        
                        if counterTransaction {
                            // Auto-suggest top picker if a trigger exists
                            counterAccount = suggestedCounterMethods.first ?? .unknown
                        } else {
                            counterAccount = nil
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    VStack(spacing: 8) {
                        
                        // --- FX If counter transaction is different currency ---
                        if counterTransaction && transactionData.account.currency != counterAccount?.currency {
                            LabeledDecimalField(
                                label: "Counter FX Rate",
                                amount: $counterFXRate,
                                isValid: counterFXRate > 0
                            )
                        }
                        
                        // --- Top Picker: Suggested Counter Methods ---
                        if !suggestedCounterMethods.isEmpty {
                            LabeledPicker(
                                label: "Suggested Account",
                                selection: Binding(
                                    get: { counterAccount ?? .unknown },
                                    set: { counterAccount = $0 }
                                ),
                                isValid: counterAccount != nil && counterAccount != .unknown,
                                items: suggestedCounterMethods
                            )
                        }
                        
                        // --- Bottom Picker: Manual Payment Method (any) ---
                        LabeledPicker(
                            label: "Chosen Counter Pmt",
                            selection: Binding(
                                get: { counterAccount ?? .unknown },
                                set: { counterAccount = $0 }
                            ),
                            isValid: counterAccount != nil && counterAccount != .unknown
                        )
                        
                        // --- Amount Box ---
                        LabeledDecimalWithFX(
                            label: "Counter Pmt Amount",
                            amount: Binding(
                                get: {
                                    guard let method = counterAccount else { return transactionData.txAmount }
                                    if transactionData.currency == method.currency {
                                        return transactionData.txAmount
                                    } else {
                                        guard counterFXRate > 0 else { return 0 }
                                        // Convert via GBP
                                        let gbpValue = transactionData.currency == .GBP
                                        ? transactionData.txAmount
                                        : transactionData.txAmount / transactionData.exchangeRate
                                        return gbpValue * counterFXRate
                                    }
                                },
                                set: { _ in }
                            ),
                            //                            amount: Binding(get: { transactionData.txAmount }, set: { _ in }),
                            currency: $transactionData.currency,
                            fxRate: $transactionData.exchangeRate,
                            isValid: true,
                            displayOnly: true
                        )
                        
                    }
                    .disabled(!counterTransaction)
                    .opacity(counterTransaction ? 1.0 : 0.5)
                    .if(gViewCheck) { view in view.border(.green) }
                }
                .padding(.vertical, 8)
                .if(gViewCheck) { view in view.border(.orange) }
            }
            .if(gViewCheck) { view in view.border(.red) }
        }
    }
}
