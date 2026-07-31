import SwiftUI

struct AudioScrubber: View {
    @State private var scrubTime: TimeInterval = 0
    @State private var isScrubbing = false
    @State private var wasPlayingBeforeScrub = false

    let playerController: PlaybackController
    let showTime: Bool

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
                if isScrubbing && showTime {
                    Text(
                        "\(timeString(scrubTime)) / \(timeString(playerController.duration))"
                    )
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(Colors.foreground)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background {
                        Capsule()
                            .glassEffect(.clear)
                    }
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                .white.opacity(0.1),
                                lineWidth: 0.5
                            )
                    }
                    .offset(y: -40)
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
                            isScrubbing = true
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

                        isScrubbing = false

                        if wasPlayingBeforeScrub {
                            playerController.togglePlayback()
                        }

                        wasPlayingBeforeScrub = false
                    }
            )
        }
        .padding(.horizontal, 20)
        .frame(height: 24)
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
