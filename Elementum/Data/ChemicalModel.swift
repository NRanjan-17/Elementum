//
//  ChemicalModel.swift
//  Elementum
//
//  Created by Nalinish Ranjan on 31/01/26.
//

import Foundation
import SwiftData
import SwiftUI

enum ChemicalType: String, Codable {
    case element
    case ion
    case compound
}

@Model
class ChemicalEntity: Identifiable {
    var id: UUID
    var formula: String
    var name: String
    var type: ChemicalType
    var charge: Int
    var isPreset: Bool
    
    init(formula: String, name: String, type: ChemicalType, charge: Int = 0, isPreset: Bool = false) {
        self.id = UUID()
        self.formula = formula
        self.name = name
        self.type = type
        self.charge = charge
        self.isPreset = isPreset
    }
    
    var computedFormula: String {
        return formula.chemicalFormatting()
    }
}

extension String {
    func chemicalFormatting() -> String {
        var result = ""
        let numbers = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        let subscripts = ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"]
        let plus = "+"
        let minus = "-"
        let superscripts = ["⁺", "⁻"]
        
        // Simple parser: Numbers become subscripts, +/- become superscripts
        for char in self {
            let strChar = String(char)
            
            if let index = numbers.firstIndex(of: strChar) {
                result += subscripts[index]
            } else if strChar == plus {
                result += superscripts[0]
            } else if strChar == minus {
                result += superscripts[1]
            } else {
                result += strChar
            }
        }
        return result
    }
}

struct FormulaPart: Identifiable {
    var id = UUID()
    var symbol: String
    var count: Int
}

struct ReactionComponent: Identifiable {
    var id: UUID
    var symbol: String
    var name: String
    var color: Color
}

enum ActiveSheet: Identifiable {
    case elementPicker
    case compoundPicker
    case compoundCreator
    case quantityEditor(UUID)
    
    var id: String {
        switch self {
        case .elementPicker: return "elementPicker"
        case .compoundPicker: return "compoundPicker"
        case .compoundCreator: return "compoundCreator"
        case .quantityEditor(let uid): return "quantityEditor-\(uid)"
        }
    }
}

struct ReactantWrapper: Identifiable {
    let id = UUID()
    var item: ReactantItem
    var quantity: Int = 1
    
    var symbol: String {
        switch item {
        case .element(let e): return e.symbol
        case .compound(let c): return c.formula
        }
    }
    
    var formattedString: String {
        return quantity > 1 ? "\(quantity)\(symbol)" : symbol
    }
}

enum ReactantItem {
    case element(Element)
    case compound(ChemicalEntity)
}
