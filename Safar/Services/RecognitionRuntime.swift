import CxxStdlib
import Foundation
import SafarCore

struct VerseMatch {
    let surah: Int
    let ayah: Int
    let confidence: Float
    let text: String
}

final class RecognitionRuntime {
    private var recognizer: safar.RecitationIdentifier?

    func identifyVerses(
        from audioURL: URL
    ) async -> [VerseMatch] {
        initializeOnce()

        let path = std.string(audioURL.path)

        return await Task(priority: .userInitiated) {
            guard self.recognizer != nil else {
                fatalError("RecitationIdentifier not initialized")
            }

            let matches = self.recognizer!.identify_verses(path)

            return matches.map { match in
                VerseMatch(
                    surah: Int(match.surah),
                    ayah: Int(match.ayah),
                    confidence: match.confidence,
                    text: String(match.text)
                )
            }
        }.value
    }

    private func initializeOnce() {
        guard self.recognizer == nil else { return }

        guard
            let modelURL = Bundle.main.url(
                forResource: "whisper-base-ar-quran-ggml",
                withExtension: "bin"
            )
        else {
            fatalError("Missing ASR model")
        }

        self.recognizer = safar.RecitationIdentifier(
            std.string(modelURL.path)
        )
    }
}
