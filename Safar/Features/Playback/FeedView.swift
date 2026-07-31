import SwiftData
import SwiftUI

struct FeedView: View {
    @State private var activeClipID: UUID?
    @State private var clips: [RecitationClip] = []
    @State private var offset = 0
    @State private var isLoading = false

    @Environment(\.modelContext)
    private var modelContext

    private let batchSize = 10
    private let assetManager = AssetManager()
    private let playbackController: PlaybackController

    init(playbackController: PlaybackController) {
        self.playbackController = playbackController
    }

    var body: some View {
        Group {
            if clips.isEmpty {
                ContentUnavailableView(
                    "No Recitations Yet",
                    systemImage: "waveform",
                    description: Text("Import a recording to get started")
                )
                .scaleEffect(1.2)
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
                                .contextMenu {
                                    CardMenu {
                                        deleteActiveClip(clip)
                                    }
                                }
                                .onAppear {
                                    if clip.id == clips.last?.id {
                                        Task {
                                            await loadMoreClips()
                                        }
                                    }
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollPosition(id: $activeClipID)
                    .scrollTargetBehavior(.paging)
                    .scrollIndicators(.hidden)
                    .refreshable {
                        UIImpactFeedbackGenerator(style: .medium)
                            .impactOccurred()

                        await refreshFeed()
                    }
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
                    if activeClipID == nil {
                        activeClipID = clips.first?.id
                    }
                }
                .onChange(of: activeClipID) { _, newID in
                    playActiveClip(newID)
                }
            }
        }
        .task {
            if clips.isEmpty {
                await loadMoreClips()
            }
        }
    }

    private func loadMoreClips() async {
        guard !isLoading else {
            return
        }

        isLoading = true

        var descriptor = FetchDescriptor<RecitationClip>(
            sortBy: [
                SortDescriptor(
                    \.createdAt,
                    order: .reverse
                )
            ]
        )

        descriptor.fetchLimit = batchSize
        descriptor.fetchOffset = offset

        do {
            var newClips = try modelContext.fetch(descriptor)
            if offset == 0 {
                newClips.shuffle()
            }

            clips.append(contentsOf: newClips)
            offset += newClips.count
        } catch {
            print("failed loading clips:", error)
        }

        isLoading = false
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

        let url = assetManager.url(
            for: clip.audioFilename
        )

        do {
            try playbackController.load(
                url: url,
                autoplay: true
            )
        } catch {
            print("failed to load audio clip:", error)
        }
    }

    private func deleteActiveClip(_ clip: RecitationClip) {
        let wasActive = activeClipID == clip.id
        if wasActive {
            playbackController.stop()
        }

        let audioURL = assetManager.url(
            for: clip.audioFilename
        )

        try? assetManager.deleteAudio(at: audioURL)

        modelContext.delete(clip)
        try? modelContext.save()

        clips.removeAll {
            $0.id == clip.id
        }

        if wasActive {
            DispatchQueue.main.async {
                activeClipID = clips.first?.id
            }
        }
    }

    private func refreshFeed() async {
        let previousActiveID = activeClipID

        clips.removeAll()
        offset = 0

        await loadMoreClips()

        if let previousActiveID,
            clips.contains(where: { $0.id == previousActiveID })
        {
            activeClipID = previousActiveID
        } else {
            playbackController.stop()
            activeClipID = clips.first?.id
        }
    }
}
