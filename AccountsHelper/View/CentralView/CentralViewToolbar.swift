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
                .frame( width: gCentralViewGeadingSize, alignment: .leading )
                .padding( [.leading], 10 )
            
            Spacer()
            
            HStack( /*alignment: .center*/ ) {
                
                // MARK: --- Edit Transaction Button
                ItMkToolBarButton(
                    action: { uiState.selectedCentralView = .editTransaction  },
                    name: "square.and.arrow.up.circle",
                    isSelected: uiState.selectedCentralView == .editTransaction )
                

                
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
