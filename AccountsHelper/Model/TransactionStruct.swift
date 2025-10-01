//
//  TransactionStruct.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/09/2025.
//

import Foundation

// MARK: --- TransactionValidatable conformance
extension TransactionStruct: TransactionValidatable {}

// MARK: --- TransactionStruct
struct TransactionStruct {
    
    var id = UUID()
    
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
    
    var isSplit: Bool {
        splitAmount != Decimal(0)
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
        reset()
    }
    
    init(from transaction: Transaction) {
        self.accountNumber   = transaction.accountNumber
        self.address         = transaction.address
        self.category        = transaction.category
        self.currency        = transaction.currency
        self.debitCredit     = transaction.debitCredit
        self.exchangeRate    = transaction.exchangeRate
        self.explanation     = transaction.explanation
        self.extendedDetails = transaction.extendedDetails
        self.payee           = transaction.payee
        self.payer           = transaction.payer
        self.paymentMethod   = transaction.paymentMethod
        self.reference       = transaction.reference
        self.splitAmount     = transaction.splitAmount
        self.splitCategory   = transaction.splitCategory
        self.txAmount        = transaction.txAmount
        self.timestamp       = transaction.timestamp
        self.transactionDate = transaction.transactionDate
        self.commissionAmount = transaction.commissionAmount
    }
    
    mutating func reset() {
        txAmount = 0
        category = .unknown
        splitCategory = .unknown
        currency = .GBP
        debitCredit = .DR
        exchangeRate = 1.0
        payee = ""
        payer = .tony
        paymentMethod = .unknown
        splitAmount = 0
        transactionDate = Date()
        timestamp = Date()
        explanation = ""
    }
    
    func apply(to transaction: Transaction) {
        transaction.accountNumber   = accountNumber
        transaction.address         = address
        transaction.category        = category
        transaction.currency        = currency
        transaction.debitCredit     = debitCredit
        transaction.exchangeRate    = exchangeRate
        transaction.explanation     = explanation
        transaction.extendedDetails = extendedDetails
        transaction.payee           = payee
        transaction.payer           = payer
        transaction.paymentMethod   = paymentMethod
        transaction.reference       = reference
        transaction.splitAmount     = splitAmount
        transaction.splitCategory   = splitCategory
        transaction.txAmount        = txAmount
        transaction.timestamp       = timestamp
        transaction.transactionDate = transactionDate
        transaction.commissionAmount = commissionAmount
    }
}

