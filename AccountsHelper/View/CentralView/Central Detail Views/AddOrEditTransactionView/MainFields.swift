//
//  MainFields.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/01/2026.
//

import Foundation
import SwiftUI

extension AddOrEditTransactionView {
    
    var mainFields: some View {
        
        GroupBox(label: Label("Transaction Details", systemImage: "doc.text")) {
            VStack(spacing: gInterFieldSpacing ) {
                
                LabeledDatePicker(
                    label: "TX Date",
                    date: Binding(
                        get: { transactionData.transactionDate ?? Date() },
                        set: { transactionData.transactionDate = $0 }
                    ),
                    displayedComponents: [.date],
                    isValid: transactionData.isTransactionDateValid()
                )
                
                LabeledPicker(label: "Payer", selection: $transactionData.payer, isValid: transactionData.isPayerValid())
                
                LabeledPicker(label: "Currency", selection: $transactionData.currency, isValid: transactionData.isCurrencyValid())
                
                if transactionData.currency != .GBP {
                    LabeledDecimalField(label: "Exchange Rate", amount: $transactionData.exchangeRate, isValid: transactionData.isExchangeRateValid())
                }
                
                LabeledPicker(label: "Debit/Credit", selection: $transactionData.debitCredit, isValid: transactionData.debitCredit != .unknown)
                
                LabeledDecimalWithFX(label: "Amount", amount: $transactionData.txAmount, currency: $transactionData.currency, fxRate: $transactionData.exchangeRate, isValid: transactionData.isTXAmountValid(), displayOnly: false)
                    .focused($focusedField, equals: .mainAmountField)
                
                LabeledPicker(label: "Account", selection: $transactionData.account, isValid: transactionData.isAccountValid())
                
                LabeledTextField(label: "Payee", text: Binding(get: { transactionData.payee ?? "" }, set: { transactionData.payee = $0 }), isValid: transactionData.isPayeeValid())
                    .onChange(of: transactionData.payee) { _, newValue in
                        guard let payee = newValue, !payee.isEmpty else { return }
                        let matcher = CategoryMatcher(context: viewContext)
                        transactionData.category = matcher.matchCategory(for: payee)
                    }
                
                HStack(spacing: 8) {
                    LabeledPicker(
                        label: "Category",
                        selection: $transactionData.category,
                        isValid: transactionData.isCategoryValid()
                    )
                    
                    Button("Suggest") {
                        if let payee = transactionData.payee, !payee.isEmpty {
                            let matcher = CategoryMatcher(context: viewContext)
                            transactionData.category = matcher.matchCategory(for: payee)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.system(size: 11))
                }
                
                LabeledTextField(label: "Explanation", text: Binding(get: { transactionData.explanation ?? "" }, set: { transactionData.explanation = $0 }), isValid: true)
            }
        }
    }
}
