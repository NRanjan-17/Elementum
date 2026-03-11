//
//  ReactionModel.swift
//  Elementum
//
//  Created by Nalinish Ranjan on 01/02/26.
//

import Foundation

actor ReactionModel {
    
    
    private let baseURL = ""
    
    // "API Key" found on that same page (or under "Keys and Endpoint")
    private let apiKey = ""
    
    // IMPORTANT: This is the name you chose when you clicked "Deploy model" > "Deploy new".
    // It is often "gpt-4o", "gpt-4o-deployment", or similar. Check "Model catalog" > "Deployments".
    private let deploymentName = ""
    
    func predict(elements: [String]) async -> String {
        let reactants = elements.joined(separator: " + ")
        
        // 4. Construct the Standard Azure OpenAI URL
        // Format: {baseURL}/openai/deployments/{deployment-name}/chat/completions?api-version={version}
        let urlString = "\(baseURL)/openai/deployments/\(deploymentName)/chat/completions?api-version=2024-12-01-preview"
        
        guard let url = URL(string: urlString) else { return "Invalid URL configuration" }
        
        let systemPrompt = """
            You are a chemistry expert. Analyze the reaction between: \(reactants), the given reactants may or may not be balanced.
            
            Provide your response in exactly this format:
            EQUATION: [The balanced chemical equation including all primary and by-products and if the reaction is not possible don't give any equation just give the description]
            DESCRIPTION: [A one-sentence explanation of what happens and the type of reaction]
            
            Do not include markdown or extra text and don't halucinate and if the reactants don't match in any equation just return "Correct the reactants" but if there is an issue of quantity then you can give the equation.
            """
        
        let userPrompt = "Analyze the reaction between: \(reactants)"
        
        // Prepare Payload
        let payload = HFRequest(
            model: "",
            messages: [
                HFMessage(role: "system", content: systemPrompt),
                HFMessage(role: "user", content: userPrompt)
            ],
            max_tokens: 150,
            temperature: 0.1
        )
        
        // Configure Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Azure Headers
        request.addValue(apiKey, forHTTPHeaderField: "api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
            
            // Send Request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Handle Errors
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                // Try parsing detailed error
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorDict = errorJson["error"] as? [String: Any],
                   let message = errorDict["message"] as? String {
                    
                    if httpResponse.statusCode == 404 {
                        return "Azure Error: Deployment '\(deploymentName)' not found. Check the name in Azure Portal."
                    }
                    return "Azure Error: \(message)"
                }
                return "Server Error: \(httpResponse.statusCode)"
            }
            
            // Decode Response
            let decodedResponse = try JSONDecoder().decode(HFResponse.self, from: data)
            
            guard let text = decodedResponse.choices.first?.message.content else {
                return "No result found."
            }
            
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "`", with: "")
            
        } catch {
            print("Network Error: \(error.localizedDescription)")
            return "Connection error. Please check internet."
        }
    }
}

