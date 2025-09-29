//
//  CentralViewsEnum.swift
//  From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
enum CentralViewsEnum: Hashable {
    
    case emptyView
    case editTransaction
    case editCurrency
    case editPayee
    case editPayer
    case addTransaction
    case AMEXCSVImport
    case reconcilliationListView
    case reconciliationTransactionDetail( NSPredicate? )
    case browseTransactions(NSPredicate?)   // optional predicate
    case transactionMergeView([Transaction], onComplete: (() -> Void)? = nil)
    case transactionSummary([Transaction], paymentMethod: PaymentMethod )
    case browseCategories
    case browseCurrencies
    case browsePayees
    case browsePayers

    case reports

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

    static func == (lhs: CentralViewsEnum, rhs: CentralViewsEnum) -> Bool {
        switch (lhs, rhs) {
        case (.browseTransactions(let lp), .browseTransactions(let rp)):
            return lp?.predicateFormat == rp?.predicateFormat
        default:
            return lhs.asString == rhs.asString
        }
    }

    var asString: String {
        switch self {
        case .emptyView: return " "
        case .editTransaction: return "Edit Transaction"
        case .editCurrency: return "Edit Currency"
        case .editPayee: return "Edit Payee"
        case .editPayer: return "Edit Payer"
        case .addTransaction: return "Add Transaction"
        case .AMEXCSVImport: return "AMEX CSV Import"
        case .reconcilliationListView: return "Reconcile Transactions"
        case .reconciliationTransactionDetail: return "Reconciliation Transaction Detail"
        case .browseTransactions: return "Browse Transactions"
        case .browseCategories: return "Browse Categories"
        case .browseCurrencies: return "Browse Currencies"
        case .browsePayees: return "Browse Payees"
        case .browsePayers: return "Browse Payers"
        case .reports: return "Reports"
        case .transactionMergeView: return "Transactions Merge"
        case .transactionSummary: return "Transaction Summary"
        }
    }
}


//enum CentralViewsEnum: String {
//    
//    typealias RawValue = String
//    
//    case emptyView                  = " "
//    
//    case editTransaction            = "Edit Transaction"
//    case editCurrency               = "Edit Currency"
//    case editPayee                  = "Edit Payee"
//    case editPayer                  = "Edit Payer"
//    
//    case addTransaction             = "Add Transaction"
//    
//    case AMEXCSVImport              = "AMEX CSV Import"
//    
//    case reconcileTransactions      = "Reconcile Transactions"
//    case reconcilliationTransactionDetail
//                                    = "Reconciliation Transaction Detail"
//    
//    case browseTransactions( NSPredicate )
//                                    = "Browse Transactions"
//    case browseCategories           = "Browse Categories"
//    case browseCurrencies           = "Browse Currencies"
//    case browsePayees               = "Browse Payees"
//    case browsePayers               = "Browse Payers"
//
//    case reports                    = "Reports"
//}
