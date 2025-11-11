//
// Untitled.swift
// From SkeletonMacOSApp
//
// Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary

struct CentralViewsHomeView: View {
    
    // MARK: --- Body
    var body: some View {
        
        VStack ( spacing: 0 ) {
            
//            CentralViewToolbar( ) .if( gViewCheck ) { view in view.border( .pink )}
                
            CentralViews( ) .if( gViewCheck ) { view in view.border( .cyan )}
            
        } .background( Color.ItMkPlatformWindowBackgroundColor )
          .if( gViewCheck ) { view in view.border( .green )}
    }
}
