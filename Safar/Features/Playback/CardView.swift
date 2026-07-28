import SwiftUI

struct CardView: View {
    @State private var playbackIndicator: String?

    let clip: RecitationClip
    let playbackController: PlaybackController

    private var orderedVerses: [(offset: Int, element: Verse)] {
        Array(
            clip.matches
                .sorted { $0.ayah < $1.ayah }
                .enumerated()
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(
                        orderedVerses,
                        id: \.element.id
                    ) { index, verse in
                        verseView(
                            verse,
                            showSurah: index == 0
                        )
                        .frame(width: proxy.size.width)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .overlay {
                if let playbackIndicator {
                    Image(systemName: playbackIndicator)
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(radius: 8)
                        .transition(
                            .scale.combined(with: .opacity)
                        )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                playbackController.togglePlayback()

                withAnimation(.spring(response: 0.25)) {
                    playbackIndicator =
                        playbackController.isPlaying
                        ? "pause.fill"
                        : "play.fill"
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut) {
                        playbackIndicator = nil
                    }
                }
            }
        }
    }

    private func verseView(
        _ verse: Verse,
        showSurah: Bool
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 24
        ) {
            Spacer()

            if showSurah {
                Text(
                    Metadata.surahName(verse.surah)
                )
                .font(.largeTitle)
                .fontWeight(.bold)
            }

            Text("\(verse.surah):\(verse.ayah)")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(verse.text)
                .font(.system(size: 38))
                .lineSpacing(12)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 32)
        .foregroundStyle(Colors.foreground)
    }
}

