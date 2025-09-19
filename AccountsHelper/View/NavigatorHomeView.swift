//
//  NavigatorHomeView.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary

struct NavigatorHomeView: View {
    
    // MARK: --- Body
    var body: some View {
        
        VStack ( spacing: 0 ) {
            
            NavigatorViewToolbar( )

            NavigatorViews( )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background( Color( Color.platformWindowBackgroundColor ) )
        .if( gViewCheck ) { view in view.border( Color.cyan )}
    }
}
