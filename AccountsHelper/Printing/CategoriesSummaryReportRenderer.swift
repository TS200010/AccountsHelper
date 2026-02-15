//
//  CategoriesSummaryReport.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 10/02/2026.
//

import Foundation
import CoreData

struct CategoriesSummaryReport {

    let reconciliation: Reconciliation
    let transactions: [Transaction]
    let showCurrencySymbols: ShowCurrencySymbolsEnum

    let viewContext: NSManagedObjectContext
    let appState: AppState
}

