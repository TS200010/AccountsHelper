//
//  reportHeader.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 10/11/2025.
//

import Foundation
import CoreData

struct ReportHeaderData {
    let title: String
    let accountDescription: String?
    let periodMonth: Int32?
    let periodYear: Int32?
    let statementDate: Date?
}

func reportHeader(_ data: ReportHeaderData) -> String {

    var header = String()
    header.append(data.title)

    if let account = data.accountDescription {
        header.append(" — \(account)\n")

        let periodStr: String
        if let m = data.periodMonth, let y = data.periodYear {
            periodStr = "\(m)/\(y)"
        } else {
            periodStr = "-"
        }

        let statementDateStr =
            data.statementDate?
                .formatted(date: .numeric, time: .omitted)
            ?? "-"

        header.append("Period: \(periodStr) | Statement Date: \(statementDateStr)\n")
    } else {
        header.append("\n")
    }

    return header
}
//
//func reportHeader( title: String, viewContext: NSManagedObjectContext, appState: AppState) -> String {
//    
//    var header = String()
//    header.append(title)
//    if let recID = appState.selectedReconciliationID,
//       let rec = try? viewContext.existingObject(with: recID) as? Reconciliation {
//        header.append(" — \(rec.account.description)\n")
//        let periodStr = "\(rec.periodMonth)/\(rec.periodYear)"
//        let statementDateStr = rec.statementDate?.formatted(date: .numeric, time: .omitted) ?? "-"
//        header.append("Period: \(periodStr) | Statement Date: \(statementDateStr)\n")
//    } else {
//        header.append("\n")
//    }
//    return header
//}
