//
//  Helpers.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/01/2026.
//

import Foundation

extension AddOrEditTransactionView {
    
    // MARK: --- AmountFieldIdentifier Focus identifiers for amount fields
    enum AmountFieldIdentifier: Hashable {
        case mainAmountField
        case splitAmountField
    }
    
    // MARK: --- ResetForm
    func resetForm() {
        transactionData = TransactionStruct()
        transactionData.setDefaults()
    }
    


}

