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

    func process(
        item: PhotosPickerItem,
        modelContext: ModelContext,
    ) async throws {
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

        let clip = RecitationClip(
            audioURL: savedAudioURL.path
        )

        modelContext.insert(clip)

        clip.status = ClipStatus.processing

        try modelContext.save()

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

        let matches = await runtime.identifyVerses(
            from: wavURL
        )

        for match in matches {
            let verse = Verse(
                surah: match.surah,
                ayah: match.ayah,
                confidence: match.confidence,
                text: match.text,
                clip: clip
            )

            modelContext.insert(verse)
        }

        clip.status =
            matches.isEmpty
            ? ClipStatus.failed
            : .completed

        try modelContext.save()
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
