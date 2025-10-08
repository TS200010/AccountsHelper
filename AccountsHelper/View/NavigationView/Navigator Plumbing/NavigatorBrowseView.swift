//
//  NavigatorBrowseView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 12/09/2025.
//

import SwiftUI
import ItMkLibrary

// MARK: --- NavigatorBrowseView
struct NavigatorBrowseView: View {
    
    // MARK: --- Environment
    @Environment(AppState.self) var appState
    
    // MARK: --- Body
    var body: some View {
        VStack(spacing: 12) {
            
            Button("Browse Transactions") {
                appState.pushCentralView(.browseTransactions(nil))
            }
            
            Button("Browse Currencies") {
                appState.pushCentralView(.browseCurrencies)
            }
            
            Button("Browse Payers") {
                appState.pushCentralView(.browsePayers)
            }
            
            Button("Browse Payees") {
                appState.pushCentralView(.browsePayees)
            }
            
        }
        .buttonStyle(ItMkButton())
        .padding()
    }
}
