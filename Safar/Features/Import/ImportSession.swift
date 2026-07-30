import Foundation

@Observable
final class ImportSession {
    enum State: Int, Equatable {
        case idle
        case processing
        case preview
        case error
    }

    var state: State = .idle
    var message = ""
    var errorMessage = ""
    var matches: [VerseMatch] = []
    var audioURL: URL?
    var progress: Double = 0

    @MainActor
    func update(
        state: State,
        progress: Double,
        message: String = ""
    ) {
        self.state = state
        self.progress = progress
        self.message = message
    }

    @MainActor
    func updateWithDelay(
        state: State,
        progress: Double,
        message: String = "",
        delay: UInt64 = 650_000_000
    ) async {
        self.update(state: state, progress: progress, message: message)

        try? await Task.sleep(nanoseconds: delay)
    }

    @MainActor
    func reset() {
        state = .idle
        message.removeAll()
        errorMessage.removeAll()
        matches.removeAll()
        audioURL = nil
        progress = 0
    }
}
