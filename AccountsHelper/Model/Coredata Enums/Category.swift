//
//  Category.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 14/09/2025.
//

import Foundation


import Foundation
import ItMkLibrary

@objc enum Category: Int32, CaseIterable, Codable, HasStringRepresentation, CustomStringConvertible {
    
    // Do not use zero as it is also effectively unknown
    case Spare1             = 1
    case GardenHome         = 2
    case Insurance          = 3
    case CarTax             = 4
    case CarMaintenance     = 5
    case Spare2             = 6
    case Maintenance        = 7
    case FoodHousehold      = 8
    case AMWAY              = 9
    case Wine               = 10
    case Entertainments     = 11
    case Travel             = 12
    case TransportPetrol    = 13
    case BooksCDs           = 14
    case Medical            = 15
    case OfficeCompAV       = 16
    case Hobbies            = 17
    case Presents           = 18
    case Spare3             = 19
    case MiscOther          = 20
    case ToBalance          = 21
    case Spare4             = 22
    case Phone              = 23
    case Utilities          = 24
    case CouncilTax         = 25
    case Spare5             = 26
    case ToYokko            = 27
    case OpeningBalance     = 28
    // Do not change this either
    case unknown            = 99
    
    
func rawValueAsString() -> String {
    return self.rawValue.description
}
    
    var description: String {
        switch self {
        case .Spare1:           return String( localized: "Spare1" )
        case .GardenHome:       return String( localized: "GardenHome" )
        case .Insurance:        return String( localized: "Insurance" )
        case .CarTax:           return String( localized: "CarTax" )
        case .CarMaintenance:   return String( localized: "CarMaintenance" )
        case .Spare2:           return String( localized: "Spare2" )
        case .Maintenance:      return String( localized: "Maintenance" )
        case .FoodHousehold:    return String( localized: "FoodHousehold" )
        case .AMWAY:            return String( localized: "AMWAY" )
        case .Wine:             return String( localized: "Wine" )
        case .Entertainments:   return String( localized: "Entertainments" )
        case .Travel:           return String( localized: "Travel" )
        case .TransportPetrol:  return String( localized: "TransportPetrol" )
        case .BooksCDs:         return String( localized: "BooksCDs" )
        case .Medical:          return String( localized: "Medical" )
        case .OfficeCompAV:     return String( localized: "OfficeCompAV" )
        case .Hobbies:          return String( localized: "Hobbies" )
        case .Presents:         return String( localized: "Presents" )
        case .Spare3:           return String( localized: "Spare3" )
        case .MiscOther:        return String( localized: "MiscOther" )
        case .ToBalance:        return String( localized: "ToBalance" )
        case .Spare4:           return String( localized: "Spare4" )
        case .Phone:            return String( localized: "Phone" )
        case .Utilities:        return String( localized: "Utilities" )
        case .CouncilTax:       return String( localized: "CouncilTax" )
        case .Spare5:           return String( localized: "Spare5" )
        case .ToYokko:          return String( localized: "ToYokko" )
        case .OpeningBalance:   return String( localized: "OpeningBalance" )
        case .unknown:          return String( localized: "Unknown" )
        }
    }

    
}
