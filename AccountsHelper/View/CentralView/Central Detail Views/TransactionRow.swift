//
//  TransactionRow.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 14/10/2025.
//

import Foundation
import CoreData

struct TransactionRow: Identifiable, Hashable {
    
    let transaction: Transaction
    var id: NSManagedObjectID { transaction.objectID }

    // MARK: --- Category
    var category: String { transaction.category.description }

    // MARK: --- Currency
    var currency: String { transaction.currency.description }

    // MARK: --- DebitCredit
    var debitCredit: String { transaction.debitCredit.description }
    
    // MARK: --- RunningBalance
    var runningBalance: Decimal = 0

    // MARK: --- DisplayAmount
    var displayAmount: String {
        var wip: String = transaction.txAmount.formattedAsCurrency( transaction.currency )
        if transaction.currency == .GBP {
            return wip
        } else {
#if os(macOS)
            return wip + "\n" + transaction.totalAmountInGBP.formattedAsCurrency( .GBP )
#else
//            return wip + " " + transaction.totalAmountInGBP.formattedAsCurrency( .GBP )
            return wip
#endif
        }
    }
    
    var displaySplitAmount: String {
        if transaction.splitAmount == Decimal(0) { return "" }

        var splitPart = transaction.splitAmountInGBP.formattedAsCurrency( .GBP ) + " " + transaction.splitCategory.description
        var remainderPart = transaction.splitRemainderAmountInGBP.formattedAsCurrency( .GBP ) + " " + transaction.splitRemainderCategory.description

    #if os(macOS)
            return splitPart + "\n" + remainderPart
    #else
            return splitPart + remainderPart
    #endif

    }

    // MARK: --- Explanation
    var explanation: String { transaction.explanation ?? "" }

    // MARK: --- iOSRowForDisplay
    var iOSRowForDisplay: String {
        var parts: [String] = []
        if !transactionDate.isEmpty { parts.append("\(transactionDate) \(transaction.paymentMethod.description)" ) }
        if !displayAmount.isEmpty { parts.append("\(displayAmount) \(payee): \(category)"  ) }
//        if !payee.isEmpty && !category.isEmpty { parts.append("\(payee): \(category)") }
        return parts.joined(separator: "\n")
    }

    // MARK: --- PaymentMethod
    var paymentMethod: String { transaction.paymentMethod.description }

    // MARK: --- Payer
    var payer: String { transaction.payer.description }

    // MARK: --- Payee
    var payee: String { transaction.payee ?? "" }

    // MARK: --- SplitCategory
    var splitCategory: String { transaction.splitCategory.description }

    // MARK: --- SplitRemainderAsString
    var splitRemainderAsString: String {
        let amount = transaction.splitRemainderAmount
        return amount.string2f
    }

    // MARK: --- SplitRemainderCategory
    var splitRemainderCategory: String { transaction.splitRemainderCategory.description }

    // MARK: --- TransactionDate
    var transactionDate: String { transaction.transactionDateAsString() ?? "" }

    // MARK: --- TxAmount
    var txAmount: String { transaction.txAmountAsString() }

    // MARK: --- ExchangeRate
    var exchangeRate: String { transaction.currency == .GBP ? "" : (transaction.exchangeRateAsString() ?? "") }

    static func == (lhs: TransactionRow, rhs: TransactionRow) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
