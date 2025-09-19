//
//  DebitCredit.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 14/09/2025.
//

import Foundation
import ItMkLibrary

@objc enum DebitCredit: Int32, CaseIterable, Codable, HasStringRepresentation, CustomStringConvertible {
    
    case DR             = 1
    case CR             = 2
    case unknown        = 99
    
    func rawValueAsString() -> String {
        switch self {
        case .DR:       return "DR"
        case .CR:       return "CR"
        case .unknown:  return "Unknown"
        }
    }
    
    var description: String {
        switch self {
        case .DR:           return String( localized: "DR" )
        case .CR:           return String( localized: "CR" )
        case .unknown:      return String( localized: "Unknown" )
        }
    }

    
}
