//
//  Array+SumByCategoryIncludingSplits.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 28/09/2025.
//

import Foundation

// Sums txAmounts by category for a given payment method, including split transactions
//extension Array where Element == Transaction {
//    
//    func sumByCategoryIncludingSplits(for paymentMethod: PaymentMethod) -> [String: Decimal] {
//        var result: [String: Decimal] = [:]
//        
//        for tx in self where tx.paymentMethod == paymentMethod {
//            
//            // Add the splitAmount to its category
//            let splitCategory = tx.splitCategory.description
//            result[splitCategory.description, default: 0] += tx.splitAmount
//            
//            // Add the remainder to the main category
//            let remainderCategory = tx.splitRemainderCategory
//            result[remainderCategory.description, default: 0] += tx.splitRemainderAmount
//        }
//        
//        return result
//    }
//}

