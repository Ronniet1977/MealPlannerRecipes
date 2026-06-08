import SwiftUI
import AVFoundation

struct DinnerDetailView: View {
    
    @State var dinner: SavedDinner
    @ObservedObject var store: DinnerStore
    
    @State private var selectedTab = 0
    @State private var cookStepIndex = 0
    
    @State private var selectedGroceryItems: Set<String> = []
    @State private var speaker = AVSpeechSynthesizer()
    @State private var dinnerComplete = false
    
    
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
            
            VStack(alignment: .leading, spacing: 24) {
                
                Text("Ingredients")
                    .font(.title2.bold())
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(dinner.ingredients, id: \.self) { item in
                        Label(item, systemImage: "circle.fill")
                            .font(.body)
                    }
                }
                
                Divider()
                
                Text("Instructions")
                    .font(.title2.bold())
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    ForEach(
                        Array(dinner.instructions.enumerated()),
                        id: \.offset
                    ) { index, step in
                        
                        HStack(alignment: .top) {
                            
                            Text("\(index + 1)")
                                .font(.headline)
                                .frame(width: 28)
                            
                            Text(step)
                        }
                    }
                }
            }
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
                
            } else if dinnerComplete {
                
                VStack(spacing: 20) {
                    Text("🎉")
                        .font(.system(size: 70))
                    
                    Text("Dinner Complete")
                        .font(.largeTitle.bold())
                    
                    Text("Enjoy your meal!")
                        .foregroundStyle(.secondary)
                    
                    Button("Cook Again") {
                        cookStepIndex = 0
                        dinnerComplete = false
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Back To Recipe") {
                        selectedTab = 0
                        cookStepIndex = 0
                        dinnerComplete = false
                    }
                    .buttonStyle(.bordered)
                }
                
            } else {
                
                Text("Step \(cookStepIndex + 1) of \(dinner.instructions.count)")
                    .font(.headline)
                
                ProgressView(
                    value: Double(cookStepIndex + 1),
                    total: Double(dinner.instructions.count)
                )
                .padding(.horizontal)
                
                Text(dinner.instructions[cookStepIndex])
                    .font(.system(size: 44, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding()
                    .minimumScaleFactor(0.5)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                
                                if value.translation.width < -50 {
                                    
                                    if cookStepIndex < dinner.instructions.count - 1 {
                                        cookStepIndex += 1
                                    } else {
                                        dinnerComplete = true
                                    }
                                }
                                
                                if value.translation.width > 50 {
                                    
                                    if cookStepIndex > 0 {
                                        cookStepIndex -= 1
                                    }
                                }
                            }
                    )
                
                HStack {
                    Button {
                        readCurrentStep()
                    } label: {
                        Label("Read Step", systemImage: "speaker.wave.2.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    
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
                        } else {
                            dinnerComplete = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
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
    
    private func readCurrentStep() {
        guard !dinner.instructions.isEmpty else { return }
        
        if speaker.isSpeaking {
            speaker.stopSpeaking(at: .immediate)
        }
        
        let text = dinner.instructions[cookStepIndex]
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        speaker.speak(utterance)
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
