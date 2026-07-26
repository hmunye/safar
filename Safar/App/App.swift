import SwiftData
import SwiftUI

@main
struct SafarApp: App {
    let runtime = RecognitionRuntime()

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
    RootView(runtime: RecognitionRuntime())
        .modelContainer(
            for: [
                RecitationClip.self,
                RecognizedVerse.self,
            ]
        )
}
