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
    var description: String
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
