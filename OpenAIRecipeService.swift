import SwiftUI
import Foundation

final class OpenAIRecipeService {
    
    private let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    
    func makeRecipe(ocrText: String, transcript: String) async throws -> String {
        
        let prompt = """
You are a recipe assistant helping clean up messy TikTok/Reel recipe text.

Create the best possible recipe from the OCR and speech below.

Rules:
- Ignore TikTok usernames, watermarks, captions, ads, music lyrics, and unrelated text.
- Use only cooking-related details.
- If a measurement is missing, estimate a reasonable amount and mark it "(estimated)".
- If a step is unclear, infer the most likely cooking step and mark it "(estimated)".
- Include oven temperature/cook time if found.
- Keep it simple enough for a home cook.

Return a COMPLETE recipe. Do not shorten it. Do not use "...".

Return EXACTLY this format:

Recipe Name:
[short recipe name]

Ingredients:
- [amount] [ingredient]
- [amount] [ingredient]

Instructions:
1. [clear step]
2. [clear step]
3. [clear step]

Cook Time:
[estimated or found time]

Notes:
- [what was estimated or unclear]

OCR TEXT:
\(ocrText)

SPEECH TRANSCRIPT:
\(transcript)
"""
        
        let url = URL(string: "https://api.openai.com/v1/responses")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4.1-mini",
            "input": prompt,
            "max_output_tokens": 1200
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown API error"
            return "OpenAI error \(http.statusCode): \(errorText)"
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            if let outputText = json["output_text"] as? String {
                return outputText
            }
            
            if let output = json["output"] as? [[String: Any]] {
                var allText: [String] = []

                for item in output {
                    if let content = item["content"] as? [[String: Any]] {
                        for part in content {
                            if let text = part["text"] as? String {
                                allText.append(text)
                            }
                        }
                    }
                }

                if !allText.isEmpty {
                    return allText.joined(separator: "\n")
                }
            }
            
            return "Could not find recipe text in response:\n\(json)"
        }
        
        return "Failed to read OpenAI response."
    }
}

struct OpenAIResponse: Decodable {
    let output: [OpenAIOutput]
}

struct OpenAIOutput: Decodable {
    let content: [OpenAIContent]
}

struct OpenAIContent: Decodable {
    let text: String?
}
