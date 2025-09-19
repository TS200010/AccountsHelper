//
//  NavigatorEditView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 12/09/2025.
//

import SwiftUI
import ItMkLibrary

struct NavigatorEditView: View {
    
    // MARK: --- Environment
    @Environment(UIState.self) var uiState
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: --- Properties
    @State private var showingEditTransactionSheet = false
    @State private var showingBrowseTransactionsView = false
    
    // MARK: --- Body
    var body: some View {
        
        VStack {
            Button("Edit Transaction") {
                #if os(macOS)
                uiState.selectedCentralView = .editTransaction
                #else
                uiState.selectedCentralView = .editTransaction
                showingEditTransactionSheet = true
                #endif
                
            }
            
            Button("Add Random Transactions") {
                let _ = Transaction.generateRandomTransactions(in: viewContext)
            }
            .disabled( gUseLiveStore )
            
            Button("Browse Transactions") {
                #if os(macOS)
                uiState.selectedCentralView = .browseTransactions
                #else
                uiState.selectedCentralView = .browseTransactions
                showingBrowseTransactionsView = true
                #endif
                
            }

            Button("Edit Currency") {
                uiState.selectedCentralView = .editCurrency
            }

            Button("Edit Payer") {
                uiState.selectedCentralView = .editPayer
            }
            
            Button("Edit Payee") {
                uiState.selectedCentralView = .editPayee
            }
        }
        .buttonStyle( ItMkButton() )
        .sheet(isPresented: $showingEditTransactionSheet) {
                EditTransactionView()
        }
        .sheet(isPresented: $showingBrowseTransactionsView) {
                BrowseTransactionsView()
        }
    }
}
