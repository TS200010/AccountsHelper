//
//  Array+SumByCategoryIncludingSplits.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 28/09/2025.
//

import Foundation

// MARK: --- Extension to sum transactions including splits
extension Array where Element == Transaction {
    
    // MARK: --- Sum by Category including Splits (UKL)
    func sumByCategoryIncludingSplitsInUKLXXX() -> [Category: Decimal] {
        var result: [Category: Decimal] = [:]
        
        // Initialize all categories to 0
        for category in Category.allCases {
            result[category] = 0
        }
        
        // Sum transaction amounts by category including splits
        for tx in self {
            let splitAmt = tx.splitAmountInUKL
            if !splitAmt.isNaN {
                result[tx.splitCategory, default: 0] += splitAmt
            } else {
                print("⚠️ NaN splitAmountInUKL in tx:", tx)
            }

            let remainderAmt = tx.splitRemainderAmountInUKL
            if !remainderAmt.isNaN {
                result[tx.splitRemainderCategory, default: 0] += remainderAmt
            } else {
                print("⚠️ NaN splitRemainderAmountInUKL in tx:", tx)
            }
        }
        
        return result
    }
}
