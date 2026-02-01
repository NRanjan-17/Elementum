//
//  ReactionModel.swift
//  Elementum
//
//  Created by Nalinish Ranjan on 01/02/26.
//

import Foundation
import GoogleGenerativeAI

actor ReactionModel {
    private let model: GenerativeModel
    
    init() {
        // Initialize with the current recommended configuration pattern
        self.model = GenerativeModel(
            name: "gemini-2.5-flash-lite",
            apiKey: "Gemini API Key",
            generationConfig: GenerationConfig(
                temperature: 0.1, // Low temperature for consistent chemical formulas
                topP: 0.95,
                topK: 40,
                maxOutputTokens: 100
            )
        )
    }
    
    func predict(elements: [String]) async -> String {
        let reactants = elements.joined(separator: " + ")
        
        // Updated structured prompt for more detailed output
        let prompt = """
            You are a chemistry expert. Analyze the reaction between: \(reactants).
            
            Provide your response in exactly this format:
            EQUATION: [The balanced chemical equation including all primary and by-products and if the reaction is not possible don't give any equation just give the description]
            DESCRIPTION: [A one-sentence explanation of what happens and the type of reaction]
            
            Do not include markdown or extra text and don't halucinate and if the reactants don't match in any equation just return "Correct the reactants".
            """
        
        do {
            let response = try await model.generateContent(prompt)
            
            guard let text = response.text else {
                return "No result found for this combination."
            }
            
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "`", with: "")
        } catch {
            print("❌ Gemini API Error: \(error.localizedDescription)")
            return "Unable to simulate reaction. Please check your connection."
        }
    }
}
