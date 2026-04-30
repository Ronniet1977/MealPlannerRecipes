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
            .filter { $0.hasPrefix("-") }
            .map {
                $0.replacingOccurrences(of: "-", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
    }
    
    var instructions: [String] {
        extractSection("Instructions")
            .map {
                $0.replacingOccurrences(
                    of: #"^\d+\.\s*"#,
                    with: "",
                    options: .regularExpression
                )
                .trimmingCharacters(in: .whitespaces)
            }
    }
    
    private func extractSection(_ name: String) -> [String] {
        let lines = recipeText.components(separatedBy: .newlines)
        var found = false
        var result: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.lowercased().hasPrefix(name.lowercased() + ":") {
                found = true
                continue
            }
            
            if found && trimmed.hasSuffix(":") {
                break
            }
            
            if found && !trimmed.isEmpty {
                result.append(trimmed)
            }
        }
        
        return result
    }
}
