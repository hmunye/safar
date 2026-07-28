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
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(timeString)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            AudioScrubber(playerController: player)
                .padding(.bottom, 14)
        }
        .background {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(.clear)
            .glassEffect()
        }
        .shadow(
            color: .black.opacity(0.08),
            radius: 12,
            y: 4
        )
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
