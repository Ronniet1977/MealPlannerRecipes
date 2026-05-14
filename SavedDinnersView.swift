import SwiftUI

struct SavedDinnersView: View {
    
    @StateObject private var store = DinnerStore()
    @State private var showShareSheet = false
    @State private var shareText = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.dinners) { dinner in
                    NavigationLink {
                        DinnerDetailView(dinner: dinner, store: store)
                    } label: {
                        HStack {
                            Text(dinner.name)
                            Spacer()
                            if dinner.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            shareText = groceryText(from: dinner.recipeText)
                            showShareSheet = true
                        } label: {
                            Label("Grocery", systemImage: "cart")
                        }
                        .tint(.green)
                        
                        Button {
                            shareText = dinner.recipeText
                            showShareSheet = true
                        } label: {
                            Label("Recipe", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        store.delete(store.dinners[index])
                    }
                }
            }
            .navigationTitle("Saved Dinners")
            .toolbar {
                EditButton()
            }
            .onAppear {
                store.loadDinners()
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [shareText])
            }
        }
    }
    private func groceryText(from recipe: String) -> String {
        let lines = recipe.components(separatedBy: .newlines)
        var found = false
        var items: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.lowercased().hasPrefix("ingredients:") {
                found = true
                continue
            }
            
            if found && trimmed.hasSuffix(":") {
                break
            }
            
            if found && trimmed.hasPrefix("-") {
                let item = trimmed
                    .replacingOccurrences(of: "-", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                items.append("• \(item)")
            }
        }
        
        return """
    Grocery List
    
    \(items.joined(separator: "\n"))
    """
    }
}
