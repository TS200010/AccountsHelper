//
//  Currency.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/09/2025.
//

import Foundation
import ItMkLibrary

@objc enum Currency: Int32, CaseIterable, Codable, HasStringRepresentation, CustomStringConvertible {
    
    
    case GBP             = 1
    case USD             = 2
    case JPY             = 3
    case EUR             = 4
    case unknown         = 99
    
    init( _ s: String ) {
        self = Currency.fromString( s )
    }
    
    func rawValueAsString() -> String {
        return self.rawValue.description
    }
    
    static func fromString( _ s: String ) -> Currency {
        switch s {
        case "GBP":     return .GBP
        case "USD":     return .USD
        case "JPY":     return .JPY
        case "EUR":     return .EUR
        default:        return .unknown
        }
    }
    
    var description: String {
        switch self {
            case .GBP:             return String( localized: "GBP" )
            case .USD:             return String( localized: "USD" )
            case .JPY:             return String( localized: "JPY" )
            case .EUR:             return String( localized: "EUR" )
            case .unknown:          return String( localized: "Unknown" )
        }
    }
    
    // TODO: Not sure we need these
    
    static func fromInt( _ i: Int ) -> Currency {
        
        switch i {
            case 1:  return Self.GBP
            case 2:  return Self.USD
            case 3:  return Self.JPY
            case 4:  return Self.EUR
            default: return Self.unknown
        }
    }
    
    static func fromInt32( _ i: Int32 ) -> Currency {
        
        return Currency.fromInt( Int( i ) )
    }
}
