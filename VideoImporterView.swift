import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct VideoImporterView: View {
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedVideoURL: URL?
    @State private var extractedText = ""
    @State private var isScanning = false
    @State private var isBuildingRecipe = false
    @State private var recipeOutput = ""
    @State private var showFullScreen = false
    @State private var savedMessage = ""
    @State private var showPhotoPicker = false
    @State private var showFileImporter = false
    @State private var showEditRecipe = false
    @State private var manualText = ""
    @State private var showPasteSheet = false
    
    private let ocrService = VideoFrameOCRService()
    private let recipeCleaner = RecipeCleaner()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                Menu {
                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label("From Photos", systemImage: "photo")
                    }
                    
                    Button {
                        showFileImporter = true
                    } label: {
                        Label("From Files", systemImage: "folder")
                    }
                } label: {
                    Label("Select Video", systemImage: "video")
                }
                .buttonStyle(.borderedProminent)
                
                Button("Paste Recipe Text") {
                    showPasteSheet = true
                }
                .buttonStyle(.bordered)
                
                Button("New Dinner") {
                    resetDinner()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                
                if let url = selectedVideoURL {
                    Text("Selected:")
                        .font(.headline)
                    
                    Text(url.lastPathComponent)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                    
                    Button(isScanning ? "Scanning..." : "Scan Video Text") {
                        scanVideo(url: url)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isScanning)
                }
                
                if !extractedText.isEmpty {
                    Button(isBuildingRecipe ? "Building Recipe..." : "Make Recipe") {
                        makeRecipe()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isBuildingRecipe || isScanning)
                }
                
                if isScanning {
                    ProgressView("Scanning video...")
                }
                
                if isBuildingRecipe {
                    ProgressView("Building recipe...")
                }
                
                extractedTextView
                
                if !recipeOutput.isEmpty {
                    recipeResultView
                }
            }
            .padding()
        }
        .sheet(isPresented: $showEditRecipe) {
            EditRecipeView(recipeText: $recipeOutput)
        }
        .sheet(isPresented: $showPasteSheet) {
            pasteRecipeSheet
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                await loadVideo(from: newItem)
            }
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedItem,
            matching: .videos
        )
        .fullScreenCover(isPresented: $showFullScreen) {
            RecipeFullScreenView(recipe: recipeOutput)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }
    
    private func resetDinner() {
        selectedItem = nil
        selectedVideoURL = nil
        extractedText = ""
        recipeOutput = ""
        savedMessage = ""
        manualText = ""
        isScanning = false
        isBuildingRecipe = false
        showFullScreen = false
        showEditRecipe = false
        showPasteSheet = false
    }
    
    private var extractedTextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scanned / Pasted Text")
                .font(.headline)
            
            Text(extractedText.isEmpty ? "No text yet. Select a video, scan it, or paste recipe text." : extractedText)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    private var recipeResultView: some View {
        let parsed = parseRecipe(recipeOutput)
        
        return VStack(alignment: .leading, spacing: 14) {
            Divider()
            
            Text("Recipe")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
            
            VStack(alignment: .leading, spacing: 16) {
                
                Text(parsed.name.isEmpty ? "Untitled Dinner" : parsed.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if !parsed.ingredients.isEmpty {
                    Text("Ingredients")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    ForEach(parsed.ingredients, id: \.self) { item in
                        HStack(alignment: .top) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .padding(.top, 7)
                            Text(item)
                        }
                    }
                }
                
                if !parsed.steps.isEmpty {
                    Text("Instructions")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 6)
                    
                    ForEach(parsed.steps, id: \.self) { step in
                        Text(step)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                if parsed.ingredients.isEmpty && parsed.steps.isEmpty {
                    Text(recipeOutput)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .onTapGesture {
                showFullScreen = true
            }
            
            HStack {
                Button("Save Dinner") {
                    saveDinner()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Edit Recipe") {
                    showEditRecipe = true
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            if !savedMessage.isEmpty {
                Text(savedMessage)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    private var pasteRecipeSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $manualText)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                
                Button("Use This Text") {
                    extractedText = manualText
                    recipeOutput = ""
                    savedMessage = ""
                    showPasteSheet = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(manualText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .navigationTitle("Paste Recipe Text")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        showPasteSheet = false
                    }
                }
            }
        }
    }
    
    private func makeRecipe() {
        isBuildingRecipe = true
        recipeOutput = ""
        savedMessage = ""
        
        Task {
            let result = await recipeCleaner.cleanRecipe(from: extractedText)
            
            await MainActor.run {
                recipeOutput = result
                isBuildingRecipe = false
            }
        }
    }
    
    private func saveDinner() {
        let dinnerName = extractRecipeName(from: recipeOutput)
        let dinner = SavedDinner(
            name: dinnerName,
            recipeText: recipeOutput
        )
        
        let store = DinnerStore()
        store.save(dinner)
        
        savedMessage = "Saved: \(dinnerName)"
    }
    
    private func extractRecipeName(from text: String) -> String {
        let parsed = parseRecipe(text)
        
        if !parsed.name.isEmpty {
            return parsed.name
        }
        
        return "Dinner-\(Date().formatted(date: .numeric, time: .shortened))"
    }
    
    private func loadVideo(from item: PhotosPickerItem?) async {
        guard let item else { return }
        
        do {
            if let movie = try await item.loadTransferable(type: MovieTransfer.self) {
                await MainActor.run {
                    selectedVideoURL = movie.url
                    extractedText = ""
                    recipeOutput = ""
                    savedMessage = ""
                    isScanning = false
                    isBuildingRecipe = false
                }
            }
        } catch {
            await MainActor.run {
                extractedText = "Video load error: \(error.localizedDescription)"
            }
        }
    }
    
    private func scanVideo(url: URL) {
        isScanning = true
        extractedText = ""
        recipeOutput = ""
        savedMessage = ""
        
        Task {
            do {
                let text = try await ocrService.extractTextFromVideo(url: url)
                await MainActor.run {
                    extractedText = text.isEmpty ? "No readable text found." : text
                    isScanning = false
                }
            } catch {
                await MainActor.run {
                    extractedText = "Scan error: \(error.localizedDescription)"
                    isScanning = false
                }
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                let copyURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(url.pathExtension)
                
                if FileManager.default.fileExists(atPath: copyURL.path) {
                    try FileManager.default.removeItem(at: copyURL)
                }
                
                try FileManager.default.copyItem(at: url, to: copyURL)
                
                selectedVideoURL = copyURL
                extractedText = ""
                recipeOutput = ""
                savedMessage = ""
                isScanning = false
                isBuildingRecipe = false
            } catch {
                extractedText = "File import error: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            extractedText = "Import error: \(error.localizedDescription)"
        }
    }
    
    private func parseRecipe(_ text: String) -> ParsedRecipe {
        var result = ParsedRecipe()
        let lines = text.components(separatedBy: .newlines)
        var currentSection = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty { continue }
            
            let lower = trimmed.lowercased()
            
            if lower == "recipe name:" || lower.hasPrefix("recipe name:") {
                currentSection = "name"
                
                let inlineName = trimmed
                    .replacingOccurrences(of: "Recipe Name:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !inlineName.isEmpty {
                    result.name = inlineName
                }
                
                continue
            }
            
            if lower == "ingredients:" || lower.hasPrefix("ingredients:") {
                currentSection = "ingredients"
                continue
            }
            
            if lower == "instructions:" || lower.hasPrefix("instructions:") {
                currentSection = "steps"
                continue
            }
            
            if lower == "cook time:" || lower == "notes:" {
                currentSection = ""
                continue
            }
            
            switch currentSection {
            case "name":
                if result.name.isEmpty {
                    result.name = trimmed
                }
            case "ingredients":
                let cleaned = trimmed
                    .replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: "•", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !cleaned.isEmpty {
                    result.ingredients.append(cleaned)
                }
            case "steps":
                result.steps.append(trimmed)
            default:
                break
            }
        }
        
        return result
    }
}

struct ParsedRecipe {
    var name: String = ""
    var ingredients: [String] = []
    var steps: [String] = []
}

struct MovieTransfer: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(received.file.pathExtension)
            
            try FileManager.default.copyItem(at: received.file, to: copy)
            return MovieTransfer(url: copy)
        }
    }
}
