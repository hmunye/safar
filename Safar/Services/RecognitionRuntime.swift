import CxxStdlib
import Foundation
import SafarCore

struct VerseMatch {
    let surah: UInt16
    let ayah: UInt16
    let confidence: Float32
    let text: String
    let translation: String
}

actor RecognitionRuntime {
    private var recognizer: safar.RecitationIdentifier?

    func identifyVerses(
        from audioURL: URL
    ) async throws -> [VerseMatch] {
        try initializeOnce()

        guard recognizer != nil else {
            throw RecognitionError.notInitialized
        }

        let path = std.string(audioURL.path)
        let matches = recognizer!.identify_verses(path)

        return matches.map { match in
            VerseMatch(
                surah: match.surah,
                ayah: match.ayah,
                confidence: match.confidence,
                text: String(match.text),
                translation: String(match.translation)
            )
        }
    }

    private func initializeOnce() throws {
        guard self.recognizer == nil else { return }

        guard
            let modelURL = Bundle.main.url(
                forResource: "whisper-base-ar-quran-ggml",
                withExtension: "bin"
            )
        else {
            throw RecognitionError.missingModel
        }

        self.recognizer = safar.RecitationIdentifier(
            std.string(modelURL.path)
        )
    }
}

enum RecognitionError: Error {
    case notInitialized
    case missingModel
}
