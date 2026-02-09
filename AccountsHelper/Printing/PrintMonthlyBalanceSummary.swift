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
        guard let (month, year) = resolvePreviousPeriod() else { return }
        guard let (currentMonth, currentYear) = resolveSelectedPeriod() else { return }

        // Index reconciliations for the previous period
        let recIndex = indexReconciliationsByAccount(
            month: month,
            year: year,
            context: context
        )
        
        // Index reconciliations for the current period
        let currentRecIndex = indexReconciliationsByAccount(
            month: currentMonth,
            year: currentYear,
            context: context
        )

        report.append(reportHeader(title: "Monthly Balance Summary", viewContext: context, appState: appState))
        report.append("\n\n")
        
        // --- UKL Current Assets Table
        report.append("UKL\n")
        report.append("Current Assets at Start of Month\n")
        report.append("\t" + String(repeating: " ", count: 32) + "Previous           Closing\n")

        let currentAssetsAccounts: [ReconcilableAccounts] = [
            .CashUKL,
            .BofSCA_64,
            .BofSPV_82,
            .BofSIASA_62,
            .BofSYP_06,
            .BofSISS_43,
            .ItMkEquity,
        ]

        for account in currentAssetsAccounts {
            let label = "\(account.description) B/F"

            let opening = openingBalance(for: account)

            let current = currentRecIndex[account]?.endingBalance ?? 0

            report.append(
                formattedTwoColumnBalanceLine(
                    label: label,
                    openingAmount: opening,
                    currentAmount: current,
                    currency: account.currency
                )
            )
        }
        
        report.append("\nLiabilities Start of Month\n")
        let liabilitiesAccounts: [ReconcilableAccounts] = [
            .VISA,
            .AMEX,

        ]
        for account in liabilitiesAccounts {
            let label = "\(account.description) B/F"
            report.append(formattedBalanceLine(
                label: label,
                account: account,
                reconciliationsByAccount: recIndex
            ))
        }
        
        report.append("\nBofS Joint Income\n")
        report.append( reportLineForATotal(descr: "NCR Pension", category: .NCRPension, account: .BofSPV_82))
        report.append( reportLineForATotal(descr: "Interest Income", category: .IntDivIncome, account: .BofSPV_82))
        report.append( reportLineForATotal(descr: "Other Income", category: .OtherIncome, account: .BofSPV_82))
        
        report.append("\nBofS Joint Transfers to/from Current Assets\n")
        report.append( reportLineForATotal(descr: "T/F to TMB Japan", category: .ToTMB, account: .BofSPV_82))
        report.append( reportLineForATotal(descr: "T/F to BofS Classic", category: .ToBofSCA_64, account: .BofSPV_82))
        report.append( reportLineForATotal(descr: "T/F to ItMk", category: .ToItMkEquity, account: .BofSPV_82))
        report.append( reportLineForATotal(descr: "T/F to General Hold", category: .ToBofSYP_06, account: .BofSPV_82))
        report.append( reportLineForATotal(descr: "T/F to UKL Cash", category: .ToCashUKL, account: .BofSPV_82))
