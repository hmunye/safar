import SwiftUI

struct CardView: View {
    let clip: RecitationClip
    let playbackController: PlaybackController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(
                clip.createdAt.formatted()
            )

            Button {
                let url = AssetManager()
                    .url(for: clip.audioFilename)

                playbackController.load(url: url)
                playbackController.togglePlayback()
            } label: {
                Image(systemName: "play.fill")
            }

            ForEach(clip.matches) { verse in
                VStack(alignment: .leading) {
                    Text("\(verse.surah):\(verse.ayah)")
                    Text(verse.text)
                }
            }
        }
        .padding()
    }
}
