//
//  InspectorViewToolbar.swift
//  From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary

struct InspectorViewToolbar: View {

    @Environment(AppState.self) var appState
    
    private let buttonNames: [(systemName: String, view: InspectorViewsEnum)] = [
        ("list.bullet", .viewTransaction),
        ("tag", .viewCategoryBreakdown),
        ("heart.fill", .InspectorViewThree)
    ]
    
    private let buttonHeight: CGFloat = 32
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(buttonNames, id: \.view) { item in
                InspectorToolbarButton(
                    systemName: item.systemName,
                    isSelected: appState.selectedInspectorView == item.view,
                    action: { appState.selectedInspectorView = item.view }
                )
            }
        }
        .frame(height: buttonHeight)
        .background(
            RoundedRectangle(cornerRadius: buttonHeight / 2)
                .fill(Color(Color.ItMkPlatformWindowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: buttonHeight / 2)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(4)
    }
}

struct InspectorToolbarButton: View {
    let systemName: String
    let isSelected: Bool
    let action: () -> Void
    private let buttonHeight: CGFloat = 32
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .frame(maxWidth: .infinity, minHeight: buttonHeight)
                .contentShape(Rectangle()) // full area clickable
                .background(
                    RoundedRectangle(cornerRadius: buttonHeight / 2)
                        .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(isSelected ? Color.accentColor : Color.primary)
    }
}



//
//import SwiftUI
//import ItMkLibrary
//
//// MARK: --- InspectorViewToolbar
//struct InspectorViewToolbar: View {
//
//    // MARK: --- Environment
//    @Environment(AppState.self) var appState
//    
//    // MARK: --- Body
//    var body: some View {
//        VStack(spacing: 0) {
//            
//            HStack {
//                
//                // MARK: --- viewTransaction Button
//                ItMkToolBarButton(
//                    action: { appState.selectedInspectorView = .viewTransaction },
//                    name: "star.hexagon.fill",
//                    isSelected: appState.selectedInspectorView == .viewTransaction
//                )
//                
//                // MARK: --- viewCategoryBreakdown Button
//                ItMkToolBarButton(
//                    action: { appState.selectedInspectorView = .viewCategoryBreakdown },
//                    name: "xmark.seal",
//                    isSelected: appState.selectedInspectorView == .viewCategoryBreakdown
//                )
//                
//                // MARK: --- InspectorViewThree Button
//                ItMkToolBarButton(
//                    action: { appState.selectedInspectorView = .InspectorViewThree },
//                    name: "heart.fill",
//                    isSelected: appState.selectedInspectorView == .InspectorViewThree
//                )
//            }
//        }
//        .frame(width: 36) // compact width like Xcode
//        .padding(.top, 8)
//        .background(Color(NSColor.windowBackgroundColor))
//        .cornerRadius(6)
//        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
//        .bottomBorder()
////        .frame(maxWidth: .infinity, maxHeight: gMaxToolbarHeight)
////        .bottomBorder()
////        .buttonStyle(.plain)
////        .background(Color(Color.ItMkPlatformTextBackgroundColor))
//    }
//}
