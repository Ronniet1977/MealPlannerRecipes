import SwiftUI
import Photos
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
    @State private var showReelHelp = false
    @State private var showDeleteRecordingConfirmation = false
    @State private var selectedPhotoAssetIdentifier: String?
    @State private var importMessage = ""
    
    @State private var showVideoSourceDialog = false

    private let recipeCleaner = RecipeCleaner()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .videos,
                    photoLibrary: .shared()
                ) {
                    Label("Select Video", systemImage: "video")
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    showReelHelp = true
                } label: {
                    Label("Using a Reel?", systemImage: "record.circle")
                }
                .buttonStyle(.bordered)
                
                Button("Paste Recipe Text") {
                    showPasteSheet = true
                }
                .buttonStyle(.bordered)
                
                Button("New Dinner") {
                    resetDinner()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                
                if !importMessage.isEmpty {
                    Text(importMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                if let url = selectedVideoURL {
                    Text("✅ Video is selected")
                        .foregroundColor(.green)
                    
                    Text(url.lastPathComponent)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                    
                    Button(isScanning ? "Scanning..." : "Scan Video") {
                        scanVideo(url: url)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isScanning)
                } else {
                    Text("❌ selectedVideoURL is nil")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                if !extractedText.isEmpty {
                    Button(isBuildingRecipe ? "Building Recipe..." : "Make Recipe") {
                        makeRecipe()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isBuildingRecipe || isScanning)
                }
                
                if isScanning {
                    ProgressView("Scanning video text and speech...")
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
        .sheet(isPresented: $showReelHelp) {
            reelHelpSheet
        }
        .confirmationDialog(
            "Delete the screen recording from Photos?",
            isPresented: $showDeleteRecordingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Recording", role: .destructive) {
                deleteImportedRecording()
            }

            Button("Keep Recording", role: .cancel) {
                importMessage = "Recording kept in Photos."
            }
        } message: {
            Text("The app already copied the video for scanning. Delete the original recording from Photos if you only made it for this recipe.")
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                await loadVideo(from: newItem)
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            RecipeFullScreenView(recipe: recipeOutput)
        }
    }

    private func resetDinner() {
        selectedItem = nil
        selectedVideoURL = nil
        extractedText = ""
        recipeOutput = ""
        savedMessage = ""
        manualText = ""
        importMessage = ""
        selectedPhotoAssetIdentifier = nil
        isScanning = false
        isBuildingRecipe = false
        showFullScreen = false
        showEditRecipe = false
        showPasteSheet = false
        showReelHelp = false
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

    private var reelHelpSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Facebook and most social apps do not share the actual Reel video file from a link. Screen record it, then import the recording from Photos.")
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    reelHelpStep("1", "Open the Reel and turn the volume on.")
                    reelHelpStep("2", "Start Screen Recording from Control Center.")
                    reelHelpStep("3", "Play the full Reel, including the cooking steps.")
                    reelHelpStep("4", "Stop recording and wait for it to save to Photos.")
                    reelHelpStep("5", "Return here and choose Select Video, then From Photos.")
                }

                Button {
                    showReelHelp = false
                    showPhotoPicker = true
                } label: {
                    Label("Choose Recording", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer()
            }
            .padding()
            .navigationTitle("Use a Reel")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showReelHelp = false
                    }
                }
            }
        }
    }

    private func reelHelpStep(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .frame(width: 28, height: 28)
                .background(.thinMaterial)
                .clipShape(Circle())

            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func makeRecipe() {
        isBuildingRecipe = true
        recipeOutput = ""
        savedMessage = ""
        
        Task {
            do {
                if #available(iOS 26.0, *) {
                    let service = AppleRecipeService()
                    let result = try await service.makeRecipe(from: extractedText)
                    
                    await MainActor.run {
                        recipeOutput = result
                        isBuildingRecipe = false
                    }
                } else {
                    let fallback = await recipeCleaner.cleanRecipe(from: extractedText)
                    
                    await MainActor.run {
                        recipeOutput = fallback
                        isBuildingRecipe = false
                    }
                }
            } catch {
                let fallback = await recipeCleaner.cleanRecipe(from: extractedText)
                
                await MainActor.run {
                    recipeOutput = fallback
                    isBuildingRecipe = false
                }
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
        guard let item else {
            await MainActor.run {
                importMessage = "No video item selected."
            }
            return
        }
        
        await MainActor.run {
            importMessage = "Loading video from Photos..."
        }
        
        do {
            if let movie = try await item.loadTransferable(type: MovieTransfer.self) {
                await MainActor.run {
                    selectedVideoURL = movie.url
                    extractedText = ""
                    recipeOutput = ""
                    savedMessage = ""
                    importMessage = "Video ready: \(movie.url.lastPathComponent)"
                    selectedPhotoAssetIdentifier = item.itemIdentifier
                    showDeleteRecordingConfirmation = item.itemIdentifier != nil
                    isScanning = false
                    isBuildingRecipe = false
                }
            } else {
                await MainActor.run {
                    importMessage = "Could not load video file."
                }
            }
        } catch {
            await MainActor.run {
                importMessage = "Video load error: \(error.localizedDescription)"
                extractedText = "Video load error: \(error.localizedDescription)"
            }
        }
    }

    private func deleteImportedRecording() {
        guard let selectedPhotoAssetIdentifier else { return }

        Task {
            do {
                try await deletePhotoAsset(localIdentifier: selectedPhotoAssetIdentifier)

                await MainActor.run {
                    self.selectedPhotoAssetIdentifier = nil
                    importMessage = "Original recording deleted from Photos."
                }
            } catch {
                await MainActor.run {
                    importMessage = "Could not delete recording: \(error.localizedDescription)"
                }
            }
        }
    }

    private nonisolated func deletePhotoAsset(localIdentifier: String) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)

        guard status == .authorized || status == .limited else {
            throw NSError(
                domain: "VideoImporterView",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Photos permission was not granted."]
            )
        }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)

        guard let asset = assets.firstObject else {
            throw NSError(
                domain: "VideoImporterView",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Could not find the imported recording in Photos."]
            )
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets([asset] as NSArray)
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "VideoImporterView",
                        code: 3,
                        userInfo: [NSLocalizedDescriptionKey: "Photos did not delete the recording."]
                    ))
                }
            }
        }
    }

    private func scanVideo(url: URL) {
        isScanning = true
        extractedText = ""
        recipeOutput = ""
        savedMessage = ""

        Task {
            async let ocrText = readVideoText(url: url)
            async let transcriptText = readVideoTranscript(url: url)

            let textParts = await [ocrText, transcriptText]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            await MainActor.run {
                extractedText = textParts.isEmpty ? "No readable text or speech found." : textParts.joined(separator: "\n\n")
                isScanning = false
            }
        }
    }

    private nonisolated func readVideoText(url: URL) async -> String {
        do {
            let ocrService = VideoFrameOCRService()
            let text = try await ocrService.extractTextFromVideo(url: url)
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return ""
            }

            return """
            On-screen text:
            \(text)
            """
        } catch {
            return ""
        }
    }

    private nonisolated func readVideoTranscript(url: URL) async -> String {
        do {
            let speechTranscriber = SpeechTranscriber()
            let transcript = try await speechTranscriber.transcribeVideo(url: url)
            guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return ""
            }

            return """
            Spoken transcript:
            \(transcript)
            """
        } catch {
            return ""
        }
    }
    

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                importMessage = "No file selected."
                return
            }
            
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                let fileExtension = url.pathExtension.isEmpty ? "mp4" : url.pathExtension
                
                let copyURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(fileExtension)
                
                if FileManager.default.fileExists(atPath: copyURL.path) {
                    try FileManager.default.removeItem(at: copyURL)
                }
                
                try FileManager.default.copyItem(at: url, to: copyURL)
                
                Task { @MainActor in
                    selectedVideoURL = copyURL
                    extractedText = ""
                    recipeOutput = ""
                    savedMessage = ""
                    importMessage = "Video ready: \(copyURL.lastPathComponent)"
                    selectedPhotoAssetIdentifier = nil
                    isScanning = false
                    isBuildingRecipe = false
                }
                
            } catch {
                
                importMessage = "File import error: \(error.localizedDescription)"
                extractedText = "File import error: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            importMessage = "Import error: \(error.localizedDescription)"
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
            let fileExtension = received.file.pathExtension.isEmpty ? "mp4" : received.file.pathExtension
            
            let copy = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(fileExtension)
            
            if FileManager.default.fileExists(atPath: copy.path) {
                try FileManager.default.removeItem(at: copy)
            }
            
            try FileManager.default.copyItem(at: received.file, to: copy)
            return MovieTransfer(url: copy)
        }
    }
}
