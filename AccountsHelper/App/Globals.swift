//
//  Globals.swift
//  From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import Foundation
import ItMkLibrary
import SwiftUI

//public extension View {
//    
//    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
//        
//        if condition {
//            transform(self)
//        } else {
//            self
//        }
//    }
//}

// MARK: --- Global variables used throughout the App
#if os(ios)
let gUseLiveStore = true
#else
let gUseLiveStore = false
#endif


// MARK: --- For debugging Views. The compiler will optimise out unused variables.
// use
let gViewCheck = false

// MARK: --- To remove Magic numbers from the code
let gInspectorMaxWidth:      CGFloat = 350
let gNavigatorMaxWidth:      CGFloat = 350
let gMinToolbarHeight:       CGFloat = 30
let gMaxToolbarHeight:       CGFloat = 30
let gCentralViewGeadingSize: CGFloat = 170

// MARK: --- Defaults
let gAppName: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "UnknownAppName"
let defaultURL: String = "\\NoSourceFile"

// MARK: --- Global Alert system
var gGlobalAlert: GlobalAlert = GlobalAlert()

// MARK: --- Global UI State
@Observable
class UIState {
    
    var selectedRecord: Int = 0
    
    var selectedNavigatorView: NavigatorViewsEnum = .emptyView
    
    var selectedCentralView: CentralViewsEnum = .emptyView
    
    var selectedInspectorView: InspectorViewsEnum = .emptyView
    
    func reset() -> Void {
        selectedRecord = 0
    }
}
