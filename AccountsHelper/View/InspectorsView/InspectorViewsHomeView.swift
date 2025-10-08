//
//  InspectorViewsHomeView.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary

struct InspectorViewsHomeView: View {
    
    // MARK: --- Body
    var body: some View {
        
        VStack ( spacing: 0 ) {
            
            InspectorViewToolbar( )
            
            InspectorViews( )
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .background( Color( Color.ItMklatformTextBackgroundColor ) )
         .if( gViewCheck ) { view in view.border( .red )}
    }
}
