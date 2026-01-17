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
            // Split portion
            if tx.splitAmount != 0 {
                result.append(TransactionPosting(category: tx.splitCategory, amount: tx.splitAmount))
            }
            
            // Remainder portion
            if tx.splitRemainderAmount != 0 {
                result.append(TransactionPosting(category: tx.splitRemainderCategory, amount: tx.splitRemainderAmount))
            }
        }
        
        print( result)
        return result
    }
}
