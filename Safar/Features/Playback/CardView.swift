import SwiftUI

struct CardView: View {
    @State private var playbackIndicator: String?
    @State private var activeVerseID: UUID?

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
                        .scaleEffect(x: -1)
                        .id(verse.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $activeVerseID)
            .scrollIndicators(.hidden)
            .scaleEffect(x: -1)
            .overlay {
                if let playbackIndicator {
                    Image(systemName: playbackIndicator)
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(Colors.foreground)
                        .shadow(radius: 8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .overlay(alignment: .bottom) {
                pageIndicator
                    .padding(.bottom, 100)
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
            .onAppear {
                if activeVerseID == nil {
                    activeVerseID = orderedVerses.first?.element.id
                }
            }
        }
    }

    @ViewBuilder
    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(orderedVerses, id: \.element.id) { _, verse in
                Circle()
                    .fill(
                        verse.id == activeVerseID
                            ? Colors.foreground
                            : Colors.foreground.opacity(0.2)
                    )
                    .frame(width: 6, height: 6)
            }
        }
        .scaleEffect(x: -1)
    }

    private func verseView(
        _ verse: Verse,
        showSurah: Bool
    ) -> some View {
        VStack(
            alignment: .trailing,
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
                .font(.system(size: 42, weight: .regular))
                .lineSpacing(16)
                .multilineTextAlignment(.trailing)

            Text(verse.translation)
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
                .lineSpacing(10)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 32)
        .foregroundStyle(Colors.foreground)
    }
}
