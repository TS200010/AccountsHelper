//
//  PrintMonthlyBalanceSummary.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 01/02/2026.
//

import Foundation
import SwiftUI
import PrintingKit

extension ReconcilliationListView {

    func printMonthlyBalanceSummary() {
#if os(macOS)
        let report = NSMutableString()
        
        // Resolve period
        guard let (month, year) = resolveSelectedPeriod() else { return }

        // Index reconciliations for the period
        let recIndex = indexReconciliationsByAccount(
            month: month,
            year: year,
            context: context
        )

        // --- Header stays the same
        report.append(reportHeader(title: "Monthly Balance Summary", viewContext: context, appState: appState))
        report.append("\n\n")
        
        // --- UKL Current Assets Table
        report.append("UKL\n")
        report.append("Current Assets at Start of Month\n")

        let currentAssetsAccounts: [ReconcilableAccounts] = [
            .CashUKL,
            .BofSCA,
            .BofSPV,
            .BofSIASA,
            .BofSYP,
            .BofSISS,
            .ItMkEquity,
            .AMEX,
            .VISA,
            .CashYEN,
            
        ]

        for account in currentAssetsAccounts {
            let label = "\(account.description) B/F"
            report.append(formattedBalanceLine(
                label: label,
                account: account,
                reconciliationsByAccount: recIndex
            ))
        }
        report.append("Total Current Assets at Start of Month\n\n")
        
        // --- Long Term Assets Table
        report.append("Long Term Assets at Start of Month\n")
        let longTermAssets = [
            "ZOPA", "AltCoin", "Spare 4", "Wine",
            "BARC Spread Trading", "Spare 5", "Premium Bonds"
        ]
        for item in longTermAssets {
            let line = String(format: "\t%-30@ %15@\n", item as NSString, "" as NSString) // added tab
            report.append(line)
        }
        report.append("Total Securities\n")
        report.append("Total Long Term Assets at Start of Month\n")
        report.append("Total Assets at Start of Month\n\n")
        
        // --- Liabilities Table
        report.append("Liabilities at Start of Month\n")
        let liabilities = ["VISA B/F", "BA AMEX B/F"]
        for item in liabilities {
            let line = String(format: "\t%-30@ %15@\n", item as NSString, "" as NSString) // added tab
            report.append(line)
        }
        report.append("Total Liabilities at Start of Month\n\n")
        
        // --- You can continue each major section the same way
        
        // MARK: --- Print
        printReport(report)
#endif
    }
    
    // MARK: --- HELPERS
    // MARK: --- resolveSelectedPeriod
    func resolveSelectedPeriod() -> (month: Int, year: Int)? {
        guard
            let recID = appState.selectedReconciliationID,
            let rec = try? context.existingObject(with: recID) as? Reconciliation
        else {
            return nil
        }

        return (
            month: Int(rec.periodMonth),
            year:  Int(rec.periodYear)
        )
    }

    // MARK: --- fetchReconciliationsForPeriod
    func fetchReconciliationsForPeriod(month: Int, year: Int) throws -> [Reconciliation] {
        let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
        
        request.predicate = NSPredicate(
            format: "periodMonth == %d AND periodYear == %d",
            month,
            year
        )
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Reconciliation.accountCD, ascending: true)
        ]
        
        return try context.fetch(request)
    }

    // MARK: --- indexReconciliationsByAccount
    func indexReconciliationsByAccount(
        month: Int,
        year: Int,
        context: NSManagedObjectContext
    ) -> [ReconcilableAccounts: Reconciliation] {

        let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
        request.predicate = NSPredicate(
            format: "periodMonth == %d AND periodYear == %d",
            month,
            year
        )

        let recs = (try? context.fetch(request)) ?? []

        var index: [ReconcilableAccounts: Reconciliation] = [:]
        for rec in recs {
            index[rec.account] = rec
        }

        return index
    }
    
    // MARK: --- formattedBalanceLine

        
        func formattedBalanceLine(label: String, account: ReconcilableAccounts, reconciliationsByAccount: [ReconcilableAccounts: Reconciliation]) -> String {
            let amountColumn = 40
            let amount: Decimal = reconciliationsByAccount[account]?.openingBalance ?? 0
            let amountStr = AmountFormatter.anyAmountAsString(amount: amount, currency: account.currency, withSymbol: .always)
            let paddingCount = max(1, amountColumn - label.count - amountStr.count)
            let padding = String(repeating: " ", count: paddingCount)
            return "\t\(label)\(padding)\(amountStr)\n"
        }
}

