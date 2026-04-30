import Foundation
import Speech
import AVFoundation

final class SpeechTranscriber {
    
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    func transcribeVideo(url: URL) async throws -> String {
        let allowed = await requestPermission()
        guard allowed else {
            throw NSError(
                domain: "SpeechTranscriber",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Speech recognition permission denied."]
            )
        }
        
        let audioURL = try await extractAudio(from: url)
        return try await transcribeAudio(url: audioURL)
    }
    
    private func extractAudio(from videoURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw NSError(
                domain: "SpeechTranscriber",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Could not create audio export session."]
            )
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        
        await exportSession.export()
        
        if exportSession.status == .completed {
            return outputURL
        } else {
            throw exportSession.error ?? NSError(
                domain: "SpeechTranscriber",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Audio export failed."]
            )
        }
    }
    
    private func transcribeAudio(url: URL) async throws -> String {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
            throw NSError(
                domain: "SpeechTranscriber",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Speech recognizer unavailable."]
            )
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
}

