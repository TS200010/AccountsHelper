//
//  SplitView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/01/2026.
//

import Foundation
import SwiftUI

extension AddOrEditTransactionView {
    // MARK: --- SplitTransactionView
    struct SplitTransactionView: View {
        @Binding var transactionData: TransactionStruct
        @Binding var splitTransaction: Bool
        @FocusState var focusedField: AmountFieldIdentifier? // <-- pass parent state as Binding
        
        var body: some View {
            GroupBox(label: Label("Split Transaction", systemImage: "square.split.2x1")) {
                VStack(spacing: 8 ) {
                    Button(splitTransaction ? "Unsplit Transaction" : "Split Transaction") {
                        if splitTransaction {
                            splitTransaction = false
                            transactionData.splitAmount = 0
                            transactionData.splitCategory = .unknown
                        } else {
                            splitTransaction = true
                            let half = (transactionData.txAmount / 2).rounded(scale: 2, roundingMode: .up)
                            transactionData.splitAmount = half
                            transactionData.splitCategory = .unknown
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    VStack(spacing: gInterFieldSpacing ) {
                        LabeledDecimalWithFX(
                            label: "Split",
                            amount: $transactionData.splitAmount,
                            currency: $transactionData.currency,
                            fxRate: $transactionData.exchangeRate,
                            isValid: !splitTransaction || transactionData.isSplitAmountValid()
                        )
                        .focused($focusedField, equals: .splitAmountField)
                        
                        LabeledPicker(
                            label: "Split Category",
                            selection: $transactionData.splitCategory,
                            isValid: !splitTransaction || transactionData.isSplitCategoryValid()
                        )
                        
                        LabeledDecimalWithFX(
                            label: "Remainder",
                            amount: Binding(get: { transactionData.splitRemainderAmount }, set: { _ in }),
                            currency: $transactionData.currency,
                            fxRate: $transactionData.exchangeRate,
                            isValid: true,
                            displayOnly: true
                        )
                        
                        LabeledPicker(
                            label: "Remainder Category",
                            selection: $transactionData.category,
                            isValid: !splitTransaction || transactionData.isSplitRemainderCategoryValid()
                        )
                    }
                    .disabled(!splitTransaction)
                    .opacity(splitTransaction ? 1.0 : 0.5)
                }
            }
        }
    }

}
