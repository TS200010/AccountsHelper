//
//  NavigatorViewToolbar.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary

import SwiftUI
import ItMkLibrary

// MARK: --- NavigatorViewToolbar
struct NavigatorViewToolbar: View {

    // MARK: --- Environment
    @Environment(AppState.self) var appState

    private let buttonNames: [(systemName: String, view: NavigatorViewsEnum)] = [
        ("square.and.pencil", .edit),
        ("arrow.triangle.2.circlepath", .reconcile),
        ("magnifyingglass", .browse),
        ("doc.text", .report)
    ]
    
    private let buttonHeight: CGFloat = 32

    // MARK: --- Body
    var body: some View {
        HStack(spacing: 0) {
            ForEach(buttonNames, id: \.view) { item in
                NavigatorToolbarButton(
                    systemName: item.systemName,
                    isSelected: appState.selectedNavigatorView == item.view,
                    action: { appState.selectedNavigatorView = item.view }
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

struct NavigatorToolbarButton: View {
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


//// MARK: --- NavigatorViewToolbar
//struct NavigatorViewToolbar: View {
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
//                // MARK: --- Edit Transaction Button
//                ItMkToolBarButton(
//                    action: { appState.selectedNavigatorView = .edit },
//                    name: "square.and.pencil",
//                    isSelected: appState.selectedNavigatorView == .edit
//                )
//                
//                // MARK: --- Reconcile Button
//                ItMkToolBarButton(
//                    action: { appState.selectedNavigatorView = .reconcile },
//                    name: "arrow.triangle.2.circlepath",
//                    isSelected: appState.selectedNavigatorView == .reconcile
//                )
//                
//                // MARK: --- Browse Button
//                ItMkToolBarButton(
//                    action: { appState.selectedNavigatorView = .browse },
//                    name: "magnifyingglass",
//                    isSelected: appState.selectedNavigatorView == .browse
//                )
//                
//                // MARK: --- Report Button
//                ItMkToolBarButton(
//                    action: { appState.selectedNavigatorView = .report },
//                    name: "doc.text",
//                    isSelected: appState.selectedNavigatorView == .report
//                )
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: gMaxToolbarHeight)
//        .buttonStyle(.plain)
//        .background(Color(Color.ItMkPlatformWindowBackgroundColor))
//        .topBorder()
//        .bottomBorder()
//        .if(gViewCheck) { view in view.background(.green) }
//    }
//}
