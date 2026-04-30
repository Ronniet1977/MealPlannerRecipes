//
//  RecipeCleaner.swift
//  MealPlannerRecipes
//
//  Created by Ronald Thayer Jr on 4/30/26.
//

import Foundation

final class RecipeCleaner {
    
    func cleanRecipe(from text: String) async -> String {
        basicCleanup(text)
    }
    
    private func basicCleanup(_ text: String) -> String {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var recipeName = detectRecipeName(text)
        var ingredients: [String] = []
        var instructions: [String] = []
        var section = ""
        
        let junkWords = [
            "app store", "google play", "link in my bio",
            "save unlimited recipes", "follow", "subscribe",
            "tiktok", "instagram", "@", "comment", "like", "share"
        ]
        
        for line in lines {
            let lower = line.lowercased()
            
            if junkWords.contains(where: { lower.contains($0) }) {
                continue
            }
            
            if lower.hasPrefix("recipe name") {
                let name = line
                    .replacingOccurrences(of: "Recipe Name:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !name.isEmpty {
                    recipeName = name
                }
                continue
            }
            
            if lower.hasPrefix("ingredients") {
                section = "ingredients"
                continue
            }
            
            if lower.hasPrefix("instructions") || lower.hasPrefix("directions") {
                section = "instructions"
                continue
            }
            
            if lower.hasPrefix("cook time") || lower.hasPrefix("notes") {
                section = ""
                continue
            }
            
            if section == "ingredients" {
                ingredients.append(cleanIngredient(line))
            } else if section == "instructions" {
                instructions.append(cleanInstruction(line))
            }
        }
        
        ingredients = Array(NSOrderedSet(array: ingredients)) as? [String] ?? ingredients
        instructions = Array(NSOrderedSet(array: instructions)) as? [String] ?? instructions
        
        let ingredientText = ingredients.isEmpty
        ? "- Add ingredients manually"
        : ingredients.map { "- \($0)" }.joined(separator: "\n")
        
        let instructionText = instructions.isEmpty
        ? "1. Add instructions manually."
        : instructions.enumerated().map { index, step in
            "\(index + 1). \(step)"
        }.joined(separator: "\n")
        
        return """
        Recipe Name:
        \(recipeName)
        
        Ingredients:
        \(ingredientText)
        
        Instructions:
        \(instructionText)
        
        Cook Time:
        Estimated / add manually
        
        Notes:
        - Cleaned from pasted recipe text or video OCR.
        - Edit before saving if anything looks off.
        """
    }
    
    private func detectRecipeName(_ text: String) -> String {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let keywords = [
            "pasta", "alfredo", "chicken", "steak", "shrimp",
            "tacos", "soup", "salad", "burger", "rice",
            "noodles", "pizza", "casserole", "salmon"
        ]
        
        for line in lines.prefix(12) {
            let lower = line.lowercased()
            
            if keywords.contains(where: { lower.contains($0) }) &&
                !lower.contains("ingredients") &&
                !lower.contains("instructions") {
                return line.capitalized
            }
        }
        
        return "Quick Dinner"
    }
    
    private func cleanIngredient(_ line: String) -> String {
        line
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "•", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func cleanInstruction(_ line: String) -> String {
        var cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        cleaned = cleaned.replacingOccurrences(
            of: #"^\d+\.\s*"#,
            with: "",
            options: .regularExpression
        )
        
        return cleaned
    }
}
