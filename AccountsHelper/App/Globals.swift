//
//  Globals.swift
//  From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import Foundation
import CoreData
import ItMkLibrary
import SwiftUI


// MARK: --- Global variables used throughout the App

// MARK: --- Which Coredata DEVELOPMENT Store to use. This is not apples Production yet
#if os(iOS)
let gUseLiveStore = true
#else
let gUseLiveStore = false
#endif

// MARK: --- To force upload the Schema (do this on iOS - seems to be more reliable there)
// ... run on both .dev and .live
let gUploadSchema = false


// MARK: --- For debugging Views. The compiler will optimise out unused variables.
// use
let gViewCheck = false

// MARK: --- To remove Magic numbers from the code
let gInspectorMaxWidth:      CGFloat = 350
let gNavigatorMaxWidth:      CGFloat = 350
let gMinToolbarHeight:       CGFloat = 30
let gMaxToolbarHeight:       CGFloat = 30
let gCentralViewHeadingSize: CGFloat = 170
let gInvalidReconciliationGap: Decimal = Decimal(999999)

// MARK: --- Defaults
let gAppName: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "UnknownAppName"
let defaultURL: String = "\\NoSourceFile"

// MARK: --- Global Alert system
var gGlobalAlert: GlobalAlert = GlobalAlert()

// MARK: --- Global UI State
@Observable
class AppState {

    var selectedTransactionID: NSManagedObjectID? = nil
    var selectedNavigatorView: NavigatorViewsEnum = .edit
    var selectedInspectorTransactionIDs: [NSManagedObjectID] = []
    var selectedReconciliationID: NSManagedObjectID? = nil

    // Dummy trigger to force SwiftUI updates
    var inspectorRefreshTrigger: Int = 0

    // Central view stack
    private(set) var centralViewStack: [CentralViewsEnum] = []

    var selectedCentralView: CentralViewsEnum {
        centralViewStack.last ?? .emptyView
    }

    var selectedInspectorView: InspectorViewsEnum = .emptyView

    // MARK: --- Central View Management
    func pushCentralView(_ view: CentralViewsEnum) {
        centralViewStack.append(view)
    }

    func popCentralView() {
        if !centralViewStack.isEmpty {
            centralViewStack.removeLast()
        }
    }

    func replaceCentralView(with view: CentralViewsEnum) {
        centralViewStack = [view]
    }

    // MARK: --- Inspector View Management
    func replaceInspectorView(with view: InspectorViewsEnum) {
        selectedInspectorView = view
    }

    // MARK: --- Force Inspector Refresh
    func refreshInspector() {
        DispatchQueue.main.async {
            self.inspectorRefreshTrigger += 1
        }
    }
}

