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

// MARK: --- Which CoreData DEVELOPMENT Store to use. This is not Apple's Production yet
#if os(iOS)
// MARK: --- iOS
var gUseLiveStore = true
#else
// MARK: --- macOS
var gUseLiveStore = false
#endif

// MARK: --- To force upload the Schema (do this on iOS - seems to be more reliable there)
// ... run on both .dev and .live
let gUploadSchema = false

// MARK: --- For debugging Views. The compiler will optimise out unused variables.
let gViewCheck = false

// MARK: --- To remove Magic numbers from the code
let gInspectorMaxWidth:         CGFloat = 350
let gNavigatorMaxWidth:         CGFloat = 350
let gMinToolbarHeight:          CGFloat = 30
let gMaxToolbarHeight:          CGFloat = 30
let gCentralViewHeadingSize:    CGFloat = 170
let gInvalidReconciliationGap:  Decimal = Decimal(999_999)
let gNumTransactionAttributes:  Int     = 16 // Number minus 2 as we do not care about TimeStamp, Category and AccoiuntungPeriod
let gAmountFieldWidth:          Int     = 10
let gHStackSpacing:             CGFloat = 12.0
let gLabelWidth:                CGFloat = 140
let gPickerWidth:               CGFloat = 200
let gRowHeight:                 CGFloat = 35
#if os(macOS)
let gInterFieldSpacing: CGFloat = 0
#else
let gInterFieldSpacing: CGFloat = 3
#endif

// MARK: --- Defaults
let gAppName: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "UnknownAppName"
let gDefaultURL: String = "\\NoSourceFile"
let gDefaultZeroAmountRepresentation: String = ""

// MARK: --- User State Persistence
let gColumnWidthsKey = "BrowseTransactionsView_ColumnWidths"

// MARK: --- Global Alert system
var gGlobalAlert: GlobalAlert = GlobalAlert()

// MARK: --- Global UI State
@Observable
class AppState {

    // MARK: --- Properties
    var selectedTransactionID: NSManagedObjectID? = nil
    var selectedNavigatorView: NavigatorViewsEnum = .edit
    var selectedInspectorTransactionIDs: [NSManagedObjectID] = []
    var selectedReconciliationID: NSManagedObjectID? = nil
    var inspectorRefreshTrigger: Int = 0 // Dummy trigger to force SwiftUI updates

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

    func refreshInspector() {
        DispatchQueue.main.async {
            self.inspectorRefreshTrigger += 1
        }
    }
}
