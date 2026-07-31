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

    func fetchAudio(from url: URL) async throws -> URL {
        guard
            let serverIP = Config.serverIP,
            let serverPort = Config.serverPort
        else {
            throw AssetError.serverUnavailable
        }

        var components = URLComponents()

        components.scheme = "http"
        components.host = serverIP
        components.port = serverPort
        components.path = "/audio"
        components.queryItems = [
            URLQueryItem(
                name: "url",
                value: url.absoluteString
            )
        ]

        guard let serverURL = components.url else {
            throw AssetError.serverUnavailable
        }

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 120

        let tempURL: URL
        let response: URLResponse

        do {
            (tempURL, response) = try await URLSession(
                configuration: configuration
            ).download(
                from: serverURL
            )
        } catch let error as URLError {
            switch error.code {
            case .timedOut,
                .cannotConnectToHost,
                .networkConnectionLost,
                .notConnectedToInternet:
                throw AssetError.serverUnavailable

            default:
                throw AssetError.downloadFailed
            }
        }

        guard
            let httpResponse = response as? HTTPURLResponse
        else {
            throw AssetError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw AssetError.downloadFailed
        }

        let destinationURL =
            storageDirectory
            .appending(
                path: "clip-\(UUID().uuidString).m4a"
            )

        try FileManager.default.moveItem(
            at: tempURL,
            to: destinationURL
        )

        guard
            FileManager.default.fileExists(
                atPath: destinationURL.path
            )
        else {
            throw AssetError.exportFailed("file could not be created")
        }

        return destinationURL
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
            return
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
    case serverUnavailable
    case invalidResponse
    case downloadFailed
    case exportSessionFailed
    case exportFailed(String)
    case cancelled
    case deletionFailed(String)
}
