//
//  ContentViewMacOS.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/09/2025.
//

import SwiftUI
import ItMkLibrary

struct ContentViewMacOS: View {
    
    @EnvironmentObject var gGlobalAlert: GlobalAlert
    
    // A Placeholder for a Finite State Machine for the model
    //    @Environment(ModelFSM.self) var modelFSM
    @State fileprivate var showingNavigators = true
    @State fileprivate var showingInspectors = true
    @State fileprivate var showingStatusbar  = true
    @State fileprivate var showingSettings = false
    
    // MARK: --- Body
    var body: some View {
        
        VStack ( spacing: 0 ) {
            NavigationSplitView {
                NavigatorHomeView()
                    .navigationSplitViewColumnWidth( min: 250, ideal: 300, max: gNavigatorMaxWidth )
                
            } detail: {
                CentralViewsHomeView()
                    .navigationTitle( gAppName )
                    .inspector( isPresented: $showingInspectors ) {
                        InspectorViewsHomeView()
                            .inspectorColumnWidth(min: 250, ideal: 300, max: gInspectorMaxWidth)
                    }
            }
            .toolbar {
                ToolbarItem( placement: .confirmationAction ) {
                    Button( action: { withAnimation { showingInspectors.toggle() } },
                            label:  { Image( systemName: "sidebar.trailing") }
                    )
                }
                
                
                ToolbarItem( placement: .confirmationAction) {
                    Button( action: { withAnimation { showingSettings.toggle() } },
                            label: { Image(systemName: "gearshape") }
                    )
                }
                
                // MARK: --- Add more ToolbarItems here as .principal if needed ... eg
                ToolbarItem( placement: .principal ) {
                    Button( action: { withAnimation { /* Action here */ } },
                            label:  { Image( systemName: "trash.slash.circle.fill") }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("\(gGlobalAlert.alert)",
                   isPresented: $gGlobalAlert.isFaultAlert ) {
                Button("OK", role: .cancel ) {
                    gGlobalAlert.reset()
                } }
            .alert("\(gGlobalAlert.alert)",
                    isPresented: $gGlobalAlert.isErrorAlert ) {
                Button("OK", role: .cancel ) {
                    gGlobalAlert.reset()
                } }
            .if( gViewCheck ) { view in view.border( .blue )}
 
            if showingStatusbar {
                StatusBarView( status: "To Implement ... Status Bar" )
            }
        }
    }
}
