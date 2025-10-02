//
//  InspectorViews.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import CoreData
import ItMkLibrary

struct InspectorViews: View {
    
    @Environment(AppState.self) var appState
    
    // MARK: --- Body
    var body: some View {
        
        VStack (spacing: 0) {
            
            switch appState.selectedInspectorView {
                
            case .viewTransaction:
                InspectTransaction()
                
            case .viewCategoryBreakdown:
                InspectorCategoryBreakdown( )
                
            case .InspectorViewThree:
                InspectorViewThree()
                
            default:
                Text("Select an action from the toolbar" )
                
            }
        } .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background( Color( Color.platformWindowBackgroundColor ) )
          .if( gViewCheck ) { view in view.border( .red )}
    }
}
