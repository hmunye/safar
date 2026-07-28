import Foundation
import PhotosUI
import SwiftData
import SwiftUI

enum ImportSource {
    case photos
    case url
}

enum ImportInput {
    case photosVideo(PhotosPickerItem)
    case url(URL)
}

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

    func process(
        input: ImportInput,
        session: ImportSession
    ) async throws {
        switch input {
        case .photosVideo(let item):
            try await processPhotosVideo(
                item: item,
                session: session
            )
        case .url(let url):
            try await processURL(
                url: url,
                session: session
            )
        }
    }

    func saveImport(
        _ session: ImportSession,
        _ modelContext: ModelContext
    ) throws {
        guard let audioURL = session.audioURL else {
            throw ImportProcessorError.missingAudio
        }

        let clip = RecitationClip(audioFilename: audioURL.lastPathComponent)

        modelContext.insert(clip)

        for match in session.matches {
            let verse = Verse(
                surah: match.surah,
                ayah: match.ayah,
                confidence: match.confidence,
                text: match.text,
                clip: clip
            )

            modelContext.insert(verse)
        }

        try modelContext.save()
        session.reset()
    }

    private func processPhotosVideo(
        item: PhotosPickerItem,
        session: ImportSession,
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

        let matches = try await runtime.identifyVerses(
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

    private func processURL(
        url: URL,
        session: ImportSession
    ) async throws {
        // download video/audio
        // pass through the same pipeline
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
    case missingAudio
    case videoLoadFailed
}
