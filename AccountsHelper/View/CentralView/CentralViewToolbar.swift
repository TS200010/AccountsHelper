//
//  File.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary

struct CentralViewToolbar: View {
    
    @Environment(UIState.self) var uiState
    
    // MARK: --- Body
    var body: some View {

        HStack {
            
            Text(uiState.selectedCentralView.rawValue )
                .frame( width: gCentralViewHeadingSize, alignment: .leading )
                .padding( [.leading], 10 )
            
            Spacer()
            
            HStack( /*alignment: .center*/ ) {
                
                // MARK: --- Add Transaction Button
                ItMkToolBarButton(
                    action: { uiState.selectedCentralView = .addTransaction  },
                    name: "plus.app",
                    isSelected: uiState.selectedCentralView == .addTransaction )
                
                Divider()
                    .frame( width: 1)
                
                // Pad the last button
                .padding( .trailing, 10 )
            }
        } .frame( maxWidth: .infinity, minHeight: gMinToolbarHeight, maxHeight: gMaxToolbarHeight)
          .bottomBorder()
          .buttonStyle(.plain)
          .background( Color( Color.platformTextBackgroundColor ) )
    }
}
