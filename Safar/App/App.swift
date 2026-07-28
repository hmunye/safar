import AVFoundation
import SwiftData
import SwiftUI

@main
struct SafarApp: App {
    init() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(
            for: [RecitationClip.self, Verse.self]
        )
    }
}
