import Foundation
import FoundationModels

@available(iOS 26.0, *)
final class AppleRecipeService {
    
    func makeRecipe(from rawText: String) async throws -> String {
        
        let model = SystemLanguageModel.default
        
        switch model.availability {
        case .available:
            break
        default:
            throw NSError(
                domain: "AppleRecipeService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Apple Intelligence is not available on this device yet."]
            )
        }
        
        let instructions = """
        You clean messy recipe video text into clear home recipes.
        Ignore intros, captions, jokes, hashtags, ads, and unrelated text.
        Return only the recipe.
        """
        
        let session = LanguageModelSession(
            model: model,
            instructions: instructions
        )
        
        let prompt = """
        Turn this messy recipe text into a clean recipe.
        
        Recipe Name:
        Ingredients:
        Instructions:
        Cook Time:
        Notes:
        
        Messy Recipe Text:
        \(rawText)
        """
        
        let response = try await session.respond(to: prompt)
        return response.content
    }
}
