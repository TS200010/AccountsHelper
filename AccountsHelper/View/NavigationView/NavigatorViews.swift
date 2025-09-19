//
//  NavigatorViews.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary

struct NavigatorViews: View {
    
    // MARK: --- Environment
    @Environment(UIState.self) var uiState
    
    // MARK: --- Body
    var body: some View {
        
        VStack (spacing: 0) {
            
            switch uiState.selectedNavigatorView {
                
            case .emptyView:
                Text("Select an action from the toolbar" )
                
            case .edit:
                NavigatorEditView()
                
            case .reconcile:
                Text("Navigator Reconcile View" )
                
            case .browse:
                NavigatorBrowseView()
                
            case .report:
                Text("Navigator Report View" )

            case .navigatorViewTwo:
                NavigatorViewTwo()
            
            case .navigatorViewThree:
                NavigatorViewThree()
                

            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity )
        .background( Color( Color.platformWindowBackgroundColor ) ) .if( gViewCheck ) { view in view.background( .yellow )}
        .if( gViewCheck ) { view in view.border( .yellow )}
    }
}

