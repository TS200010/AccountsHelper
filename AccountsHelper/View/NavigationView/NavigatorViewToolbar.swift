//
//  NavigatorViewToolbar.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary

struct NavigatorViewToolbar: View {
    
    @Environment(AppState.self)             var appState
    
    // MARK: --- Body
    var body: some View {
        
        VStack( spacing:0 ) {
            
            HStack( /*alignment: .center*/ ) {
                
                // MARK: --- Edit Transaction Button
                ItMkToolBarButton(
                    action: { appState.selectedNavigatorView = .edit  },
                    name: "square.and.pencil",
                    isSelected: appState.selectedNavigatorView == .edit )
                
                // MARK: --- Reconcile Button
                ItMkToolBarButton(
                    action: { appState.selectedNavigatorView = .reconcile   },
                    name: "arrow.triangle.2.circlepath",
                    isSelected: appState.selectedNavigatorView == .reconcile )
                
                // MARK: --- Browse Button
                ItMkToolBarButton(
                    action: { appState.selectedNavigatorView = .browse  },
                    name: "magnifyingglass",
                    isSelected: appState.selectedNavigatorView == .browse )
                
                // MARK: --- Repport Button
                ItMkToolBarButton(
                    action: { appState.selectedNavigatorView = .report  },
                    name: "doc.text",
                    isSelected: appState.selectedNavigatorView == .report )
            }

            
        } .frame( maxWidth: .infinity, maxHeight: gMaxToolbarHeight )
          .buttonStyle( .plain )
          .background( Color( Color.ItMkPlatformWindowBackgroundColor ) )
          .topBorder( )
          .bottomBorder( )
          .if( gViewCheck ) { view in view.background( .green )}
    }
}

