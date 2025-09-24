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
    @State private var showingAddTransactionSheet = false
    @State private var showingBrowseTransactionsView = false
    
    // MARK: --- Body
    var body: some View {
        
        VStack {
            Button("Add Transaction") {
                #if os(macOS)
                appState.selectedCentralView = .addTransaction
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
                appState.selectedCentralView = .AMEXCSVImport
            }
            
            Button("Browse Transactions") {
                #if os(macOS)
                appState.selectedCentralView = .browseTransactions
                #else
                appState.selectedCentralView = .browseTransactions
                showingBrowseTransactionsView = true
                #endif
                
            }
            
            
            Button("Browse Categories") {
                #if os(macOS)
                appState.selectedCentralView = .browseCategories
                #else
                appState.selectedCentralView = .browseTransactions
                showingBrowseTransactionsView = true
                #endif
                
            }

            Button("Edit Currency") {
                appState.selectedCentralView = .editCurrency
            }

            Button("Edit Payer") {
                appState.selectedCentralView = .editPayer
            }
            
            Button("Edit Payee") {
                appState.selectedCentralView = .editPayee
            }
        }
        .buttonStyle( ItMkButton() )
        .sheet(isPresented: $showingAddTransactionSheet) {
                EditTransactionSheet()
        }
        .sheet(isPresented: $showingBrowseTransactionsView) {
                BrowseTransactionsView()
        }
    }
}
