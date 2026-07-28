import Foundation

@Observable
final class ImportSession {
    enum State: Int {
        case idle
        case extractingAudio
        case recognizing
        case preview
        case failed
    }

    var state: State = .idle
    var message: String = ""
    var progress: Double = 0
    var audioURL: URL?
    var matches: [VerseMatch] = []
    var errorMessage: String?

    func update(
        state: State,
        progress: Double,
        message: String
    ) {
        self.state = state
        self.progress = progress
        self.message = message
    }

    func reset() {
        state = .idle
        message = ""
        progress = 0
        audioURL = nil
        matches = []
        errorMessage = nil
    }
}
