//
//  ContentView.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import CoreData
import ItMkLibrary

struct ContentView: View {
    
    // MARK: --- Body
    var body: some View {
        #if os(macOS)
            ContentViewMacOS()
        #else
            ContentViewIOS()
        #endif
        
    }
}
