//
//  CategoryPrintHelper.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 05/10/2025.
//

import SwiftUI
import AppKit

struct CategoryPrintHelper {
    
        static func printCategoriesSummaryView(predicate: NSPredicate? = nil) {
            let view = CategoriesSummaryView(predicate: predicate, isPrinting: true)
            let hostingView = NSHostingView(rootView: view)
            hostingView.frame = NSRect(x: 0, y: 0, width: 595, height: 842)
            let printOperation = NSPrintOperation(view: hostingView, printInfo: .shared)
            printOperation.showsPrintPanel = true
            printOperation.showsProgressPanel = true
            printOperation.run()
        }

}



