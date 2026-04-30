import SwiftUI

struct RecipeFullScreenView: View {
    
    let recipe: String
    @Environment(\.dismiss) private var dismiss
    @State private var checkedItems: Set<String> = []
    
    private var ingredients: [String] {
        extractSection(named: "Ingredients")
            .filter { $0.hasPrefix("-") }
            .map { $0.replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespaces) }
    }
    
    var body: some View {
        NavigationStack {
            TabView {
                
                recipeTab
                    .tabItem {
                        Label("Recipe", systemImage: "doc.text")
                    }
                
                ingredientsTab
                    .tabItem {
                        Label("Ingredients", systemImage: "list.bullet")
                    }
                
                groceryTab
                    .tabItem {
                        Label("Grocery", systemImage: "cart")
                    }
            }
            .navigationTitle("Recipe")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var recipeTab: some View {
        ScrollView {
            Text(recipe)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
    
    private var ingredientsTab: some View {
        List {
            ForEach(ingredients, id: \.self) { item in
                Text(item)
            }
        }
    }
    
    
    
    private var groceryTab: some View {
        VStack {
            List {
                ForEach(ingredients, id: \.self) { item in
                    HStack {
                        Image(systemName: checkedItems.contains(item) ? "checkmark.circle.fill" : "circle")
                            .onTapGesture {
                                toggleItem(item)
                            }
                        
                        Text(item)
                            .strikethrough(checkedItems.contains(item))
                    }
                }
            }
            
            Divider()
            
            HStack {
                Button("Copy List") {
                    copyList()
                }
                
                Spacer()
                
                Button("Share") {
                    shareList()
                }
            }
            .padding()
        }
    }
    
    private func toggleItem(_ item: String) {
        if checkedItems.contains(item) {
            checkedItems.remove(item)
        } else {
            checkedItems.insert(item)
        }
    }
    
    private func copyList() {
        let list = ingredients.joined(separator: "\n")
        UIPasteboard.general.string = list
    }
    
    private func shareList() {
        let list = ingredients.joined(separator: "\n")
        
        let activityVC = UIActivityViewController(
            activityItems: [list],
            applicationActivities: nil
        )
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
    
    private func extractSection(named sectionName: String) -> [String] {
        let lines = recipe.components(separatedBy: .newlines)
        var found = false
        var sectionLines: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.lowercased().hasPrefix(sectionName.lowercased() + ":") {
                found = true
                continue
            }
            
            if found && trimmed.hasSuffix(":") {
                break
            }
            
            if found && !trimmed.isEmpty {
                sectionLines.append(trimmed)
            }
        }
        
        return sectionLines
    }
}
