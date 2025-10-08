//
//  NSManagedContext+CategoryRows.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 05/10/2025.
//

import Foundation
import CoreData

// MARK: --- NSManagedObjectContext Category Totals
//extension NSManagedObjectContext {
//
//    /// Fetch transactions matching a predicate and sum by category including splits in GBP
//    func categoryTotals(for predicate: NSPredicate) -> [Category: Decimal] {
//        do {
//            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
//            request.predicate = predicate
//            let transactions = try fetch(request)
//            return transactions.sumByCategoryIncludingSplitsInGBP()
//        } catch {
//            print("Failed to fetch category totals: \(error)")
//            return [:]
//        }
//    }
//
//    /// Convenience for a ReconciliationRow
//    func categoryTotals(for row: ReconciliationRow) -> [Category: Decimal] {
//        let predicate = NSPredicate(
//            format: "paymentMethodCD == %d AND transactionDate >= %@ AND transactionDate <= %@",
//            row.rec.paymentMethod.rawValue,
//            row.rec.transactionStartDate as NSDate,
//            row.rec.transactionEndDate as NSDate
//        )
//        return categoryTotals(for: predicate)
//    }
//}
