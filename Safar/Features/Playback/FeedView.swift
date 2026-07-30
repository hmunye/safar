import SwiftData
import SwiftUI

struct FeedView: View {
    @State private var activeClipID: UUID?

    @Query
    private var clips: [RecitationClip]

    private let playbackController: PlaybackController
    private let assetManager = AssetManager()

    init(playbackController: PlaybackController) {
        self.playbackController = playbackController
    }

    var body: some View {
        if clips.isEmpty {
            ContentUnavailableView(
                "No Recitations",
                systemImage: "waveform",
                description: Text("Import a clip to get started")
            )
        } else {
            GeometryReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(clips) { clip in
                            CardView(
                                clip: clip,
                                playbackController: playbackController
                            )
                            .id(clip.id)
                            .frame(
                                width: proxy.size.width,
                                height: proxy.size.height
                            )
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $activeClipID)
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
            }
            .ignoresSafeArea(.keyboard)
            .overlay(alignment: .bottom) {
                VStack {
                    Spacer()

                    AudioScrubber(
                        playerController: playbackController,
                        showTime: true
                    )
                    .padding(.bottom, 24)
                }
                .frame(height: 40)
                .contentShape(Rectangle())
            }
            .animation(.smooth, value: activeClipID)
            .onAppear {
                activeClipID = clips.first?.id
            }
            .onChange(of: activeClipID) { _, newID in
                playActiveClip(newID)
            }
        }
    }

    private func playActiveClip(_ id: UUID?) {
        guard
            let id,
            let clip = clips.first(where: {
                $0.id == id
            })
        else {
            return
        }

        let url = assetManager.url(for: clip.audioFilename)

        do {
            try playbackController.load(url: url, autoplay: true)
        } catch {
            print("failed to load audio clip:", error)
        }
    }
}
