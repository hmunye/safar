import AVFoundation
import SwiftData
import SwiftUI

@main
struct SafarApp: App {
    init() {
        let session = AVAudioSession.sharedInstance()

        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(
            for: [
                RecitationClip.self,
                Verse.self,
            ]
        )
    }
}
