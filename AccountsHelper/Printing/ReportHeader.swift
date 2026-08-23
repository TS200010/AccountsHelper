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
    var header = ""

    // Title
    header.append(data.title)
    
    // Optional account description
    if let account = data.accountDescription, !account.isEmpty {
        header.append(" — \(account)")
    }
    header.append("\n") // always end line after title/account

    // Period
    let periodStr: String
    if let m = data.periodMonth, let y = data.periodYear {
        periodStr = "\(m)/\(y)"
        header.append("Period: \(periodStr)  ")
    }

    // Statement date§
    if let statementDateStr = data.statementDate {
        let str = statementDateStr.formatted(date: .numeric, time: .omitted)
        header.append("Statement Date: \(str)  ")
    }

    // Current print timestamp
    let nowFormatter = DateFormatter()
    nowFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let nowStr = nowFormatter.string(from: Date())
    header.append("Report generated: \(nowStr)\n")

    // 6️⃣ Separator line
    header.append(String(repeating: "-", count: 80))
    header.append("\n")

    return header
}

//func reportHeader(_ data: ReportHeaderData) -> String {
//
//    var header = String()
//    header.append(data.title)
//
//    if let account = data.accountDescription {
//        header.append(" — \(account)\n")
//
//        let periodStr: String
//        if let m = data.periodMonth, let y = data.periodYear {
//            periodStr = "\(m)/\(y)"
//        } else {
//            periodStr = "-"
//        }
//
//        let statementDateStr =
//            data.statementDate?
//                .formatted(date: .numeric, time: .omitted)
//            ?? "-"
//
//        header.append("Period: \(periodStr) | Statement Date: \(statementDateStr)\n")
//    } else {
//        header.append("\n")
//    }
//
//    return header
//}
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
