import SwiftData
import SwiftUI

struct FeedView: View {
    @Query(
        sort: \RecitationClip.createdAt,
        order: .reverse
    )
    private var clips: [RecitationClip]

    @State private var audioPlayer = AudioPlayer()

    var body: some View {
        if clips.isEmpty {
            ContentUnavailableView(
                "No Recitation Clips",
                systemImage: "waveform"
            )
            .foregroundStyle(Colors.foreground)
        } else {
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(clips) { clip in
                        CardView(
                            clip: clip,
                            audioPlayer: audioPlayer
                        ).containerRelativeFrame(.vertical)
                    }
                }
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
        }
    }
}
