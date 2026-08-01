import SwiftUI

struct MiniAudioPlayer: View {
    @Bindable var player: PlaybackController

    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button {
                    player.togglePlayback()
                } label: {
                    Image(
                        systemName: player.isPlaying
                            ? "pause.fill"
                            : "play.fill"
                    )
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Colors.foreground)
                    .frame(width: 38, height: 38)
                    .background(Colors.accent)
                    .clipShape(Circle())
                }
                .buttonStyle(.plain)

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Colors.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(timeString)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding()

            AudioScrubber(playerController: player, showTime: false)
        }
        .background {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(.clear)
            .stroke(
                Colors.foreground.opacity(0.12),
                lineWidth: 1
            )
        }
    }

    private var timeString: String {
        let current = Int(player.currentTime)

        return String(
            format: "%d:%02d",
            current / 60,
            current % 60
        )
    }
}
