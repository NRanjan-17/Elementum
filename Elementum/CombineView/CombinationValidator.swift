import Foundation

struct CombinationValidator {
    private var combinations: [Combination] = []

    init() {
        loadCombinations()
    }

    private mutating func loadCombinations() {
        guard let url = Bundle.main.url(forResource: "Combinations", withExtension: "json") else {
            return
        }

        do {
            let data = try Data(contentsOf: url)
            combinations = try JSONDecoder().decode([Combination].self, from: data)
        } catch {
        }
    }

    func validate(elements: [Element]) -> String? {
        let selectedSymbols = elements.map { $0.symbol }.sorted()

        for combo in combinations {
            if combo.elements.sorted() == selectedSymbols {
                return combo.result
            }
        }
        return nil
    }
}
