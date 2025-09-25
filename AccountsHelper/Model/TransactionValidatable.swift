//
//  TransactionValidatable.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 25/09/2025.
//

import Foundation

protocol TransactionValidatable {
    var txAmount: Decimal { get }
    var category: Category { get }
    var currency: Currency { get }
    var debitCredit: DebitCredit { get }
    var exchangeRate: Decimal { get }
    var payee: String? { get }
    var payer: Payer { get }
    var paymentMethod: PaymentMethod { get }
    var splitRemainderCategory: Category { get }
    var transactionDate: Date? { get }
    
    var splitCategory: Category { get }
    var splitAmount: Decimal { get }
}


extension TransactionValidatable {
    
    // MARK: ---  Returns true if all key transaction fields are valid
    func isValid() -> Bool {
        return isTXAmountValid()
        && isCategoryValid()
        && isCurrencyValid()
        && isExchangeRateValid()
        && isDebitCreditValid()
        && isPayeeValid()
        && isPayerValid()
        && isPaymentMethodValid()
        && (splitAmount != 0 ? isSplitCategoryValid() : true)
        && (splitAmount != 0 ? isSplitRemainderCategoryValid() : true)
        && isTransactionDateValid()
    }
    
    // MARK: - Individual checks
    
    func isTXAmountValid() -> Bool {
        txAmount != Decimal(0)
    }
    
    func isCategoryValid() -> Bool {
        category != .unknown
    }
    
    func isCurrencyValid() -> Bool {
        currency != .unknown
    }
    
    func isExchangeRateValid() -> Bool {
        currency == .GBP
        || (exchangeRate != Decimal(0)
            && (currency == .JPY ? exchangeRate < 300 : true))
    }
    
    func isDebitCreditValid() -> Bool {
        debitCredit != .unknown
    }
    
    func isPayeeValid() -> Bool {
        !(payee?.isEmpty ?? true)
    }
    
    func isPayerValid() -> Bool {
        payer != .unknown
    }
    
    func isPaymentMethodValid() -> Bool {
        paymentMethod != .unknown
    }
    
    func isSplitAmountValid() -> Bool {
        splitAmount != 0 && splitAmount < txAmount
    }
    
    func isSplitCategoryValid() -> Bool {
        splitCategory != .unknown
    }
    
    func isSplitRemainderCategoryValid() -> Bool {
        splitRemainderCategory != .unknown
    }
    
    func isTransactionDateValid() -> Bool {
        (transactionDate ?? Date()) <= Date()
    }
}
