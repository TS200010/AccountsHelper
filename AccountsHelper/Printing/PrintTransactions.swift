//
//  PrintTransactions.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 10/11/2025.
//

import Foundation
import SwiftUI
import PrintingKit

extension BrowseTransactionsView {
    
    func printTransactions() {
        
        var totalCR: Decimal = 0
        var totalDR: Decimal = 0


        let columnWidths: [String: Int] = [
            "Date":          10,
            "Category":      15,
            "Amount":        12,
            "FX":            6,
            "Split":         12,
            "SplitCategory": 15,
            "Payee":         15
        ]
        
        func padded(_ string: String, column: String, alignRight: Bool = false, spacing: Int = 1) -> String {
            guard let width = columnWidths[column] else { return string }
            let actualWidth = max(width, string.count)
            let padding = String(repeating: " ", count: actualWidth - string.count)
            let space = String(repeating: " ", count: spacing)
            return alignRight ? padding + string + space : string + padding + space
        }
        
        // Compute Totals
        
        for tx in transactions {
            let amount = tx.txAmount
            if amount < 0 {
                totalCR += amount
            } else if amount > 0 {
                totalDR += amount
            }
        }
        let netTotal = totalCR + totalDR
        
        let report = NSMutableString()
        
        // MARK: --- Build the report header
        report.append(reportHeader(title: "Full Transactions Report", viewContext: viewContext, appState: appState) )
        
        // MARK: --- Build column headings
        report.append("\n")
        report.append(
            padded("Date", column: "Date") +
            padded("Category", column: "Category") +
            padded("Amount", column: "Amount", alignRight: true) +
            padded("FX", column: "FX") +
            padded("Split", column: "Split") +
            padded("Split Category", column: "SplitCategory") +
            padded("Payee", column: "Payee") +
            "\n"
        )
        report.append(String(repeating: "-", count: columnWidths.values.reduce(0, +)) + "\n")
        
        // MARK: --- Add transactions
        for tx in transactions {
            let dateStr     = tx.transactionDate?.formatted(date: .numeric, time: .omitted) ?? ""
            let categoryStr = tx.category.description
            let amountStr   = tx.txAmountAsString( withSymbol: showCurrencySymbols )
            let fxStr       = tx.currency != .GBP ? (tx.exchangeRateAsString() ?? "") : ""
            let splitStr    = tx.splitAmount != 0 ?  tx.splitAmountAsString( withSymbol: showCurrencySymbols ) : ""
            let splitCatStr = tx.splitAmount != 0 ?  tx.splitCategory.description : ""
            let payeeStr    = String((tx.payee ?? "" ).prefix(15))
            
            report.append(
                padded(dateStr, column: "Date") +
                padded(categoryStr, column: "Category") +
                padded(amountStr, column: "Amount", alignRight: true) +
                padded(fxStr, column: "FX") +
                padded(splitStr, column: "Split") +
                padded(splitCatStr,column: "SplitCategory") +
                padded(payeeStr, column: "Payee") +
                "\n"
            )
        }
        
        // MARK: --- Add Footer
        func appendSummaryLine(title: String, amount: Decimal) {
            let amountStr = AmountFormatter.anyAmountAsString(
                amount: amount,
                currency: transactions.first?.currency ?? .GBP,
                withSymbol: showCurrencySymbols
            )
            
            // Pad for all columns before Amount
            let line =
                padded(title, column: "Date") +            // label
                padded("", column: "Category") +          // empty
                padded(amountStr, column: "Amount", alignRight: true) + "\n"
            
            report.append(line)
        }
        
        report.append(String(repeating: "-", count: columnWidths.values.reduce(0, +)) + "\n")

        // TODO: --- Make this work for mixed currencies
        appendSummaryLine(title: "Total CR:", amount: totalCR)
        appendSummaryLine(title: "Total DR:", amount: totalDR)
        appendSummaryLine(title: "Net Total:", amount: netTotal)
        
        
        // MARK: --- Print
        printReport( report )
        //       // MARK: --- Create attributes for monospaced font
        //       let attrs: [NSAttributedString.Key: Any] = [
        //           .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        //       ]
        //       let attributedReport = NSAttributedString(string: report as String, attributes: attrs)
        //
        //       // MARK: --- Print
        //       let printer = Printer.shared
        //       do {
        //           try printer.printAttributedString(
        //               attributedReport,
        //               config: Printer.PageConfiguration(
        //                   pageSize: CGSize(width: 595, height: 842),
        //                   pageMargins: Printer.PageMargins(top: 36, left: 36, bottom: 36, right: 36)
        //               )
        //           )
        //       } catch {
        //           print("Failed to print: \(error)")
        //       }
    }
}

