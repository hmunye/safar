import SwiftUI

struct AudioScrubber: View {
    @State private var scrubTime: TimeInterval = 0
    @State private var isScrubbing = false
    @State private var wasPlayingBeforeScrub = false

    let playerController: PlaybackController

    private var playbackProgress: Double {
        guard playerController.duration > 0 else {
            return 0
        }

        return playerController.currentTime / playerController.duration
    }

    private var scrubProgress: Double {
        guard playerController.duration > 0 else {
            return 0
        }

        return scrubTime / playerController.duration
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)

                Capsule()
                    .fill(Colors.accent)
                    .frame(
                        width: geometry.size.width
                            * (isScrubbing ? scrubProgress : playbackProgress)
                    )
            }
            .frame(
                height: isScrubbing ? 8 : 3
            )
            .overlay(alignment: .top) {
                if isScrubbing {
                    Text(
                        "\(timeString(scrubTime)) / \(timeString(playerController.duration))"
                    )
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Colors.foreground)
                    .offset(y: -28)
                }
            }
            .animation(
                .smooth,
                value: isScrubbing
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isScrubbing {
                            isScrubbing.toggle()
                            scrubTime = playerController.currentTime
                            wasPlayingBeforeScrub = playerController.isPlaying

                            if wasPlayingBeforeScrub {
                                playerController.togglePlayback()
                            }
                        }

                        let percentage = min(
                            max(
                                value.location.x / geometry.size.width,
                                0
                            ),
                            1
                        )

                        scrubTime = percentage * playerController.duration
                    }
                    .onEnded { _ in
                        playerController.seek(to: scrubTime)

                        isScrubbing.toggle()

                        if wasPlayingBeforeScrub {
                            playerController.togglePlayback()
                        }

                        wasPlayingBeforeScrub.toggle()
                    }
            )
        }
        .frame(height: 24)
        .padding(.horizontal, 20)
    }

    private func timeString(
        _ time: TimeInterval
    ) -> String {
        let seconds = Int(time)

        return String(
            format: "%d:%02d",
            seconds / 60,
            seconds % 60
        )
    }
}
