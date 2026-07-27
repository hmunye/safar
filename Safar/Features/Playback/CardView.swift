import SwiftUI

struct CardView: View {
    let clip: RecitationClip
    let audioPlayer: AudioPlayer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(
                clip.createdAt.formatted()
            )

            Text(
                "Status: \(clip.status.rawValue)"
            )

            Button {
                let url = URL(
                    filePath: clip.audioURL
                )
                
                audioPlayer.play(url: url)
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
