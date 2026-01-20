//
//  TransactionStruct.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/09/2025.
//

import Foundation

// MARK: --- TransactionValidatable Conformance
extension TransactionStruct: TransactionValidatable {}

// MARK: --- TransactionStruct
/// Struct representation of a Transaction, independent of Core Data.
/// Provides convenience initializers, derived properties, and conversion to/from Core Data Transaction objects.
struct TransactionStruct {
    
    // MARK: --- Properties
    
    /// Unique identifier
    var id = UUID()
    
    /// Optional account number for the transaction
    var accountNumber: String?
    
    /// Optional address associated with transaction
    var address: String?
    
    // MARK: --- Core transaction data
    
    var category: Category
    var currency: Currency
    var debitCredit: DebitCredit
    var exchangeRate: Decimal
    var explanation: String?
    var extendedDetails: String?
    var payee: String?
    var payer: Payer
    var paymentMethod: ReconcilableAccounts
    
    var reference: String?
    
    var splitAmount: Decimal
    var splitCategory: Category
    
    var txAmount: Decimal
    var timestamp: Date?
    var transactionDate: Date?
    var commissionAmount: Decimal
    
    // MARK: --- Derived Properties
    
    /// Remaining amount after split
    var splitRemainderAmount: Decimal {
        txAmount - splitAmount
    }
    
    /// Category associated with remainder (defaults to main category)
    var splitRemainderCategory: Category {
        category
    }
    
    /// Whether this transaction is a split
    var isSplit: Bool {
        splitAmount != Decimal(0)
    }
    
    /// Total in GBP after applying exchange rate and commission, rounded to 2 decimal places
    var totalInGBP: Decimal {
        let total = txAmount * exchangeRate + commissionAmount
        var roundedTotal = Decimal()
        var copy = total
        NSDecimalRound(&roundedTotal, &copy, 2, .plain)
        return roundedTotal
    }
    
    // MARK: --- Initializers
    
    /// Default initializer with optional parameters
    init(
        accountNumber: String? = nil,
        address: String? = nil,
        category: Category = .unknown,
        currency: Currency = .GBP,
        debitCredit: DebitCredit = .DR,
        exchangeRate: Decimal = 1.0,
        explanation: String? = nil,
        extendedDetails: String? = nil,
        payee: String? = nil,
        payer: Payer = .tony,
        paymentMethod: ReconcilableAccounts = .AMEX,
        reference: String? = nil,
        splitAmount: Decimal = 0,
        splitCategory: Category = .unknown,
        txAmount: Decimal = 0,
        timestamp: Date? = Date(),
        transactionDate: Date? = Date(),
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
    
    /// Initialize from a Core Data Transaction object
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
    
    // MARK: --- Methods
    
    /// Reset this transaction to default values
    mutating func setDefaults() {
        txAmount = 0
        category = .unknown
        splitCategory = .unknown
        currency = .GBP
        debitCredit = .DR
        exchangeRate = 1.0
        payee = ""
        payer = .tony
        paymentMethod = .AMEX
        splitAmount = 0
        transactionDate = Date()
        timestamp = Date()
        explanation = ""
    }
    
    /// Apply this struct’s values to a Core Data Transaction object
    /// - Parameter transaction: Core Data Transaction to update
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
