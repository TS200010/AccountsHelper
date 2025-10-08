//
//  CentralViewTwo.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary


struct CentralViewTwo: View {
    
    // MARK: --- Body
    var body: some View {
        
        Text("Central View Two")
        
        Button("Cause Error") {
            gGlobalAlert.publish(alert: "Error triggered.", type: .error )
        }
        Button("Cause Fault") {
            gGlobalAlert.publish(alert: "Fault triggered.", type: .fault )
        }
    }
}


