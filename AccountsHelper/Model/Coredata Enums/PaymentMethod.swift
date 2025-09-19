//
//  PaymentMethod.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 29/09/2024.
//

import Foundation
import ItMkLibrary



@objc enum PaymentMethod: Int32, CaseIterable, Codable, HasStringRepresentation, CustomStringConvertible {
    
    case CASH           = 1
    case AMEX           = 2
    case VISA           = 3
    case bankOfScotland = 4
    case unknown        = 99
    
    init( _ s: String ) {
        self = PaymentMethod.fromString( s )
    }
    
    func rawValueAsString() -> String {
        return self.rawValue.description
    }
    
    var description: String {
        switch self {
            case .CASH:             return String( localized: "Cash" )
            case .AMEX:             return String( localized: "AMEX" )
            case .VISA:             return String( localized: "VISA" )
            case .bankOfScotland:   return String( localized: "BankOfS" )
            case .unknown:          return String( localized: "Unknown" )
        }
    }
    
    static func fromString( _ s: String ) -> PaymentMethod {
        switch s {
        case "Cash":          return Self.CASH
        case "AMEX":          return Self.AMEX
        case "VISA":          return Self.VISA
        case "BankOfS":       return Self.bankOfScotland
        default:              return Self.unknown
        }
    }

    
    // TODO: Not sure we need these
    
    static func fromInt( _ i: Int ) -> PaymentMethod {
        
        switch i {
            case 1:  return Self.CASH
            case 2:  return Self.AMEX
            case 3:  return Self.VISA
            case 4:  return Self.bankOfScotland
            default: return Self.unknown
        }
    }
    
    static func fromInt32( _ i: Int32 ) -> PaymentMethod {
        
        return PaymentMethod.fromInt( Int( i ) )
    }
}
