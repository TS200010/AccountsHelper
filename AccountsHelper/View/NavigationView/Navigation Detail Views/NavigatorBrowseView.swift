//
//  NavigatorBrowseView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 12/09/2025.
//

import SwiftUI
import ItMkLibrary

struct NavigatorBrowseView: View {
    
    @Environment(UIState.self) var uiState
    
    var body: some View {
        
        VStack {
            Button("Browse Transactions") {
                uiState.selectedCentralView = .browseTransactions
                #if os(iOS)
                BrowseTransactionsView()
                #endif
            }

            Button("Browse Currencies") {
                uiState.selectedCentralView = .browseCurrencies
            }

            Button("Browse Payers") {
                uiState.selectedCentralView = .browsePayees
            }
            
            Button("Browse Payees") {
                uiState.selectedCentralView = .browsePayers
            }
        } .buttonStyle( ItMkButton() )
    }
}

