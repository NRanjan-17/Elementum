//
//  ReactionModel.swift
//  Elementum
//
//  Created by Nalinish Ranjan on 01/02/26.
//

import Foundation
import Sapient

/// Predicts reactions fully on-device with Qwen 2.5 1.5B through Sapient.
actor ReactionModel {
    
    private var session: LlmSession?
    
    // Users experiment with arbitrary element/compound combinations, so the prompt covers
    // impossible mixes and unusual quantities, and shows the exact output shape with examples
    // (small models follow examples far better than rules).
    private let systemPrompt = """
        You are a careful chemistry tutor inside an app where students experiment by combining elements and compounds. \
        You are given a list of reactants joined by " + ". Quantities such as "2 H2" are optional and may be unbalanced.

        Reply with exactly two lines and nothing else:
        EQUATION: <balanced chemical equation with every product and by-product, using → between sides>
        DESCRIPTION: <one sentence naming the reaction type and what is observed>

        Rules:
        - Only describe reactions that really happen under common conditions. Never invent products.
        - If the substances do not react, write "EQUATION: No reaction" and explain why in DESCRIPTION.
        - If an entry is not a real element, compound or formula, reply only: Correct the reactants
        - If only the quantities are off, balance the equation using the correct ratio and say so.
        - Elements that exist as molecules are written in molecular form: H2, N2, O2, F2, Cl2, Br2, I2. \
        Other elements are written as single atoms (Na, Fe, C).
        - Balance with the smallest whole-number coefficients and make sure every element has the same atom count on both sides.
        - Write formulas in plain ASCII (H2O, not subscripts). Write ionic charges with ^ (Fe^3+, SO4^2-).
        - Plain text only: no markdown, no extra commentary.

        Examples:
        Reactants: H + O
        EQUATION: 2H2 + O2 → 2H2O
        DESCRIPTION: A combination (synthesis) reaction in which hydrogen burns in oxygen to form water.

        Reactants: Na + Cl2
        EQUATION: 2Na + Cl2 → 2NaCl
        DESCRIPTION: A synthesis reaction in which sodium and chlorine form sodium chloride, releasing heat and bright light.

        Reactants: Au + H2O
        EQUATION: No reaction
        DESCRIPTION: Gold is unreactive and does not react with water.
        """
    
    /// Loads the model on first use (downloads the weights on first run) and reuses it afterwards.
    private func loadSession() async throws -> LlmSession {
        if let session { return session }
        
        let options = GenerationOptions(
            maxTokens: 150,
            temperature: nil,   // greedy decoding, deterministic answers
            systemPrompt: systemPrompt,
            contextLength: 2048   // prompts here are short; a small KV cache saves memory
        )
        let model = ModelManager.modelAlias
        // `load` blocks (and downloads on first run), so keep it off the actor's executor.
        let loaded = try await Task.detached(priority: .userInitiated) {
            try LlmSession.load(model: model, options: options)
        }.value
        session = loaded
        return loaded
    }
    
    /// Loads the model ahead of time so the first prediction doesn't wait for it.
    func warmUp() async {
        _ = try? await loadSession()
    }
    
    func predict(elements: [String]) async -> String {
        let reactants = elements.joined(separator: " + ")
        
        do {
            let session = try await loadSession()
            // Each prediction is independent, so clear the previous conversation.
            session.reset()
            let reply = try await session.chatAsync(userMessage: "Reactants: \(reactants)")
            return reply.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "`", with: "")
        } catch {
            let available = listModels().filter { $0.category == "chat" }.map(\.alias).joined(separator: ", ")
            print("Sapient error: \(error). Available chat models: \(available)")
            return "Couldn't run the on-device model. \(error.localizedDescription)"
        }
    }
}
