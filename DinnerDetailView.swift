import SwiftUI

struct DinnerDetailView: View {
    
    @State var dinner: SavedDinner
    @ObservedObject var store: DinnerStore
    
    @State private var selectedTab = 0
    @State private var cookStepIndex = 0
    
    @State private var selectedGroceryItems: Set<String> = []
    
    
    var body: some View {
        VStack {
            Picker("View", selection: $selectedTab) {
                Text("Recipe").tag(0)
                Text("Grocery").tag(1)
                Text("Cook").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if selectedTab == 0 {
                recipeView
            } else if selectedTab == 1 {
                groceryView
            } else {
                cookModeView
            }
        }
        .navigationTitle(dinner.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dinner.isFavorite.toggle()
                    store.update(dinner)
                } label: {
                    Image(systemName: dinner.isFavorite ? "star.fill" : "star")
                }
            }
        }
    }
    
    private var recipeView: some View {
        ScrollView {
            Text(dinner.recipeText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
    
    private var groceryView: some View {
        VStack {
            List {
                ForEach(dinner.ingredients, id: \.self) { item in
                    Button {
                        toggleSelectedGrocery(item)
                    } label: {
                        HStack {
                            Image(systemName: selectedGroceryItems.contains(item) ? "checkmark.circle.fill" : "circle")
                            
                            Text(item)
                                .strikethrough(selectedGroceryItems.contains(item))
                        }
                    }
                }
            }
            
            Divider()
            
            HStack {
                Button {
                    UIPasteboard.general.string = selectedGroceryListText()
                } label: {
                    Label("Copy Selected", systemImage: "doc.on.doc")
                }
                
                Spacer()
                
                ShareLink(
                    item: selectedGroceryListText()
                ) {
                    Label("Share Selected", systemImage: "square.and.arrow.up")
                }
            }
            .padding()
        }
        .onDisappear {
            selectedGroceryItems.removeAll()
        }
    }
    
    private func toggleSelectedGrocery(_ item: String) {
        if selectedGroceryItems.contains(item) {
            selectedGroceryItems.remove(item)
        } else {
            selectedGroceryItems.insert(item)
        }
    }
    
    private func selectedGroceryListText() -> String {
        let items = selectedGroceryItems
            .sorted()
            .map { "• \($0)" }
            .joined(separator: "\n")
        
        return """
    Grocery List for \(dinner.name)
    
    \(items.isEmpty ? "No items selected." : items)
    """
    }
    
    private var cookModeView: some View {
        VStack(spacing: 25) {
            if dinner.instructions.isEmpty {
                Text("No instructions found.")
                    .foregroundStyle(.secondary)
            } else {
                Text("Step \(cookStepIndex + 1) of \(dinner.instructions.count)")
                    .font(.headline)
                
                Text(dinner.instructions[cookStepIndex])
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding()
                    .minimumScaleFactor(0.6)
                
                HStack {
                    Button("Back") {
                        if cookStepIndex > 0 {
                            cookStepIndex -= 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(cookStepIndex == 0)

                    Button("Next") {
                        if cookStepIndex < dinner.instructions.count - 1 {
                            cookStepIndex += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(cookStepIndex >= dinner.instructions.count - 1)
                }
                .padding()
            }
        }
        .padding()
    }
    
    private func toggleGrocery(_ item: String) {
        if dinner.checkedGroceryItems.contains(item) {
            dinner.checkedGroceryItems.removeAll { $0 == item }
        } else {
            dinner.checkedGroceryItems.append(item)
        }
        
        store.update(dinner)
    }
    
    private func groceryListText() -> String {
        let selectedItems = dinner.checkedGroceryItems
        
        let items = selectedItems
            .map { "• \($0)" }
            .joined(separator: "\n")
        
        return """
    Grocery List for \(dinner.name)
    
    \(items.isEmpty ? "No items selected." : items)
    """
    }
}