//        report.append( reportLineForATotal(descr: "T/F to Mum", category: .OtherIncome, account: .BofSPV_82))

        report.append("\nBofS Classic Asset Transfers\n")
        report.append( reportLineForATotal(descr: "T/F To A J Bell", category: .ToAJBell, account: .BofSCA_64))
        report.append( reportLineForATotal(descr: "T/F To AltCoin", category: .unknown, account: .BofSCA_64))
        report.append( reportLineForATotal(descr: "T/F To BofS Joint", category: .ToBofSPV_82, account: .BofSCA_64))
        
        
        
        // --- YEN Current Assets Table
        report.append("\nYEN\n")
        report.append("YEN Assets at Start of Period\n")
        report.append("\t" + String(repeating: " ", count: 32) + "Previous           Closing\n")
        let YENAssetsAccounts: [ReconcilableAccounts] = [
            .CashYEN,
        ]
        for account in YENAssetsAccounts {
            let label = "\(account.description) B/F"

            let opening = openingBalance(for: account)
            let closing = currentRecIndex[account]?.endingBalance ?? 0

            report.append(
                formattedTwoColumnBalanceLine(
                    label: label,
                    openingAmount: opening,
                    currentAmount: closing,
                    currency: account.currency
                )
            )
        }

        
        

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
    
    // MARK: --- resolvePreviousPeriod
    func resolvePreviousPeriod() -> (month: Int, year: Int)? {
        guard var period = resolveSelectedPeriod() else {
            return nil
        }

        period.month -= 1
        if period.month == 0 {
            period.month = 12
            period.year -= 1
        }

        return period
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
        if label.hasPrefix( "Unk" ) {
            return "\n"
        }
        let amountColumn = 40
        let amount = openingBalance(for: account)
        let amountStr = AmountFormatter.anyAmountAsString(amount: amount, currency: account.currency, withSymbol: .always)
        let paddingCount = max(1, amountColumn - label.count - amountStr.count)
        let padding = String(repeating: " ", count: paddingCount)
        return "\t\(label)\(padding)\(amountStr)\n"
    }
    
    // MARK: --- openingBalance
    func openingBalance(for account: ReconcilableAccounts) -> Decimal {
        guard let (currentMonth, currentYear) = resolveSelectedPeriod() else { return 0 }
        
        var month = currentMonth
        var year = currentYear
        
        // Try current period first
        if let rec = indexReconciliationsByAccount(month: month, year: year, context: context)[account],
           rec.openingBalance != 0 {
            return rec.openingBalance
        }
        
        // Look back until we find an ending balance
        for _ in 1...12 { // max 12 months back to prevent infinite loop
            (month, year) = Reconciliation.previousPeriod(month: month, year: year)
            
            if let prevRec = indexReconciliationsByAccount(month: month, year: year, context: context)[account],
               prevRec.endingBalance != 0 {
                return prevRec.endingBalance
            }
        }
        
        return 0
    }

    // MARK: --- formattedTwoColumnBalanceLine
    func formattedTwoColumnBalanceLine(
        label: String,
        openingAmount: Decimal,
        currentAmount: Decimal,
        currency: Currency
    ) -> String {

        let openingColumn = 40
        let currentColumn = 58

        let openingStr = AmountFormatter.anyAmountAsString(
            amount: openingAmount,
            currency: currency,
            withSymbol: .always
        )

        let currentStr = AmountFormatter.anyAmountAsString(
            amount: currentAmount,
            currency: currency,
            withSymbol: .always
        )

        let pad1 = max(1, openingColumn - label.count - openingStr.count)
        let pad2 = max(1, currentColumn - openingColumn - currentStr.count)

        return "\t\(label)"
             + String(repeating: " ", count: pad1)
             + openingStr
             + String(repeating: " ", count: pad2)
             + currentStr
             + "\n"
    }

}

// MARK: --- Category Total Line
extension ReconcilliationListView {
    
    /// Returns a single report line for the total of a given category and account in the current period.
    func reportLineForATotal(descr: String, category: Category, account: ReconcilableAccounts) -> String {
        // Resolve current period
        guard let (month, year) = resolveSelectedPeriod(),
              category != .unknown else {
            let zeroStr = AmountFormatter.anyAmountAsString(amount: 0, currency: account.currency, withSymbol: .always)
            let padding = max(1, 40 - descr.count - zeroStr.count)
            return "\t\(descr)" + String(repeating: "-", count: padding) + zeroStr + "\n"
        }
        
        // Fetch all transactions for this account in the current period
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        let startDate = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1))!
        let endDate: Date = {
            let comps = DateComponents(year: year, month: month + 1, day: 1)
            return Calendar.current.date(from: comps)?.addingTimeInterval(-1) ?? Date.distantFuture
        }()
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "accountCD == %d", account.rawValue),
            NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", startDate as NSDate, endDate as NSDate),
            NSPredicate(format: "categoryCD == %d OR splitCategoryCD == %d OR categoryCD == %d", category.rawValue, category.rawValue, category.rawValue)
        ])
        
        let transactionsForCategory: [Transaction] = (try? context.fetch(request)) ?? []
        
        // Sum amounts in account currency
        let totalAmount = transactionsForCategory.reduce(Decimal(0)) { sum, tx in
            sum + tx.convertToPaymentCurrency(amount: tx.txAmount)
        }
        
        let amountStr = AmountFormatter.anyAmountAsString(amount: totalAmount, currency: account.currency, withSymbol: .always)
        
        // Align with opening/previous column
        let openingColumn = 40
        let paddingCount = max(1, openingColumn - descr.count - amountStr.count)
        let padding = String(repeating: " ", count: paddingCount)
        
        return "\t\(descr)" + padding + amountStr + "\n"
    }
}
