import CxxStdlib
import SafarCore
import SwiftUI

final class SafarEngine {
    let ri: safar.RecitationIdentifier

    init() {
        guard
            let modelURL = Bundle.main.url(
                forResource: "whisper-base-ar-quran-ggml",
                withExtension: "bin"
            )
        else {
            fatalError("missing model")
        }

        ri = safar.RecitationIdentifier(std.string(modelURL.path))
    }
}

@main
struct SafarApp: App {
    let engine = SafarEngine()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
