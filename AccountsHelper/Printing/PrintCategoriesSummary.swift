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
    
    func formatFooterLine(_ label: String, _ amount: Decimal, currency: Currency, withSymbol: ShowCurrencySymbolsEnum ) -> String {
        
        let symbolSettingRaw = UserDefaults.standard.string(forKey: "showCurrencySymbols") ?? "always"
        let symbolSetting = ShowCurrencySymbolsEnum(rawValue: symbolSettingRaw) ?? .always
        
        let amountStr = Transaction.anyAmountAsString(amount: amount, currency: currency, withSymbol: symbolSetting )
//        // Format the number according to the currency
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .currency
//        formatter.locale = currency.localeForCurrency
//        
//        // Handle zero-minor-unit currencies like JPY
//        switch currency {
//        case .JPY:
//            formatter.maximumFractionDigits = 0
//            formatter.minimumFractionDigits = 0
//        default:
//            formatter.maximumFractionDigits = 2
//            formatter.minimumFractionDigits = 2
//        }
//        
//        // Construct the number
//        let amountStr = formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
        let paddedLabel = label.padding(toLength: 30, withPad: " ", startingAt: 0)
        let paddedAmount = String(repeating: " ", count: max(0, 15 - amountStr.count)) + amountStr
        return "\(paddedLabel)\(paddedAmount)\n"
    }

    
    func printCategoriesSummary() {
        
#if os(macOS)
        //        DispatchQueue.main.async {
        
//        let showCurrencySymbols = true
        let totals = summaryTotals
        let rows = categoryRows
        
        // MARK: --- Build Report Header
        let report = NSMutableString()
        report.append(reportHeader(title: "Category Summary Report", viewContext: viewContext, appState: appState) )

        // MARK: --- Build Column Headings
        report.append("\n")
        report.append(String(format: "%-30@ %15@\n", "Category" as NSString, "Total" as NSString))
        report.append(String(repeating: "-", count: 46) + "\n")
        
        // MARK: --- Build Rows
        for row in rows {
            let paddedName = row.category.description.padding(toLength: 30, withPad: " ", startingAt: 0)
            let totalStr = Transaction.anyAmountAsString(amount: row.total, currency: row.currency, withSymbol: showCurrencySymbols )
            let paddedTotal = String(repeating: " ", count: max(0, 15 - totalStr.count)) + totalStr
            report.append("\(paddedName)\(paddedTotal)\n")
        }

        // MARK: --- Report Footer
        report.append("\n" + String(repeating: "-", count: 46) + "\n")
        let reportCurrency: Currency = rows.first?.currency ?? .unknown
        report.append(formatFooterLine("Starting Balance", totals.startBalance, currency: reportCurrency, withSymbol: showCurrencySymbols))
        report.append(formatFooterLine("Total CR", totals.totalCR, currency: reportCurrency, withSymbol: showCurrencySymbols))
        report.append(formatFooterLine("Total DR", totals.totalDR, currency: reportCurrency, withSymbol: showCurrencySymbols))
        report.append(formatFooterLine("Net Total", totals.total, currency: reportCurrency, withSymbol: showCurrencySymbols))
        report.append(formatFooterLine("Ending Balance", totals.endBalance, currency: reportCurrency, withSymbol: showCurrencySymbols))

        // MARK: --- Print
        printReport(report)
        
#endif
    }
}
