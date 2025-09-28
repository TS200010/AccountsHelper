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
    @State private var appState = AppState()
    
    init() {
        // Enable Core Data + CloudKit debug logging
        UserDefaults.standard.set(true, forKey: "com.apple.CoreData.CloudKitDebug")
        
        // Any other setup
        assert(MergeField.allCases.count == 19, "🚨 MergeField count mismatch! Did you add a new field?")
    }
    
    var body: some Scene {
        
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject( gGlobalAlert )
                .environment( appState )
        }

    }
}

