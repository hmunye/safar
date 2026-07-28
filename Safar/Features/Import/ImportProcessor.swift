import Foundation
import PhotosUI
import SwiftData
import SwiftUI

final class ImportProcessor {
    private let assetManager: AssetManager
    private let runtime: RecognitionRuntime

    init(
        assetManager: AssetManager,
        runtime: RecognitionRuntime
    ) {
        self.assetManager = assetManager
        self.runtime = runtime
    }

    func processVideo(
        item: PhotosPickerItem,
        modelContext: ModelContext,
        session: ImportSession
    ) async throws {
        session.update(
            state: .extractingAudio,
            progress: 0.15,
            message: "Preparing your audio..."
        )

        let videoURL = try await createTemporaryVideoURL(
            from: item
        )

        defer {
            try? FileManager.default.removeItem(
                at: videoURL
            )
        }

        let savedAudioURL = try await assetManager.saveAudio(
            from: videoURL
        )

        session.audioURL = savedAudioURL

        session.update(
            state: .extractingAudio,
            progress: 0.35,
            message: "Audio prepared"
        )

        let wavURL =
            try await AudioConverter
            .convertTo16kHzMonoPCM16WAV(
                from: savedAudioURL
            )

        defer {
            try? FileManager.default.removeItem(
                at: wavURL
            )
        }

        session.update(
            state: .recognizing,
            progress: 0.45,
            message: "Finding verses in your recitation..."
        )

        let matches = await runtime.identifyVerses(
            from: wavURL
        )

        session.matches = matches

        session.update(
            state: .recognizing,
            progress: 0.85,
            message: "Organizing your results..."
        )

        session.update(
            state: .preview,
            progress: 1,
            message: "Your recitation is ready"
        )
    }

    private func createTemporaryVideoURL(
        from item: PhotosPickerItem
    ) async throws -> URL {
        guard
            let data = try await item.loadTransferable(
                type: Data.self
            )
        else {
            throw ImportProcessorError.videoLoadFailed
        }

        let url = FileManager.default
            .temporaryDirectory
            .appending(
                path: "video-\(UUID().uuidString).mov"
            )

        try data.write(to: url)
        return url
    }
}

enum ImportProcessorError: Error {
    case videoLoadFailed
}
