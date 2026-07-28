import SwiftUI

struct MiniAudioPlayer: View {
    @Bindable var player: PlaybackController

    let title: String
    let subtitle: String

    private var progress: Double {
        guard player.duration > 0 else {
            return 0
        }

        return player.currentTime / player.duration
    }

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

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.quaternary)

                    Capsule()
                        .fill(Colors.accent)
                        .frame(
                            width: geometry.size.width * progress
                        )
                }
                .frame(height: 3)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard player.duration > 0 else {
                                return
                            }

                            let percentage = min(
                                max(
                                    value.location.x / geometry.size.width,
                                    0
                                ),
                                1
                            )

                            player.seek(
                                to: percentage * player.duration
                            )
                        }
                )
            }
            .frame(height: 3)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(.ultraThinMaterial)
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .strokeBorder(
                .white.opacity(0.08)
            )
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
