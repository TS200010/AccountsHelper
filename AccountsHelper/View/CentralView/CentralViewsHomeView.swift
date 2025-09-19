//
//  Untitled.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary

// TODO: --- Move to ItMkLibrary
extension Color {
    static var platformWindowBackgroundColor: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(UIColor.systemBackground)
        #endif
    }
}

// TODO: --- Move to ItMkLibrary
extension Color {
    static var platformTextBackgroundColor: Color {
        #if os(macOS)
        Color(NSColor.textBackgroundColor)
        #else
        Color(UIColor.systemBackground) // iOS equivalent
        #endif
    }
}

struct CentralViewsHomeView: View {
    
    // MARK: --- Body
    var body: some View {
        
        VStack ( spacing: 0 ) {
            
            CentralViewToolbar( ) .if( gViewCheck ) { view in view.border( .pink )}
                
            CentralViews( ) .if( gViewCheck ) { view in view.border( .cyan )}
            
        } .background( Color.platformWindowBackgroundColor )
          .if( gViewCheck ) { view in view.border( .green )}
    }
}
