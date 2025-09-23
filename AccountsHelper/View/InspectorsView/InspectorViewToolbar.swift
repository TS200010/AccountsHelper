//
//  InspectorViewToolbar.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary

struct InspectorViewToolbar: View {

    @Environment(AppState.self) var appState
    
    // MARK: --- Body
    var body: some View {
        
        VStack( spacing:0 ) {
            
            HStack( /*alignment: .center*/ ) {
                
                // MARK: --- InspectorViewOne Button
                ItMkToolBarButton(
                    action: { appState.selectedInspectorView = .viewTransaction  },
                    name: "star.hexagon.fill",
                    isSelected: appState.selectedInspectorView == .viewTransaction )
                
                // MARK: --- InspectorViewTwo Button
                ItMkToolBarButton(
                    action: { appState.selectedInspectorView = .InspectorViewTwo  },
                    name: "xmark.seal",
                    isSelected: appState.selectedInspectorView == .InspectorViewTwo )
                
                // MARK: --- InspectorViewThree Button
                ItMkToolBarButton(
                    action: { appState.selectedInspectorView = .InspectorViewThree  },
                    name: "heart.fill",
                    isSelected: appState.selectedInspectorView == .InspectorViewThree )
            }
        } .frame( maxWidth: .infinity, maxHeight: gMaxToolbarHeight )
          .bottomBorder( )
          .buttonStyle( .plain )
          .background( Color( Color.platformTextBackgroundColor ) )
    }
}
