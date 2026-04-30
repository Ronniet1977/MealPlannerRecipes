import SwiftUI
import AVFoundation
import Vision
import UIKit

final class VideoFrameOCRService {
    
    func extractTextFromVideo(url: URL) async throws -> String {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let duration = try await asset.load(.duration)
        let seconds = CMTimeGetSeconds(duration)
        
        var allText: [String] = []
        
        let frameTimes = stride(from: 0.0, through: seconds, by: 2.0).map {
            CMTime(seconds: $0, preferredTimescale: 600)
        }
        
        for time in frameTimes {
            if let image = try? generator.copyCGImage(at: time, actualTime: nil) {
                let text = try await recognizeText(in: image)
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    allText.append(text)
                }
            }
        }
        
        let cleanedLines = allText
            .joined(separator: "\n")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { line in
                let lower = line.lowercased()
                
                return !lower.contains("tiktok")
                && !lower.contains("@")
                && !lower.contains("us_easyrecipes")
                && !lower.contains("for you")
                && !lower.contains("follow")
            }
        
        let uniqueLines = Array(NSOrderedSet(array: cleanedLines)) as? [String] ?? cleanedLines
        
        return uniqueLines.joined(separator: "\n")
    }
    
    private func recognizeText(in cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                
                let text = observations.compactMap {
                    $0.topCandidates(1).first?.string
                }
                
                continuation.resume(returning: text.joined(separator: "\n"))
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
