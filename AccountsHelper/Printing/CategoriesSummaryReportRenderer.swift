//
//  CategoriesSummaryReportRenderer.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 10/02/2026.
//

import Foundation
import CoreData

struct CategoriesSummaryReportRenderer {

    static func buildReport(from vm: CategoriesSummaryVM) -> NSMutableString {

        let totals = vm.totals
        let rows = vm.categoryRows

        let report = NSMutableString()

        // MARK: --- Header
        report.append(reportHeader(vm.headerData))

        // MARK: --- Column Headings
        report.append("\n")
        report.append(String(format: "%-30@ %15@\n",
                             "Category" as NSString,
                             "Total" as NSString))
        report.append(String(repeating: "-", count: 46) + "\n")

        // MARK: --- Rows
        for row in rows {
            let paddedName =
                row.category.description
                    .padding(toLength: 30, withPad: " ", startingAt: 0)

            let totalStr =
                AmountFormatter.anyAmountAsString(
                    amount: row.total,
                    currency: row.currency,
                    withSymbol: vm.showCurrencySymbols
                )

            let paddedTotal =
                String(repeating: " ", count: max(0, 15 - totalStr.count)) + totalStr

            report.append("\(paddedName)\(paddedTotal)\n")
        }

        // MARK: --- Footer
        report.append("\n" + String(repeating: "-", count: 46) + "\n")

        let currency = rows.first?.currency ?? .unknown

        report.append(formatFooterLine("Starting Balance",
                                       totals.startBalance,
                                       currency: currency,
                                       withSymbol: vm.showCurrencySymbols))

        report.append(formatFooterLine("Total CR",
                                       totals.totalCR,
                                       currency: currency,
                                       withSymbol: vm.showCurrencySymbols))

        report.append(formatFooterLine("Total DR",
                                       totals.totalDR,
                                       currency: currency,
                                       withSymbol: vm.showCurrencySymbols))

        report.append(formatFooterLine("Net Total",
                                       totals.total,
                                       currency: currency,
                                       withSymbol: vm.showCurrencySymbols))

        report.append(formatFooterLine("Ending Balance",
                                       totals.endBalance,
                                       currency: currency,
                                       withSymbol: vm.showCurrencySymbols))

        return report
    }
    
    static func formatFooterLine(_ label: String, _ amount: Decimal, currency: Currency, withSymbol: ShowCurrencySymbolsEnum ) -> String {
        
        let symbolSettingRaw = UserDefaults.standard.string(forKey: "showCurrencySymbols") ?? "always"
        let symbolSetting = ShowCurrencySymbolsEnum(rawValue: symbolSettingRaw) ?? .always
        
        let amountStr = AmountFormatter.anyAmountAsString(amount: amount, currency: currency, withSymbol: symbolSetting )
        
        let paddedLabel = label.padding(toLength: 30, withPad: " ", startingAt: 0)
        let paddedAmount = String(repeating: " ", count: max(0, 15 - amountStr.count)) + amountStr
        return "\(paddedLabel)\(paddedAmount)\n"
    }
}


