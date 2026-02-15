//
//  CategoriesSummaryVM.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 15/02/2026.
//

import Foundation



// MARK: --- SummaryTotals
struct SummaryTotals {
    var startBalance: Decimal = 0
    var endBalance: Decimal = 0
    var totalCR: Decimal = 0
    var totalDR: Decimal = 0
    var total: Decimal { get { totalCR + totalDR } }
    var currency: Currency = .unknown
}

extension Array where Element == Transaction {

    func summaryTotals(startBalance: Decimal, currency: Currency) -> SummaryTotals {

        var result = SummaryTotals()
        result.startBalance = startBalance
        result.currency = currency

        for posting in self.postings {
            let amount = posting.amount
            if amount < 0 {
                result.totalCR += amount
            } else if amount > 0 {
                result.totalDR += amount
            }
        }

        result.endBalance = result.startBalance - result.total
        return result
    }
}


struct CategoryRow: Identifiable, Hashable {
    let category: Category
    let total: Decimal
    let currency: Currency

    var id: Int32 { category.id }
}


extension Array where Element == Transaction {
    func categoryRows(currency: Currency) -> [CategoryRow] {
        let postings = self.postings

        let grouped = Dictionary(grouping: postings, by: { $0.category })

        return Category.allCases.map { category in
            let total = grouped[category]?.reduce(Decimal(0)) {
                $0 + $1.amount
            } ?? 0

            return CategoryRow(
                category: category,
                total: total,
                currency: currency
            )
        }
    }
}


struct CategoriesSummaryVM {


    let reconciliation: Reconciliation
    let showCurrencySymbols: ShowCurrencySymbolsEnum

    // MARK: --- Postings

    var postings: [TransactionPosting] {
        reconciliation.transactionsArray.postings
    }

    // MARK: --- Totals

    var totals: SummaryTotals {
        reconciliation.transactionsArray.summaryTotals(
            startBalance: reconciliation.previousEndingBalance,
            currency: reconciliation.transactionsArray.first?.account.currency ?? .unknown
        )
    }

    // MARK: --- Category Rows
    var categoryRows: [CategoryRow] {
        reconciliation.transactionsArray.categoryRows(
            currency: reconciliation.transactionsArray.first?.account.currency ?? .unknown
        )
    }

    // MARK: --- Report Header

    var headerData: ReportHeaderData {
        ReportHeaderData(
            title: "Category Summary Report",
            accountDescription: reconciliation.account.description,
            periodMonth: reconciliation.periodMonth,
            periodYear: reconciliation.periodYear,
            statementDate: reconciliation.statementDate
        )
    }
}


/*
 struct CategoriesSummaryVMOld {
 
 // MARK: --- SummaryTotals
 internal struct SummaryTotals {
 var startBalance: Decimal = 0
 var endBalance: Decimal = 0
 var totalCR: Decimal = 0
 var totalDR: Decimal = 0
 var total: Decimal { get { totalCR + totalDR } }
 var currency: Currency = .unknown
 }
 
 let reconciliation: Reconciliation
 let showCurrencySymbols: ShowCurrencySymbolsEnum
 
 // Flattened postings from reconciliation's transactions
 var postings: [TransactionPosting] {
 reconciliation.transactionsArray.postings
 }
 
 // Totals for the reconciliation
 var totals: SummaryTotals {
 reconciliation.transactionsArray.summaryTotals(
 startBalance: reconciliation.previousEndingBalance,
 currency: reconciliation.transactionsArray.first?.account.currency ?? .unknown
 )
 }
 
 // MARK: --- Computed summaryTotals
 //    internal var summaryTotals: SummaryTotals {
 //        var result = SummaryTotals()
 //        result.currency = currency ?? .unknown
 //
 //        // Identify reconciliation if present
 ////        let reconciliation: Reconciliation? = {
 ////            if let recID = appState.selectedReconciliationID,
 ////               let rec = try? viewContext.existingObject(with: recID) as? Reconciliation {
 ////                return rec
 ////            }
 ////            return nil
 ////        }()
 //
 //        // Compute start balance
 ////        if let rec = reconciliation {
 //            result.startBalance = rec.previousEndingBalance
 ////        }
 //
 //        // Sum all tx amounts
 //        for posting in reconciliation.transactionsArray.postings {
 //            let amount = posting.amount
 //            if amount < 0 { result.totalCR += amount }
 //            else if amount > 0 { result.totalDR += amount }
 //        }
 //
 //        // Compute ending balance
 //        result.endBalance = result.startBalance - result.total
 //        return result
 //    }
 
 // Category rows
 var categoryRows: [CategoryRow] {
 reconciliation.transactionsArray.categoryRows(
 currency: reconciliation.transactionsArray.first?.account.currency ?? .unknown
 )
 }
 
 // Header info for report
 var headerData: ReportHeaderData {
 ReportHeaderData(
 title: "Category Summary Report",
 accountDescription: reconciliation.account.description,
 periodMonth: reconciliation.periodMonth,
 periodYear: reconciliation.periodYear,
 statementDate: reconciliation.statementDate
 )
 }
 }
 */
