import SwiftUI

struct SavedDinnersView: View {
    
    @StateObject private var store = DinnerStore()
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var searchText = ""
    
    var filteredDinners: [SavedDinner] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return store.dinners
        }
        
        return store.dinners.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var favoriteDinners: [SavedDinner] {
        filteredDinners.filter { $0.isFavorite }
    }
    
    var recentDinners: [SavedDinner] {
        filteredDinners.filter { !$0.isFavorite }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !favoriteDinners.isEmpty {
                    Section("⭐ Favorites") {
                        ForEach(favoriteDinners) { dinnerRow($0) }
                    }
                }
                
                Section("Recently Added") {
                    ForEach(recentDinners) { dinnerRow($0) }
                }
            }
            .navigationTitle("Mom’s Dinners")
            .searchable(text: $searchText, prompt: "Search chicken, pasta, steak...")
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
    
    private func dinnerRow(_ dinner: SavedDinner) -> some View {
        NavigationLink {
            DinnerDetailView(dinner: dinner, store: store)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(dinner.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if dinner.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                }
                
                Text("\(dinner.ingredients.count) ingredients • \(dinner.instructions.count) steps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                store.delete(dinner)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                shareText = groceryText(from: dinner)
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
    
    private func groceryText(from dinner: SavedDinner) -> String {
        let items = dinner.ingredients
            .map { "• \($0)" }
            .joined(separator: "\n")
        
        return """
        Grocery List for \(dinner.name)
        
        \(items.isEmpty ? "No ingredients found." : items)
        """
    }
}
