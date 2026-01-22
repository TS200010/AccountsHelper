//
//  ReportHeader.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 10/11/2025.
//

import Foundation
import CoreData

func reportHeader( title: String, viewContext: NSManagedObjectContext, appState: AppState) -> String {
    
    var header = String()
    header.append(title)
    if let recID = appState.selectedReconciliationID,
       let rec = try? viewContext.existingObject(with: recID) as? Reconciliation {
        header.append(" — \(rec.account.description)\n")
        let periodStr = "\(rec.periodMonth)/\(rec.periodYear)"
        let statementDateStr = rec.statementDate?.formatted(date: .numeric, time: .omitted) ?? "-"
        header.append("Period: \(periodStr) | Statement Date: \(statementDateStr)\n")
    } else {
        header.append("\n")
    }
    return header
}
