//
//  CentralViewsEnum.swift
//  From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

enum CentralViewsEnum: String {
    
    typealias RawValue = String
    
    case emptyView                  = " "
    
    case editTransaction            = "Edit Transaction"
    case editCurrency               = "Edit Currency"
    case editPayee                  = "Edit Payee"
    case editPayer                  = "Edit Payer"
    
    case addTransaction             = "Add Transaction"
    
    case reconcileTransactions      = "Reconcile Transactions"
    
    case browseTransactions         = "Browse Transactions"
    case browseCurrencies           = "Browse Currencies"
    case browsePayees               = "Browse Payees"
    case browsePayers               = "Browse Payers"

    case reports                    = "Reports"
}
