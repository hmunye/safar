import SwiftData
import SwiftUI

@main
struct SafarApp: App {
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
