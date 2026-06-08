import Foundation

final class RecipeCleaner {
    
    func cleanRecipe(from text: String) async -> String {
        basicCleanup(text)
    }
    
    private func basicCleanup(_ text: String) -> String {
        let lines = normalizedLines(from: text)
        
        var recipeName = detectRecipeName(text)
        var ingredients: [String] = []
        var instructions: [String] = []
        var section = ""
        
        for rawLine in lines {
            let line = cleanMarkdown(rawLine)
            let lower = line.lowercased()
            
            if line.isEmpty { continue }
            
            if isJunkLine(lower) {
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
            
            if lower == "ingredients" || lower.hasPrefix("ingredients") {
                section = "ingredients"
                continue
            }
            
            if lower == "instructions" || lower == "directions" || lower.hasPrefix("instructions") || lower.hasPrefix("directions") {
                section = "instructions"
                continue
            }
            
            if lower.hasPrefix("cook time") || lower.hasPrefix("notes") {
                section = ""
                continue
            }
            
            if section == "ingredients" {
                if looksLikeInstruction(lower) {
                    section = "instructions"
                    instructions.append(cleanInstruction(line))
                } else if !isIngredientGroupHeader(line) {
                    ingredients.append(cleanIngredient(line))
                }
            } else if section == "instructions" {
                instructions.append(cleanInstruction(line))
            } else if looksLikeIngredient(lower) {
                ingredients.append(cleanIngredient(line))
            } else if looksLikeInstruction(lower) {
                instructions.append(cleanInstruction(line))
            }
        }
        
        ingredients = uniqueClean(ingredients)
        instructions = uniqueClean(instructions)
        
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
        let lines = normalizedLines(from: text)
        
        for rawLine in lines.prefix(15) {
            let line = cleanMarkdown(rawLine)
            let lower = line.lowercased()
            
            if line.isEmpty { continue }
            
            if lower == "ingredients" ||
                lower == "instructions" ||
                lower == "directions" ||
                lower.hasPrefix("recipe name") ||
                lower.hasPrefix("cook time") ||
                lower.hasPrefix("notes") {
                continue
            }
            
            if isIngredientGroupHeader(line) {
                continue
            }
            
            return line.capitalized
        }
        
        return "Quick Dinner"
    }
    
    private func normalizedLines(from text: String) -> [String] {
        text
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func cleanMarkdown(_ line: String) -> String {
        var cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        while cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: "**", with: "")
        cleaned = cleaned.replacingOccurrences(of: "__", with: "")
        cleaned = cleaned.replacingOccurrences(of: "`", with: "")
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func isIngredientGroupHeader(_ line: String) -> Bool {
        let cleaned = cleanMarkdown(line)
        return cleaned.hasSuffix(":") && cleaned.count < 40
    }
    
    private func looksLikeIngredient(_ lower: String) -> Bool {
        if lower.contains("cup") { return true }
        if lower.contains("tbsp") { return true }
        if lower.contains("tsp") { return true }
        if lower.contains("oz") { return true }
        if lower.contains("lb") { return true }
        if lower.contains("gram") { return true }
        if lower.contains("ml") { return true }
        
        if lower.contains("salt") { return true }
        if lower.contains("pepper") { return true }
        if lower.contains("oil") { return true }
        if lower.contains("butter") { return true }
        if lower.contains("garlic") { return true }
        if lower.contains("chicken") { return true }
        if lower.contains("cheese") { return true }
        if lower.contains("cream") { return true }
        if lower.contains("pasta") { return true }
        if lower.contains("tomato") { return true }
        if lower.contains("sauce") { return true }
        
        return false
    }
    
    private func looksLikeInstruction(_ lower: String) -> Bool {
        if lower.first?.isNumber == true { return true }
        
        if lower.contains("cook") { return true }
        if lower.contains("bake") { return true }
        if lower.contains("stir") { return true }
        if lower.contains("mix") { return true }
        if lower.contains("heat") { return true }
        if lower.contains("combine") { return true }
        if lower.contains("preheat") { return true }
        if lower.contains("add") { return true }
        if lower.contains("pour") { return true }
        if lower.contains("melt") { return true }
        if lower.contains("serve") { return true }
        
        return false
    }
    
    private func cleanIngredient(_ line: String) -> String {
        var cleaned = cleanMarkdown(line)
        
        while cleaned.hasPrefix("-") || cleaned.hasPrefix("•") {
            cleaned.removeFirst()
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return cleaned
    }
    
    private func cleanInstruction(_ line: String) -> String {
        var cleaned = cleanMarkdown(line)
        
        while cleaned.first?.isNumber == true ||
                cleaned.hasPrefix(".") ||
                cleaned.hasPrefix("-") {
            cleaned.removeFirst()
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return cleaned
    }
    
    private func isJunkLine(_ lower: String) -> Bool {
        if lower.contains("app store") { return true }
        if lower.contains("google play") { return true }
        if lower.contains("link in my bio") { return true }
        if lower.contains("save unlimited recipes") { return true }
        if lower.contains("follow") { return true }
        if lower.contains("subscribe") { return true }
        if lower.contains("tiktok") { return true }
        if lower.contains("instagram") { return true }
        if lower.contains("@") { return true }
        if lower.contains("comment") { return true }
        if lower.contains("like") { return true }
        if lower.contains("share") { return true }
        
        return false
    }
    
    private func uniqueClean(_ items: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        
        for item in items {
            let cleaned = item.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = cleaned.lowercased()
            
            if cleaned.isEmpty { continue }
            if seen.contains(key) { continue }
            
            seen.insert(key)
            result.append(cleaned)
        }
        
        return result
    }
}
