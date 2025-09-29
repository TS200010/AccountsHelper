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
//                appState.selectedCentralView = .browseTransactions( nil )
                appState.pushCentralView(.browseTransactions( nil ))
            }

            Button("Browse Currencies") {
//                appState.selectedCentralView = .browseCurrencies
                appState.pushCentralView(.browseCurrencies)
            }

            Button("Browse Payers") {
//                appState.selectedCentralView = .browsePayees
                appState.pushCentralView(.browsePayees)
            }
            
            Button("Browse Payees") {
//                appState.selectedCentralView = .browsePayers
                appState.pushCentralView(.browsePayers)
            }
        } .buttonStyle( ItMkButton() )
    }
}

