//
//  AccountsHelperApp.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 19/09/2025.
//

import SwiftUI
import CoreData

@main
struct AccountsHelperApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
