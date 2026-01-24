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
        if counterTransactionActive, let method = counterAccount, method != .unknown {
            let counterTx = Transaction(context: viewContext)
            var counterData = transactionData
            
            // Set counter payment method
            counterData.account = method
            
            // Set counter currency
            counterData.currency = method.currency
            
            // Prompted FX rate for non-GBP counter
            if counterData.currency == .GBP {
                counterData.exchangeRate = 1
            } else {
                // exchangeRate should have been prompted from the user in the UI
                // Make sure it is set
                counterData.exchangeRate = counterFXRate
            }
            
            // Convert main transaction amount to GBP
            let amountInGBP: Decimal
            if transactionData.currency == .GBP {
                amountInGBP = transactionData.txAmount
            } else {
                amountInGBP = transactionData.txAmount / transactionData.exchangeRate
            }
            
            // Set counter transaction amount in counter currency
            counterData.txAmount = -amountInGBP * counterData.exchangeRate
            
            // Apply to counter transaction
            counterData.apply(to: counterTx)
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

