//
//  Payer.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/09/2025.
//

import Foundation

import ItMkLibrary

@objc enum Payer: Int32, CaseIterable, Codable, HasStringRepresentation, CustomStringConvertible {
    
    case tony            = 1
    case yokko           = 2
    case ACHelper        = 98
    case unknown         = 99
    
    init( _ s: String ) {
        self = Payer.fromString( s )
    }
    
    func rawValueAsString() -> String {
        return self.rawValue.description
    }
    
    static func fromString( _ s: String ) -> Payer {
        switch s {
        case "Tony":                return .tony
        case "Yokko":               return .yokko
        case "ACHelper":            return .ACHelper
        case "ANTHONY J STANNERS":  return .tony
        case "YOSHIKO STANNERS":    return .yokko
        default:        return .unknown
        }
    }
    
    var description: String {
        switch self {
            case .tony:             return String( localized: "Tony" )
            case .yokko:            return String( localized: "Yokko" )
            case .ACHelper:         return String( localized: "ACHelper" )
            case .unknown:          return String( localized: "Unknown" )
        }
    }
    
    // TODO: Not sure we need these
    
    static func fromInt( _ i: Int ) -> Payer {
        
        switch i {
            case 1:  return Self.tony
            case 2:  return Self.yokko
            case 98: return Self.ACHelper
            case 99: return Self.unknown
            default: return Self.unknown
        }
    }
    
    static func fromInt32( _ i: Int32 ) -> Currency {
        
        return Currency.fromInt( Int( i ) )
    }
}
