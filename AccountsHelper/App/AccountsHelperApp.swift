//
//  AccountsHelperApp.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 12/09/2025.
//

import SwiftUI
import ItMkLibrary
import CoreData

@main
struct AccountsHelperApp: App {
    
    // MARK: --- Global Variabless
//    @ObservedObject static var gGlobalAlert = GlobalAlert()
    let persistenceController = PersistenceController.shared
    
    // MARK: --- State: Tracks Global UI states between NavigatorView, CentralView and InspectorView
    @State private var uiState = UIState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject( gGlobalAlert )
                .environment( uiState )
        }
    }
}

