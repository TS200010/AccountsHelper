//
//  TransactionValidatable.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 25/09/2025.
//

import Foundation

// MARK: --- TransactionValidatable Protocol
/// Protocol defining the essential fields of a transaction for validation purposes.
protocol TransactionValidatable {
    
    // MARK: --- Required Properties
    var txAmount: Decimal { get }
    var category: Category { get }
    var currency: Currency { get }
    var debitCredit: DebitCredit { get }
    var exchangeRate: Decimal { get }
    var payee: String? { get }
    var payer: Payer { get }
    var account: ReconcilableAccounts { get }
    var splitRemainderCategory: Category { get }
    var transactionDate: Date? { get }
    var splitCategory: Category { get }
    var splitAmount: Decimal { get }
}

// MARK: --- Default Validation Implementation
extension TransactionValidatable {
    
    // MARK: --- Body
    // Returns true if all key transaction fields are valid
    func isValid() -> Bool {
        return isTXAmountValid()
            && isCategoryValid()
            && isCurrencyValid()
            && isExchangeRateValid()
            && isDebitCreditValid()
            && isPayeeValid()
            && isPayerValid()
            && isAccountValid()
            && (splitAmount != 0 ? isSplitCategoryValid() : true)
            && (splitAmount != 0 ? isSplitRemainderCategoryValid() : true)
            && isTransactionDateValid()
    }
    
    // MARK: --- Individual Field Validation
    
    // Validates that the transaction amount is non-zero
    func isTXAmountValid() -> Bool {
        txAmount != Decimal(0)
    }
    
    // Validates that the main category is not unknown
    func isCategoryValid() -> Bool {
        category != .unknown
    }
    
    // Validates that the currency is known
    func isCurrencyValid() -> Bool {
        currency != .unknown
    }
    
    /// Validates that the exchange rate is sensible
    func isExchangeRateValid() -> Bool {
        currency == .GBP
        || (exchangeRate != Decimal(0)
            && (currency == .JPY ? exchangeRate < 300 : true))
    }
    
    /// Validates that debit/credit is set
    func isDebitCreditValid() -> Bool {
        debitCredit != .unknown
    }
    
    /// Validates that payee is non-empty
    func isPayeeValid() -> Bool {
        !(payee?.isEmpty ?? true)
    }
    
    /// Validates that the payer is known
    func isPayerValid() -> Bool {
        payer != .unknown
    }
    
    /// Validates that the payment method is known
    func isAccountValid() -> Bool {
        account != .unknown
    }
    
    /// Validates that the split amount is non-zero and less than total
    func isSplitAmountValid() -> Bool {
        splitAmount != 0 && splitAmount < txAmount
    }
    
    /// Validates that the split category is known
    func isSplitCategoryValid() -> Bool {
        splitCategory != .unknown
    }
    
    /// Validates that the split remainder category is known
    func isSplitRemainderCategoryValid() -> Bool {
        splitRemainderCategory != .unknown
    }
    
    /// Validates that the transaction date is not in the future
    func isTransactionDateValid() -> Bool {
        (transactionDate ?? Date()) <= Date()
    }
}
