import AVFoundation
import Foundation

final class AssetManager {
    private let storageDirectory: URL

    init(
        storageURL: URL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appending(path: "Recitations")
    ) {
        self.storageDirectory = storageURL

        try? FileManager.default.createDirectory(
            at: storageDirectory,
            withIntermediateDirectories: true
        )
    }

    func saveAudio(from audioURL: URL) async throws -> RecitationClip {
        let asset = AVURLAsset(url: audioURL)

        let destinationURL =
            storageDirectory
            .appending(path: "clip-\(UUID().uuidString).m4a")

        try? FileManager.default.removeItem(at: destinationURL)

        guard
            let exportSession = AVAssetExportSession(
                asset: asset,
                presetName: AVAssetExportPresetAppleM4A
            )
        else {
            throw AssetError.exportSessionFailed
        }

        do {
            try await exportSession.export(
                to: destinationURL,
                as: .m4a
            )

            return RecitationClip(
                audioURL: destinationURL.path
            )

        } catch is CancellationError {
            throw AssetError.cancelled

        } catch {
            throw AssetError.exportFailed(
                error.localizedDescription
            )
        }
    }
}

enum AssetError: Error {
    case exportSessionFailed
    case exportFailed(String)
    case cancelled
}
