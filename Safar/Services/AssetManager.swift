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

        do {
            try FileManager.default.createDirectory(
                at: storageDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            fatalError("failed to create asset directory: \(error)")
        }
    }

    func saveAudio(from audioURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: audioURL)

        let destinationURL =
            storageDirectory
            .appending(path: "clip-\(UUID().uuidString).m4a")

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

            guard FileManager.default.fileExists(atPath: destinationURL.path)
            else {
                throw AssetError.exportFailed("file could not be created")
            }

            return destinationURL

        } catch is CancellationError {
            throw AssetError.cancelled
        } catch {
            throw AssetError.exportFailed(
                error.localizedDescription
            )
        }
    }

    func deleteAudio(at audioURL: URL) throws {
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw AssetError.audioNotFound
        }

        do {
            try FileManager.default.removeItem(at: audioURL)
        } catch {
            throw AssetError.deletionFailed(
                error.localizedDescription
            )
        }
    }

    func filename(
        from url: URL
    ) -> String {
        url.lastPathComponent
    }

    func url(
        for filename: String
    ) -> URL {
        storageDirectory
            .appending(path: filename)
    }
}

enum AssetError: Error {
    case exportSessionFailed
    case exportFailed(String)
    case cancelled
    case audioNotFound
    case deletionFailed(String)
}
