//
//  PrintFullSummary.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 15/02/2026.
//

import Foundation
import CoreData

extension ReconcilliationListView {
    
    // MARK: --- printFullSummary
    func printFullSummary() {
        spoolMonthlyBalanceSummary()
        spoolReportsForSelectedPeriod(
            context: context,
            showCurrencySymbols: .always
        )
    }
    
    // MARK: --- spoolReportsForSelectedPeriod
    func spoolReportsForSelectedPeriod(context: NSManagedObjectContext, showCurrencySymbols: ShowCurrencySymbolsEnum) {
        let spooler = ReportSpooler.shared
//        spooler.clear() // start fresh

        // Get the selected reconciliation ID
        guard let selectedID = appState.selectedReconciliationID,
              let selectedReco = try? context.existingObject(with: selectedID) as? Reconciliation
        else { return }

        let month = selectedReco.periodMonth
        let year = selectedReco.periodYear

        // Fetch all reconciliations for the same period
        let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "periodMonth == %d", month),
            NSPredicate(format: "periodYear == %d", year)
        ])
        request.sortDescriptors = [
            NSSortDescriptor(key: "accountCD", ascending: true)
        ]

        let recons: [Reconciliation]
        do {
            recons = try context.fetch(request)
        } catch {
            print("Failed to fetch reconciliations for period \(month)/\(year): \(error)")
            return
        }

        // Build and append reports
        for reco in recons {
            let vm = CategoriesSummaryVM(reconciliation: reco, showCurrencySymbols: showCurrencySymbols)
            let report = CategoriesSummaryReportRenderer.buildReport(from: vm)
            spooler.append(report as String) // append to spooler
        }

        #if os(macOS)
        spooler.print()
        #endif
    }

    
    func spoolCategoriesReports(for reconciliations: [Reconciliation], showCurrencySymbols: ShowCurrencySymbolsEnum) {
        let spooler = ReportSpooler.shared
        spooler.clear() // optional: start fresh

        for (_, reco) in reconciliations.enumerated() {
            // Create VM
            let vm = CategoriesSummaryVM(reconciliation: reco, showCurrencySymbols: showCurrencySymbols)
            
            // Build report
            let report = CategoriesSummaryReportRenderer.buildReport(from: vm)
            
            // Append to spooler
            spooler.append(report as String) // spooler expects String
            
        }
    }
    
    func fetchReconciliations(forMonth month: Int32? = nil, year: Int32? = nil, context: NSManagedObjectContext) -> [Reconciliation] {
        let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
        
        var predicates: [NSPredicate] = []

        if let month = month {
            predicates.append(NSPredicate(format: "periodMonth == %d", month))
        }
        if let year = year {
            predicates.append(NSPredicate(format: "periodYear == %d", year))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        // Optional: sort by period and account for consistent order
        request.sortDescriptors = [
            NSSortDescriptor(key: "periodYear", ascending: true),
            NSSortDescriptor(key: "periodMonth", ascending: true),
            NSSortDescriptor(key: "account.name", ascending: true)
        ]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch reconciliations: \(error)")
            return []
        }
    }


}
