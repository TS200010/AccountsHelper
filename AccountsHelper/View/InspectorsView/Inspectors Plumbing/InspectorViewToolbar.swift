//
//  InspectorViewToolbar.swift
//  From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary

// MARK: --- InspectorViewToolbar
struct InspectorViewToolbar: View {

    // MARK: --- Environment
    @Environment(AppState.self) var appState
    
    // MARK: --- Body
    var body: some View {
        VStack(spacing: 0) {
            
            HStack {
                
                // MARK: --- viewTransaction Button
                ItMkToolBarButton(
                    action: { appState.selectedInspectorView = .viewTransaction },
                    name: "star.hexagon.fill",
                    isSelected: appState.selectedInspectorView == .viewTransaction
                )
                
                // MARK: --- viewCategoryBreakdown Button
                ItMkToolBarButton(
                    action: { appState.selectedInspectorView = .viewCategoryBreakdown },
                    name: "xmark.seal",
                    isSelected: appState.selectedInspectorView == .viewCategoryBreakdown
                )
                
                // MARK: --- InspectorViewThree Button
                ItMkToolBarButton(
                    action: { appState.selectedInspectorView = .InspectorViewThree },
                    name: "heart.fill",
                    isSelected: appState.selectedInspectorView == .InspectorViewThree
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: gMaxToolbarHeight)
        .bottomBorder()
        .buttonStyle(.plain)
        .background(Color(Color.ItMkPlatformTextBackgroundColor))
    }
}
