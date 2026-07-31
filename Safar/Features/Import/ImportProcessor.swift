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

    init(assetManager: AssetManager, runtime: RecognitionRuntime) {
        self.assetManager = assetManager
        self.runtime = runtime
    }

    func process(input: ImportInput, session: ImportSession) async throws {
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

    func saveImport(session: ImportSession, modelContext: ModelContext) throws {
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
                translation: match.translation,
                clip: clip
            )

            modelContext.insert(verse)
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            discardImport(session: session)

            throw error
        }

        NotificationCenter.default.post(
            name: .recitationImported,
            object: nil
        )
    }

    func discardImport(session: ImportSession) {
        guard let audioURL = session.audioURL else {
            return
        }

        try? assetManager.deleteAudio(at: audioURL)
    }

    private func processPhotosVideo(
        item: PhotosPickerItem,
        session: ImportSession
    ) async throws {
        try Task.checkCancellation()
        await session.updateWithDelay(
            state: .processing,
            progress: 0.05,
            message: "Processing your video..."
        )

        let videoURL: URL

        do {
            videoURL = try await createTemporaryVideoURL(
                from: .photosVideo(item)
            )
        } catch {
            session.state = .error
            session.errorMessage =
                "We couldn't process this video. Please try again with a different source."

            return
        }

        defer {
            try? FileManager.default.removeItem(
                at: videoURL
            )
        }

        try Task.checkCancellation()
        await session.updateWithDelay(
            state: .processing,
            progress: 0.3,
            message: "Extracting audio..."
        )

        let savedAudioURL = try await assetManager.saveAudio(
            from: videoURL
        )

        try await processAudio(
            at: savedAudioURL,
            session: session
        )
    }

    private func processURL(
        url: URL,
        session: ImportSession
    ) async throws {
        try Task.checkCancellation()
        await session.updateWithDelay(
            state: .processing,
            progress: 0.05,
            message: "Fetching audio..."
        )

        let audioURL: URL

        do {
            audioURL = try await assetManager.fetchAudio(
                from: url
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch AssetError.serverUnavailable {
            session.state = .error
            session.errorMessage =
                "We couldn't fetch the audio. Is the server running?"

            return
        } catch AssetError.downloadFailed {
            session.state = .error
            session.errorMessage =
                "We couldn't fetch the audio. Check the source and try again."

            return
        } catch {
            session.state = .error
            session.errorMessage =
                "We couldn't fetch the audio. Please try again."

            return
        }
        try await processAudio(
            at: audioURL,
            session: session
        )
    }

    private func processAudio(
        at audioURL: URL,
        session: ImportSession
    ) async throws {
        var keepAudio = false
        defer {
            if !keepAudio {
                try? assetManager.deleteAudio(
                    at: audioURL
                )
            }
        }

        session.audioURL = audioURL

        try Task.checkCancellation()
        await session.updateWithDelay(
            state: .processing,
            progress: 0.5,
            message: "Preparing audio..."
        )

        let wavURL =
            try await AudioConverter
            .convertTo16kHzMonoPCM16WAV(
                from: audioURL
            )
        defer {
            try? FileManager.default.removeItem(
                at: wavURL
            )
        }

        try Task.checkCancellation()
        await session.updateWithDelay(
            state: .processing,
            progress: 0.75,
            message: "Identifying verses..."
        )

        let matches = try await runtime.identifyVerses(
            from: wavURL
        )

        try Task.checkCancellation()

        if matches.isEmpty {
            session.errorMessage =
                "We couldn't identify any verses. Please try again with a different recording."

            await session.updateWithDelay(
                state: .error,
                progress: 1
            )
        } else {
            keepAudio = true
            session.matches = matches

            await session.updateWithDelay(
                state: .preview,
                progress: 1,
                message: "Ready for review"
            )
        }
    }

    private func createTemporaryVideoURL(
        from input: ImportInput
    ) async throws -> URL {
        switch input {
        case .photosVideo(let item):
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
        case .url(_):
            throw ImportProcessorError.videoLoadFailed
        }
    }
}

enum ImportProcessorError: Error {
    case missingAudio
    case videoLoadFailed
}
