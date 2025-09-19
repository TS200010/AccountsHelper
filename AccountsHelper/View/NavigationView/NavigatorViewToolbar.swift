//
//  NavigatorViewToolbar.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary

struct NavigatorViewToolbar: View {
    
    @Environment(UIState.self)             var uiState
    
    // MARK: --- Body
    var body: some View {
        
        VStack( spacing:0 ) {
            
            HStack( /*alignment: .center*/ ) {
                
                // MARK: --- Edit Transaction Button
                ItMkToolBarButton(
                    action: { uiState.selectedNavigatorView = .edit  },
                    name: "square.and.pencil",
                    isSelected: uiState.selectedNavigatorView == .edit )
                
                // MARK: --- Reconcile Button
                ItMkToolBarButton(
                    action: { uiState.selectedNavigatorView = .reconcile   },
                    name: "arrow.triangle.2.circlepath",
                    isSelected: uiState.selectedNavigatorView == .reconcile )
                
                // MARK: --- Browse Button
                ItMkToolBarButton(
                    action: { uiState.selectedNavigatorView = .browse  },
                    name: "magnifyingglass",
                    isSelected: uiState.selectedNavigatorView == .browse )
                
                // MARK: --- Repport Button
                ItMkToolBarButton(
                    action: { uiState.selectedNavigatorView = .report  },
                    name: "doc.text",
                    isSelected: uiState.selectedNavigatorView == .report )
            }

            
        } .frame( maxWidth: .infinity, maxHeight: gMaxToolbarHeight )
          .buttonStyle( .plain )
          .background( Color( Color.platformWindowBackgroundColor ) )
          .topBorder( )
          .bottomBorder( )
          .if( gViewCheck ) { view in view.background( .green )}
    }
}

