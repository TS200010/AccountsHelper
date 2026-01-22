//
//  TransactionPosting.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 16/01/2026.
//

import Foundation

struct TransactionPosting {
    let category: Category
    let amount: Decimal
}


extension Array where Element == Transaction {
    var postings: [TransactionPosting] {
        var result: [TransactionPosting] = []

        for tx in self {
            // Split portion (always converted to payment method currency)
            if tx.splitAmount != 0 {
                let convertedSplit = tx.convertToPaymentCurrency(amount: tx.splitAmount)
                result.append(TransactionPosting(category: tx.splitCategory, amount: convertedSplit))
            }

            // Remainder portion + commission
            let convertedRemainder =
                tx.convertToPaymentCurrency(amount: tx.splitRemainderAmount)
                + tx.commissionAmount
//            let remainderPlusCommission = tx.splitRemainderAmount + tx.commissionAmount
//            if remainderPlusCommission != 0 {
//                let convertedRemainder = tx.convertToPaymentCurrency(amount: remainderPlusCommission)
                result.append(TransactionPosting(category: tx.splitRemainderCategory, amount: convertedRemainder))
//            }
        }

//        print (result)
        return result
    }
}

//extension Array where Element == Transaction {
//    var postings: [TransactionPosting] {
//        var result: [TransactionPosting] = []
//        
//        for tx in self {
//            // Split portion
//            if tx.splitAmount != 0 {
//                result.append(TransactionPosting(category: tx.splitCategory, amount: tx.splitAmount))
//            }
//            
//            // Remainder portion
//            if tx.splitRemainderAmount != 0 {
//                result.append(TransactionPosting(category: tx.splitRemainderCategory, amount: tx.splitRemainderAmount))
//            }
//        }
//
//        return result
//    }
//}
