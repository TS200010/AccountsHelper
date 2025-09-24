//
//  NavigatorEditAddView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 12/09/2025.
//

import SwiftUI
import ItMkLibrary

struct NavigatorEditAddView: View {
    
    // MARK: --- Environment
    @Environment(AppState.self) var appState
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: --- Properties
//    @State private var showingAddTransactionSheet = false
//    @State private var showingBrowseTransactionsView = false
    
    // MARK: --- Body
    var body: some View {
        
        VStack {
            Button("Add Transaction") {
                #if os(macOS)
                appState.replaceCentralView(with: .addTransaction)
//                appState.selectedCentralView = .addTransaction
                #else
                appState.selectedCentralView = .addTransaction
//                showingEditAddTransactionSheet = true
                #endif
                
            }
            
            Button("Add Random Transactions") {
                let _ = Transaction.generateRandomTransactions(in: viewContext)
            }
            .disabled( gUseLiveStore )
            
            Button("Import AMEX CSV Transactions") {
                appState.replaceCentralView(with: .AMEXCSVImport)
//                appState.selectedCentralView = .AMEXCSVImport
            }
            
            Button("Browse Transactions") {
                #if os(macOS)
                appState.replaceCentralView(with: .browseTransactions)
//                appState.selectedCentralView = .browseTransactions
                #else
                appState.selectedCentralView = .browseTransactions
                showingBrowseTransactionsView = true
                #endif
                
            }
            
            
            Button("Browse Categories") {
                #if os(macOS)
                appState.replaceCentralView(with: .browseCategories)
//                appState.selectedCentralView = .browseCategories
                #else
                appState.selectedCentralView = .browseTransactions
                showingBrowseTransactionsView = true
                #endif
                
            }

            Button("Edit Currency") {
                appState.replaceCentralView(with: .editCurrency)
//                appState.selectedCentralView = .editCurrency
            }

            Button("Edit Payer") {
                appState.replaceCentralView(with: .editPayer)
//                appState.selectedCentralView = .editPayer
            }
            
            Button("Edit Payee") {
                appState.replaceCentralView(with: .editPayee)
//                appState.selectedCentralView = .editPayee
            }
        }
        .buttonStyle( ItMkButton() )
//        .sheet(isPresented: $showingAddTransactionSheet) {
//                EditTransactionView()
//        }
//        .sheet(isPresented: $showingBrowseTransactionsView) {
//                BrowseTransactionsView()
//        }
    }
}
