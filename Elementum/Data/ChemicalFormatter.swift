import Foundation

/// Turns plain-text chemistry from the model ("2H2 + O2 -> 2H2O", "Fe^3+") into typeset text
/// using Unicode subscripts and superscripts ("2H₂ + O₂ → 2H₂O", "Fe³⁺").
enum ChemicalFormatter {
    
    private static let subscripts: [Character: Character] = [
        "0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄",
        "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉"
    ]
    
    private static let superscripts: [Character: Character] = [
        "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
        "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹",
        "+": "⁺", "-": "⁻", "−": "⁻"
    ]
    
    /// - Digits after an element symbol or ")" are subscripts (H2O, Ca(OH)2).
    /// - Digits at the start of a term are coefficients and stay full size (2H2O).
    /// - `^` starts a superscript charge: Fe^3+, SO4^2-, Na^+.
    static func format(_ text: String) -> String {
        var output = ""
        var previous: Character?
        var inSubscript = false
        var inCharge = false
        
        for character in text {
            if inCharge {
                if let raised = superscripts[character] {
                    output.append(raised)
                    previous = character
                    continue
                }
                inCharge = false
            }
            
            switch character {
            case "^":
                inCharge = true
                inSubscript = false
            case _ where character.isASCII && character.isNumber:
                let followsFormula = previous.map { $0.isLetter || $0 == ")" } ?? false
                if followsFormula || inSubscript {
                    output.append(subscripts[character] ?? character)
                    inSubscript = true
                } else {
                    output.append(character)
                }
                previous = character
            default:
                output.append(character)
                inSubscript = false
                previous = character
            }
        }
        
        return output
            .replacingOccurrences(of: "->", with: "→")
            .replacingOccurrences(of: "=>", with: "→")
    }
}
