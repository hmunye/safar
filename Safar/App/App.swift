import SwiftData
import SwiftUI

@main
struct SafarApp: App {
    let runtime = SafarRuntime()

    var body: some Scene {
        WindowGroup {
            RootView(runtime: runtime)
        }
        .modelContainer(
            for: [
                RecitationClip.self,
                RecognizedVerse.self,
            ]
        )
    }
}

#Preview {
    RootView(runtime: SafarRuntime())
        .modelContainer(
            for: [
                RecitationClip.self,
                RecognizedVerse.self,
            ]
        )
}
