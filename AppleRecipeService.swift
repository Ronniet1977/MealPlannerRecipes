import SwiftUI
import Foundation
import FoundationModels

final class AppleRecipeService {
    
    func makeRecipe(from rawText: String) async throws -> String {
        let instructions = """
        You clean messy TikTok, Reel, and video recipe text into simple home recipes.
        Ignore intros, jokes, usernames, captions, music lyrics, ads, and unrelated text.
        Return only the recipe.
        """
        
        let session = LanguageModelSession(instructions: instructions)
        
        let prompt = """
You are a professional recipe extractor.

Your job is to turn messy TikTok/Reel cooking transcripts into a clean recipe.

VERY IMPORTANT RULES:
- Ignore intros, stories, jokes, usernames, captions, hashtags, and ads.
- Ignore phrases like "you guys", "trust me", "this is fire", etc.
- DO NOT copy giant paragraphs into ingredients.
- Ingredients must ONLY contain actual ingredients.
- Instructions must ONLY contain cooking steps.
- If a quantity is unclear, estimate reasonably.
- If the recipe name is unclear, create a short natural recipe name.

Return ONLY this format:

Recipe Name:
[name]

Ingredients:
- ingredient
- ingredient
- ingredient

Instructions:
1. step
2. step
3. step

Cook Time:
[value]

Notes:
- estimated items if needed

Messy Recipe Text:
\(rawText)
"""
        
        let response = try await session.respond(to: prompt)
        print(response.content)
        return response.content
    }
}
