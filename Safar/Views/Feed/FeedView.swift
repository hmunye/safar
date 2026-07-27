import SwiftData
import SwiftUI

struct FeedView: View {
    @Query(
        sort: \RecitationClip.createdAt,
        order: .reverse
    )
    private var clips: [RecitationClip]

    var body: some View {
        ZStack {
            if clips.isEmpty {
                ContentUnavailableView(
                    "No Recitation Clips",
                    systemImage: "waveform",
                )
                .foregroundStyle(Colors.foreground)
            } else {
                List(clips) { clip in
                    RecitationCardView(
                        clip: clip
                    )
                }
                .listStyle(.plain)
            }
        }
    }
}
