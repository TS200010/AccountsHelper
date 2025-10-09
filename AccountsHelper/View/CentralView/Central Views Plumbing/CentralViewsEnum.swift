//
//  CentralViewsEnum.swift
//  From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI

// MARK: --- CentralViewsEnum
enum CentralViewsEnum: Hashable {
    
    // MARK: --- Cases
    case emptyView
    case editTransaction(existingTransaction: Transaction?)
    case editCurrency
    case editPayee
    case editPayer
    case exportCD
    case importCD
    case addTransaction
    case AMEXCSVImport
    case BofSCSVImport
    case VISAPNGImport
    case reconcilliationListView
    case reconciliationTransactionDetail(NSPredicate?)
    case browseTransactions(NSPredicate?)   // optional predicate
    case transactionMergeView([Transaction], onComplete: (() -> Void)? = nil)
    case transactionSummary(NSPredicate?)
    case browseCategories
    case browseCurrencies
    case browsePayees
    case browsePayers
    case reports

    // MARK: --- Hashable
    func hash(into hasher: inout Hasher) {
        switch self {
        case .browseTransactions(let predicate):
            hasher.combine("browseTransactions")
            if let pred = predicate {
                hasher.combine(pred.predicateFormat) // NSPredicate is not Hashable; use predicateFormat
            }
        default:
            hasher.combine(asString) // use the asString for other cases
        }
    }

    // MARK: --- Equatable
    static func == (lhs: CentralViewsEnum, rhs: CentralViewsEnum) -> Bool {
        switch (lhs, rhs) {
        case (.browseTransactions(let lp), .browseTransactions(let rp)):
            return lp?.predicateFormat == rp?.predicateFormat
        default:
            return lhs.asString == rhs.asString
        }
    }

    // MARK: --- Description
    var asString: String {
        switch self {
        case .emptyView: return " "
        case .editTransaction: return "Edit Transaction"
        case .editCurrency: return "Edit Currency"
        case .editPayee: return "Edit Payee"
        case .editPayer: return "Edit Payer"
        case .addTransaction: return "Add Transaction"
        case .AMEXCSVImport: return "AMEX CSV Import"
        case .BofSCSVImport: return "BofS CSV Import"
        case .VISAPNGImport: return "VISA PNG Import"
        case .reconcilliationListView: return "Reconcile Transactions"
        case .reconciliationTransactionDetail: return "Reconciliation Transaction Detail"
        case .browseTransactions: return "Browse Transactions"
        case .browseCategories: return "Browse Categories"
        case .browseCurrencies: return "Browse Currencies"
        case .browsePayees: return "Browse Payees"
        case .browsePayers: return "Browse Payers"
        case .reports: return "Reports"
        case .transactionMergeView: return "Transactions Merge"
        case .transactionSummary: return "Transactions Summary"
        case .exportCD: return "Export Transactions"
        case .importCD: return "Import Transactions"
        }
    }
}
