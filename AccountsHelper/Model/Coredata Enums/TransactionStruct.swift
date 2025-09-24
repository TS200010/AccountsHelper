//
//  TransactionStruct.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/09/2025.
//

import Foundation

import Foundation

struct TransactionStruct {
    var accountNumber: String?
    var address: String?
    
    // Computed property equivalents
    var category: Category
    var currency: Currency
    var debitCredit: DebitCredit
    var exchangeRate: Decimal
    var explanation: String?
    var extendedDetails: String?
    var payee: String?
    var payer: Payer
    var paymentMethod: PaymentMethod
    
    var reference: String?
    
    var splitAmount: Decimal
    var splitCategory: Category
    
    var txAmount: Decimal
    var timestamp: Date?
    var transactionDate: Date?
    var commissionAmount: Decimal
    
    // Derived properties
    var splitRemainderAmount: Decimal {
        txAmount - splitAmount
    }
    
    var splitRemainderCategory: Category {
        category
    }
    
    var totalInGBP: Decimal {
        let total = txAmount * exchangeRate + commissionAmount
        var roundedTotal = Decimal()
        var copy = total
        NSDecimalRound(&roundedTotal, &copy, 2, .plain)
        return roundedTotal
    }
    
    // Initializer
    init(
        accountNumber: String? = nil,
        address: String? = nil,
        category: Category = .unknown,
        currency: Currency = .unknown,
        debitCredit: DebitCredit = .unknown,
        exchangeRate: Decimal = 1.0,
        explanation: String? = nil,
        extendedDetails: String? = nil,
        payee: String? = nil,
        payer: Payer = .unknown,
        paymentMethod: PaymentMethod = .unknown,
        reference: String? = nil,
        splitAmount: Decimal = 0,
        splitCategory: Category = .unknown,
        txAmount: Decimal = 0,
        timestamp: Date? = nil,
        transactionDate: Date? = nil,
        commissionAmount: Decimal = 0
    ) {
        self.accountNumber = accountNumber
        self.address = address
        self.category = category
        self.currency = currency
        self.debitCredit = debitCredit
        self.exchangeRate = exchangeRate
        self.explanation = explanation
        self.extendedDetails = extendedDetails
        self.payee = payee
        self.payer = payer
        self.paymentMethod = paymentMethod
        self.reference = reference
        self.splitAmount = splitAmount
        self.splitCategory = splitCategory
        self.txAmount = txAmount
        self.timestamp = timestamp
        self.transactionDate = transactionDate
        self.commissionAmount = commissionAmount
    }
}
