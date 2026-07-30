import AVFoundation
import SwiftData
import SwiftUI

@main
struct SafarApp: App {
    init() {
        UITextField.appearance().tintColor = UIColor(Colors.accent)

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
