import Foundation

class CombinationValidator {
    private var Combinations: [String: String] = [:]

    init() {
        loadCombinations()
    }

    private func loadCombinations() {
        if let url = Bundle.main.url(forResource: "Combinations", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                Combinations = try JSONDecoder().decode([String: String].self, from: data)
            } catch {
                print("Failed to load Combinations.json: \(error)")
            }
        }
    }

    func validate(elements: [Element]) -> String {
        let sortedSymbols = elements.map { $0.symbol }.sorted()
        let key = sortedSymbols.joined(separator: "+")
        return Combinations[key] ?? "No valid combination found"
    }
}
