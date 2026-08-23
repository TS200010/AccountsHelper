//
//  HelpersForBrowseTxView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 29/01/2026.
//

import Foundation

// MARK: --- BrowseTransactionsMode
enum BrowseTransactionsMode {
    case generalBrowsing
    case reconciliationAssignmentBrowsing
}

// MARK: --- To work aroound a SwiftUI bug
func safeUIUpdate(_ action: @escaping () -> Void) {
    action()
//    DispatchQueue.main.async {
//        withAnimation(.none) {
//            action()
//        }
//    }
}
