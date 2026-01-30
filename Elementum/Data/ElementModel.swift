import SwiftUI

class ElementModel {
    func load<T: Decodable>(_ filename: String) -> T {
        let url = Bundle.main.url(forResource: filename, withExtension: nil)!
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            fatalError("Couldn't load \(filename): \(error)")
        }
    }
}

struct Element: Identifiable, Codable, Hashable {
    var id: Int
    var element: String
    var symbol: String
    var mass: Double
    var row: Int
    var column: Int
    var block: String
    var bonds: String
    var noble: String
    var phase: String?
    var discoveredBy: String?
    var appearance: String?
    var electronicConfiguration: String?
    var description: String
    var source: String?
}

struct ElementColor {
    static func color(for block: String) -> Color {
        switch block.lowercased() {
        case "s block": return Color.blue
        case "p block": return Color.green
        case "d block": return Color.orange
        case "f block": return Color.purple
        default: return Color.gray
        }
    }
}

struct Combination: Codable {
    let elements: [String]
    let result: String
}

enum SelectedView: String, CaseIterable, Hashable {
    case periodicTable
    case sGroup
    case pGroup
    case dGroup
    case fGroup
    
    var title: String {
        switch self {
        case .periodicTable: return "Periodic Table"
        case .sGroup: return "S Group Elements"
        case .pGroup: return "P Group Elements"
        case .dGroup: return "D Group Elements"
        case .fGroup: return "F Group Elements"
        }
    }
    
    var imageName: String {
        switch self {
        case .periodicTable: return "Table"
        case .sGroup: return "S_Block"
        case .pGroup: return "P_Block"
        case .dGroup: return "D_Block"
        case .fGroup: return "F_Block"
        }
    }
    
    @ViewBuilder
    var destination: some View {
        switch self {
        case .periodicTable:
            Elements()
        case .sGroup:
            S_Group()
        case .pGroup:
            P_Group()
        case .dGroup:
            D_Group()
        case .fGroup:
            F_Group()
        }
    }
}


