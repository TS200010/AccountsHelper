//
//  SortColumn.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 29/01/2026.
//

import Foundation

// MARK: --- SortColumn
enum SortColumn: CaseIterable, Identifiable {
    case category, currency, debitCredit, exchangeRate,
         payee, payer, account, reconciliation, timestamp, transactionDate, txAmount

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .category:        return "folder"
        case .currency:        return "dollarsign.circle"
        case .debitCredit:     return "arrow.left.arrow.right"
        case .exchangeRate:    return "chart.line.uptrend.xyaxis"
        case .account:   return "creditcard"
        case .payee:           return "person"
        case .payer:           return "person.crop.circle"
        case .reconciliation:  return "checkmark.seal"
        case .timestamp:       return "clock"
        case .transactionDate: return "calendar"
        case .txAmount:        return "sum"
        }
    }

    var title: String {
        switch self {
        case .category:        return "Category"
        case .currency:        return "Currency"
        case .debitCredit:     return "Debit/Credit"
        case .exchangeRate:    return "Fx"
        case .payee:           return "Payee"
        case .payer:           return "Payer"
        case .account:         return "Account"
        case .reconciliation:  return "Reconciliation"
        case .timestamp:       return "Timestamp"
        case .transactionDate: return "Date"
        case .txAmount:        return "Amount"
        }
    }

    func stringKey(for row: TransactionRow) -> String? {
        switch self {
        case .category:        return row.category
        case .currency:        return row.currency
        case .debitCredit:     return row.debitCredit
        case .exchangeRate:    return row.exchangeRate
        case .payee:           return row.payee
        case .payer:           return row.payer
        case .account:         return row.account
        case .reconciliation:  return row.reconciliationPeriod
        case .timestamp:       return row.timestamp
        case .transactionDate: return row.transactionDate
        case .txAmount:        return row.txAmount
        }
    }
}
