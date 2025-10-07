//
//  Payer.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/09/2025.
//

import Foundation
import ItMkLibrary

@objc enum Payer: Int32, CaseIterable, Codable, HasStringRepresentation, CustomStringConvertible, Identifiable {
    
    // MARK: --- Cases
    case tony        = 1
    case yokko       = 2
    case ACHelper    = 98
    case unknown     = 99
    
    // MARK: --- Identifiable
    var id: Int32 { self.rawValue }
    
    // MARK: --- Initializer from String
    init(_ s: String) {
        self = Payer.fromString(s)
    }
    
    // MARK: --- Raw Value Helper
    func rawValueAsString() -> String {
        return self.rawValue.description
    }
    
    // MARK: --- String Conversion
    static func fromString(_ s: String) -> Payer {
        switch s {
        case "Tony":                return .tony
        case "Yokko":               return .yokko
        case "ACHelper":            return .ACHelper
        case "ANTHONY J STANNERS":  return .tony
        case "YOSHIKO STANNERS":    return .yokko
        default:                    return .unknown
        }
    }
    
    // MARK: --- Int Conversion Helpers
    static func fromInt(_ i: Int) -> Payer {
        switch i {
        case 1:   return .tony
        case 2:   return .yokko
        case 98:  return .ACHelper
        case 99:  return .unknown
        default:  return .unknown
        }
    }
    
    static func fromInt32(_ i: Int32) -> Payer {
        return Payer.fromInt(Int(i))
    }
    
    // MARK: --- CustomStringConvertible
    var description: String {
        switch self {
        case .tony:      return String(localized: "Tony")
        case .yokko:     return String(localized: "Yokko")
        case .ACHelper:  return String(localized: "ACHelper")
        case .unknown:   return String(localized: "Unknown")
        }
    }
}
