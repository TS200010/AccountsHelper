//
//  ContentViewMacOS.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/09/2025.
//

import SwiftUI
import ItMkLibrary

// MARK: --- ContentViewMacOS
struct ContentViewMacOS: View {
    
    // MARK: --- Environment
    @EnvironmentObject var gGlobalAlert: GlobalAlert
    @Environment(AppState.self) var appState

    // MARK: --- Local State
    @State fileprivate var showingNavigators = true
    @State fileprivate var showingInspectors = true
    @State fileprivate var showingStatusbar  = true
    @State fileprivate var showingSettings = false
    
    // MARK: --- Body
    var body: some View {
        VStack(spacing: 0) {
            navigationSplitViewSection
            if showingStatusbar {
                StatusBarView(status: "To Implement ... Status Bar")
            }
        }
    }
}

// MARK: --- NAVIGATION SPLIT VIEW
extension ContentViewMacOS {
    
    // MARK: --- NavigationSplitViewSection
    private var navigationSplitViewSection: some View {
        NavigationSplitView {
            NavigatorHomeView()
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: gNavigatorMaxWidth)
        } detail: {
            CentralViewsHomeView()
                .navigationTitle(gAppName)
                .inspector(isPresented: $showingInspectors) {
                    InspectorViewsHomeView()
                        .inspectorColumnWidth(min: 250, ideal: 300, max: gInspectorMaxWidth)
                }
        }
        .toolbar { toolbarSection }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .alert("\(gGlobalAlert.alert)", isPresented: $gGlobalAlert.isFaultAlert) {
            Button("OK", role: .cancel) { gGlobalAlert.reset() }
        }
        .alert("\(gGlobalAlert.alert)", isPresented: $gGlobalAlert.isErrorAlert) {
            Button("OK", role: .cancel) { gGlobalAlert.reset() }
        }
        .if(gViewCheck) { view in view.border(.blue) }
    }
}

// MARK: --- TOOLBARS
extension ContentViewMacOS {
    
    // MARK: --- ToolbarSection
    private var toolbarSection: some ToolbarContent {
        Group {
            // Toggle Inspector Sidebar
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    withAnimation { showingInspectors.toggle() }
                } label: {
                    Image(systemName: "sidebar.trailing")
                }
            }
            
            // Open Settings
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    withAnimation { showingSettings.toggle() }
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            
            // Back Button
            ToolbarItem(placement: .navigation) {
                Button {
                    appState.popCentralView()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .disabled(appState.centralViewStack.isEmpty)
            }
            
            // Principal Action Button (placeholder)
            ToolbarItem(placement: .principal) {
                Button {
                    withAnimation { /* Action here */ }
                } label: {
                    Image(systemName: "trash.slash.circle.fill")
                }
            }
        }
    }
}
