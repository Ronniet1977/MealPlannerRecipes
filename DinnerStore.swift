import SwiftUI
import Foundation
internal import Combine

class DinnerStore: ObservableObject {
    
    @Published var dinners: [SavedDinner] = []
    
    private var folderURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("Dinners")
    }
    
    init() {
        loadDinners()
    }
    
    func loadDinners() {
        do {
            try FileManager.default.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true
            )
            
            let files = try FileManager.default.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: nil
            )
            
            dinners = files
                .filter { $0.pathExtension == "json" }
                .compactMap { url in
                    guard let data = try? Data(contentsOf: url) else { return nil }
                    return try? JSONDecoder().decode(SavedDinner.self, from: data)
                }
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("Load dinners failed:", error)
        }
    }
    
    func save(_ dinner: SavedDinner) {
        do {
            try FileManager.default.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true
            )
            
            let safeName = dinner.name
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
            
            let url = folderURL.appendingPathComponent("\(safeName)-\(dinner.id.uuidString).json")
            let data = try JSONEncoder().encode(dinner)
            try data.write(to: url)
            
            loadDinners()
        } catch {
            print("Save dinner failed:", error)
        }
    }
    
    func update(_ dinner: SavedDinner) {
        delete(dinner)
        save(dinner)
    }
    
    func delete(_ dinner: SavedDinner) {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: nil
            )
            
            for file in files where file.lastPathComponent.contains(dinner.id.uuidString) {
                try FileManager.default.removeItem(at: file)
            }
            
            loadDinners()
        } catch {
            print("Delete failed:", error)
        }
    }
}
