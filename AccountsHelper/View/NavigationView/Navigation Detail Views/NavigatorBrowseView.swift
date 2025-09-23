//
//  NavigatorBrowseView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 12/09/2025.
//

import SwiftUI
import ItMkLibrary

struct NavigatorBrowseView: View {
    
    @Environment(AppState.self) var appState
    
    var body: some View {
        
        VStack {
            Button("Browse Transactions") {
                appState.selectedCentralView = .browseTransactions
            }

            Button("Browse Currencies") {
                appState.selectedCentralView = .browseCurrencies
            }

            Button("Browse Payers") {
                appState.selectedCentralView = .browsePayees
            }
            
            Button("Browse Payees") {
                appState.selectedCentralView = .browsePayers
            }
        } .buttonStyle( ItMkButton() )
    }
}

