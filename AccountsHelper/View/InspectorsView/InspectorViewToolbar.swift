//
//  InspectorViewToolbar.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary

struct InspectorViewToolbar: View {

    @Environment(UIState.self) var uiState
    
    // MARK: --- Body
    var body: some View {
        
        VStack( spacing:0 ) {
            
            HStack( /*alignment: .center*/ ) {
                
                // MARK: --- InspectorViewOne Button
                ItMkToolBarButton(
                    action: { uiState.selectedInspectorView = .InspectorViewOne  },
                    name: "star.hexagon.fill",
                    isSelected: uiState.selectedInspectorView == .InspectorViewOne )
                
                // MARK: --- InspectorViewTwo Button
                ItMkToolBarButton(
                    action: { uiState.selectedInspectorView = .InspectorViewTwo  },
                    name: "xmark.seal",
                    isSelected: uiState.selectedInspectorView == .InspectorViewTwo )
                
                // MARK: --- InspectorViewThree Button
                ItMkToolBarButton(
                    action: { uiState.selectedInspectorView = .InspectorViewThree  },
                    name: "heart.fill",
                    isSelected: uiState.selectedInspectorView == .InspectorViewThree )
            }
        } .frame( maxWidth: .infinity, maxHeight: gMaxToolbarHeight )
          .bottomBorder( )
          .buttonStyle( .plain )
          .background( Color( Color.platformTextBackgroundColor ) )
    }
}
