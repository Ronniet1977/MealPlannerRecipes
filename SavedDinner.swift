import SwiftUI
import Foundation

struct SavedDinner: Identifiable, Codable {
    var id = UUID()
    var name: String
    var recipeText: String
    var isFavorite: Bool = false
    var checkedGroceryItems: [String] = []
    var createdAt: Date = Date()
    
    var ingredients: [String] {
        extractSection("Ingredients")
            .map { cleanBullet($0) }
            .filter { !$0.isEmpty }
            .filter { !isSectionHeader($0) }
    }
    
    var instructions: [String] {
        extractSection("Instructions")
            .map { cleanStep($0) }
            .filter { !$0.isEmpty }
            .filter { !isSectionHeader($0) }
    }
    
    private func extractSection(_ sectionName: String) -> [String] {
        let lines = recipeText.components(separatedBy: .newlines)
        var found = false
        var result: [String] = []
        
        for line in lines {
            let trimmed = cleanMarkdown(line)
            let lower = trimmed.lowercased()
            
            if lower == sectionName.lowercased() ||
                lower == "\(sectionName.lowercased()):" {
                found = true
                continue
            }
            
            if found && isMajorSectionHeader(trimmed) {
                break
            }
            
            if found && !trimmed.isEmpty {
                result.append(trimmed)
            }
        }
        
        return result
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
    
    private func cleanBullet(_ line: String) -> String {
        var cleaned = cleanMarkdown(line)
        
        while cleaned.hasPrefix("-") || cleaned.hasPrefix("*") || cleaned.hasPrefix("•") {
            cleaned.removeFirst()
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return cleaned
    }
    
    private func cleanStep(_ line: String) -> String {
        var cleaned = cleanMarkdown(line)
        
        while cleaned.first?.isNumber == true ||
                cleaned.hasPrefix(".") ||
                cleaned.hasPrefix("-") ||
                cleaned.hasPrefix("*") {
            cleaned.removeFirst()
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return cleaned
    }
    
    private func isSectionHeader(_ line: String) -> Bool {
        let cleaned = cleanMarkdown(line)
        return cleaned.hasSuffix(":") && cleaned.count < 50
    }
    
    private func isMajorSectionHeader(_ line: String) -> Bool {
        let lower = cleanMarkdown(line).lowercased()
        
        if lower == "instructions" || lower == "instructions:" { return true }
        if lower == "ingredients" || lower == "ingredients:" { return true }
        if lower == "cook time" || lower == "cook time:" { return true }
        if lower == "notes" || lower == "notes:" { return true }
        if lower == "recipe name" || lower == "recipe name:" { return true }
        
        return false
    }
}
