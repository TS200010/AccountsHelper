//
//  PrintCategoriesSummary.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 10/11/2025.
//

import Foundation
import SwiftUI
import PrintingKit

extension CategoriesSummaryView {
    
    
    private var reportHeaderData: ReportHeaderData {
        if let rec = reconciliation {
            return ReportHeaderData(
                title: "Category Summary Report",
                accountDescription: rec.account.description,
                periodMonth: rec.periodMonth,
                periodYear: rec.periodYear,
                statementDate: rec.statementDate
            )
        } else {
            return ReportHeaderData(
                title: "Category Summary Report",
                accountDescription: nil,
                periodMonth: nil,
                periodYear: nil,
                statementDate: nil
            )
        }
    }

    
//    func printCategoriesSummary() {
//        
//#if os(macOS)
//        
//        let totals = summaryTotals
//        let rows = categoryRows
//        
//        let report = NSMutableString()
//        
//        // MARK: --- Build Report Header
//
//        let headerData: ReportHeaderData
//        if let rec = reconciliation {
//            headerData = ReportHeaderData(
//                title: "Category Summary Report",
//                accountDescription: rec.account.description,
//                periodMonth: rec.periodMonth,
//                periodYear: rec.periodYear,
//                statementDate: rec.statementDate
//            )
//        } else {
//            headerData = ReportHeaderData(
//                title: "Category Summary Report",
//                accountDescription: nil,
//                periodMonth: nil,
//                periodYear: nil,
//                statementDate: nil
//            )
//        }
//        
//        report.append( reportHeader( headerData ) )
//        
////        report.append(reportHeader(title: "Category Summary Report", viewContext: viewContext, appState: appState) )
//        
//        // MARK: --- Build Column Headings
//        report.append("\n")
//        report.append(String(format: "%-30@ %15@\n", "Category" as NSString, "Total" as NSString))
//        report.append(String(repeating: "-", count: 46) + "\n")
//        
//        // MARK: --- Build Rows
//        for row in rows {
//            let paddedName = row.category.description.padding(toLength: 30, withPad: " ", startingAt: 0)
//            let totalStr = AmountFormatter.anyAmountAsString(amount: row.total, currency: row.currency, withSymbol: showCurrencySymbols )
//            let paddedTotal = String(repeating: " ", count: max(0, 15 - totalStr.count)) + totalStr
//            report.append("\(paddedName)\(paddedTotal)\n")
//        }
//        
//        // MARK: --- Report Footer
//        report.append("\n" + String(repeating: "-", count: 46) + "\n")
//        let reportCurrency: Currency = rows.first?.currency ?? .unknown
//        report.append(formatFooterLine("Starting Balance", totals.startBalance, currency: reportCurrency, withSymbol: showCurrencySymbols))
//        report.append(formatFooterLine("Total CR", totals.totalCR, currency: reportCurrency, withSymbol: showCurrencySymbols))
//        report.append(formatFooterLine("Total DR", totals.totalDR, currency: reportCurrency, withSymbol: showCurrencySymbols))
//        report.append(formatFooterLine("Net Total", totals.total, currency: reportCurrency, withSymbol: showCurrencySymbols))
//        report.append(formatFooterLine("Ending Balance", totals.endBalance, currency: reportCurrency, withSymbol: showCurrencySymbols))
//        
//        // MARK: --- Print
//        printReport(report)
//        
//#endif
//    }
    
}
