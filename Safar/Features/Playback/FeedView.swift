import SwiftData
import SwiftUI

struct FeedView: View {
    @Query(
        sort: \RecitationClip.createdAt,
        order: .reverse
    )
    private var clips: [RecitationClip]

    @State private var playbackController = PlaybackController()

    var body: some View {
        if clips.isEmpty {
            ContentUnavailableView(
                "No Recitations",
                systemImage: "waveform",
                description: Text("Import a clip to get started")
                    .font(.caption)
                    .foregroundStyle(.secondary),
            )
            .scaleEffect(1.2)
            .foregroundStyle(Colors.foreground)
        } else {
            ScrollView(.vertical) {
                LazyVStack {
                    ForEach(clips) { clip in
                        CardView(
                            clip: clip,
                            playbackController: playbackController
                        )
                    }
                }
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
        }
    }
}
