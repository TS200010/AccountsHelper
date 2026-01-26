//
//  SaveTransaction.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/01/2026.
//

import Foundation
import CoreData

extension AddOrEditTransactionView {
    
    // MARK: --- SaveTransaction
    func saveTransaction() {
        // --- Save main transaction
        let tx = existingTransaction ?? Transaction(context: viewContext)
        transactionData.apply(to: tx)
        
        // --- Save counter transaction if active
        if counterTransactionActive,
           let counterAccount = counterAccount,
           counterAccount != .unknown {

            // --- If counter already exists, update it
            if let counterTx = tx.counterTransaction(in: viewContext) {
                var counterData = transactionData
                counterData.account = counterAccount
                counterData.currency = counterAccount.currency
                counterData.exchangeRate = (counterData.currency == .GBP) ? 1 : counterFXRate

                let amountInGBP: Decimal = (transactionData.currency == .GBP)
                    ? transactionData.txAmount
                    : transactionData.txAmount / transactionData.exchangeRate

                counterData.txAmount = -amountInGBP * counterData.exchangeRate
                counterData.apply(to: counterTx)

                // Preserve link
                counterTx.pairID = tx.pairID
                counterTx.exchangeRate = counterData.exchangeRate
                counterTx.txAmount = counterData.txAmount

            } else {

                // --- Create new counter transaction
                let counterTx = Transaction(context: viewContext)
                var counterData = transactionData

                counterData.account = counterAccount
                counterData.currency = counterAccount.currency
                counterData.exchangeRate = (counterData.currency == .GBP) ? 1 : counterFXRate

                let amountInGBP: Decimal = (transactionData.currency == .GBP)
                    ? transactionData.txAmount
                    : transactionData.txAmount / transactionData.exchangeRate

                counterData.txAmount = -amountInGBP * counterData.exchangeRate
                counterData.apply(to: counterTx)

                // Link them
                let newPairID = UUID()
                tx.pairID = newPairID
                counterTx.pairID = newPairID
            }
        }

        // --- Save context
        do {
            try viewContext.save()
        } catch {
            print("Failed to save transaction: \(error)")
            viewContext.rollback()
        }
        
        // --- Teach category mapping for main transaction
        if let payee = transactionData.payee {
            let matcher = CategoryMatcher(context: viewContext)
            matcher.teachMapping(for: payee, category: transactionData.category)
        }
    }
    
}
