import SwiftUI

struct CardView: View {
    @State private var playbackIndicator: String?
    @State private var activeVerseID: UUID?
    @State private var selectedTranslation: String?
    @State private var showTranslation = false

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
                    .padding(.bottom, 95)
            }
            .overlay {
                if showTranslation,
                    let selectedTranslation
                {
                    translationOverlay(
                        selectedTranslation
                    )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if showTranslation {
                    withAnimation(.bouncy) {
                        showTranslation = false
                    }
                    return
                }

                playbackController.togglePlayback()

                withAnimation(.spring(response: 0.25)) {
                    playbackIndicator =
                        playbackController.isPlaying
                        ? "pause.fill"
                        : "play.fill"
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeOut) {
                        playbackIndicator = nil
                    }
                }
            }
            .onChange(of: activeVerseID) { _, id in
                guard showTranslation else {
                    selectedTranslation = nil
                    return
                }

                if let verse = orderedVerses.first(where: {
                    $0.element.id == id
                }) {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedTranslation = verse.element.translation
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
    private func translationOverlay(
        _ translation: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "quote.bubble.fill")
                    .font(.title3)
                    .foregroundStyle(Colors.foreground)

                Text("Translation - Hilali & Khan")
                    .font(.headline)
                    .foregroundStyle(Colors.foreground)
            }

            Divider()
                .opacity(0.55)

            Text(translation)
                .font(.callout)
                .foregroundStyle(Colors.foreground.opacity(0.7))
                .lineSpacing(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: 340)
        .glassEffect(
            .regular.tint(Colors.background.opacity(0.05)),
            in: RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
        )
        .transition(
            .scale(scale: 0.96)
                .combined(with: .opacity)
        )
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
            spacing: 0
        ) {
            Spacer()

            if showSurah {
                Text(
                    Metadata.surahName(verse.surah)
                )
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(
                    Colors.foreground.opacity(0.9)
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.bottom, 36)
            }

            HStack(spacing: 10) {
                Spacer()

                Text("\(verse.surah):\(verse.ayah)")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(
                        Colors.foreground.opacity(0.6)
                    )

                Button {
                    UIImpactFeedbackGenerator(style: .light)
                        .impactOccurred()

                    selectedTranslation = verse.translation

                    withAnimation(.bouncy) {
                        showTranslation.toggle()
                    }
                } label: {
                    Image(
                        systemName: showTranslation
                            ? "info.circle.fill"
                            : "info.circle"
                    )
                    .font(.title3)
                    .foregroundStyle(
                        showTranslation
                            ? Colors.foreground
                            : Colors.foreground.opacity(0.5)
                    )
                }
                .buttonStyle(.plain)
            }

            Text(verse.text)
                .font(
                    .system(size: 50)
                )
                .lineSpacing(24)
                .multilineTextAlignment(.trailing)
                .minimumScaleFactor(0.75)
                .padding(.top, 18)

            Spacer()
        }
        .foregroundStyle(Colors.foreground)
        .padding(.horizontal, 32)
    }
}
