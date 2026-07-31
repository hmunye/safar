import SwiftUI

struct ProgressSheet: View {
    @State private var playbackController = PlaybackController()

    let session: ImportSession
    let onConfirm: () -> Void
    let onCancel: () -> Void

    private var contentTransition: AnyTransition {
        .asymmetric(
            insertion:
                .offset(y: 24)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.96)),
            removal:
                .offset(y: -12)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.98))
        )
    }

    var body: some View {
        VStack {
            switch session.state {
            case .preview:
                previewContent
                    .transition(contentTransition)
            case .error:
                errorContent
                    .transition(contentTransition)
            default:
                processingContent
                    .transition(contentTransition)
            }
        }
        .padding()
        .animation(
            .spring(
                response: 0.42,
                dampingFraction: 0.86,
                blendDuration: 0.10
            ),
            value: session.state
        )
        .presentationDetents([.height(270)])
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder
    private var processingContent: some View {
        VStack(spacing: 70) {
            ZStack {
                Text(session.message.capitalized)
                    .id(session.message)
                    .frame(width: 300)
                    .font(
                        .system(
                            size: 24,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(Colors.foreground)
                    .multilineTextAlignment(.center)
                    .transition(
                        .asymmetric(
                            insertion:
                                .opacity
                                .combined(with: .offset(y: 10)),
                            removal:
                                .opacity
                                .combined(with: .offset(y: -10))
                        )
                    )
            }
            .modifier(
                Shimmer(
                    animation: .linear(duration: 2.0)
                        .delay(0.2)
                        .repeatForever(autoreverses: false),
                    gradient: Gradient(colors: [
                        Colors.background.opacity(0.4),
                        Colors.background,
                        Colors.background.opacity(0.4),
                    ]),
                    bandSize: 0.25
                )
            )

            Button(role: .cancel) {
                UIImpactFeedbackGenerator(style: .light)
                    .impactOccurred()

                onCancel()
            } label: {
                Text("Cancel")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Colors.foreground)
                    .frame(maxWidth: 300)
                    .frame(height: 40)
            }
            .buttonStyle(.glassProminent)
            .tint(Colors.destructive)
        }
        .padding([.top, .horizontal])
        .animation(
            .spring(
                response: 0.38,
                dampingFraction: 0.86,
                blendDuration: 0.08
            ),
            value: session.message
        )
    }

    @ViewBuilder
    private var previewContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 8) {
                Image(systemName: "waveform")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Colors.accent)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Passage Identified")
                        .font(
                            .system(
                                .title2,
                                design: .rounded,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(Colors.foreground)

                    Text(session.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 35)

            if let audioURL = session.audioURL {
                MiniAudioPlayer(
                    player: playbackController,
                    title: detectedTitle,
                    subtitle: detectedRange
                )
                .onAppear {
                    guard playbackController.duration == 0 else {
                        return
                    }

                    Task {
                        do {
                            try await playbackController.load(
                                url: audioURL,
                            )
                        } catch {
                            print("failed to load audio clip:", error)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Button(role: .destructive) {
                    UIImpactFeedbackGenerator(style: .light)
                        .impactOccurred()

                    playbackController.stop()
                    onCancel()
                } label: {
                    Text("Discard")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Colors.foreground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                }
                .buttonStyle(.glass)

                Button(role: .confirm) {
                    UIImpactFeedbackGenerator(style: .light)
                        .impactOccurred()

                    playbackController.stop()
                    onConfirm()
                } label: {
                    Text("Save")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Colors.foreground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                }
                .buttonStyle(.glassProminent)
                .tint(Colors.accent)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var errorContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.slash")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Colors.destructive)
                    .frame(width: 40, height: 40)

                Text("Something Went Wrong")
                    .font(
                        .system(
                            .title2,
                            design: .rounded,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(Colors.foreground)
            }

            Text(session.errorMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(role: .close) {
                UIImpactFeedbackGenerator(style: .light)
                    .impactOccurred()

                onCancel()
            } label: {
                Text("Dismiss")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Colors.foreground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
            }
            .buttonStyle(.glass)
        }
        .padding([.top, .horizontal])
    }

    private var detectedTitle: String {
        return Metadata.surahName(session.matches[0].surah)
    }

    private var detectedRange: String {
        let first = session.matches[0]
        let last = session.matches[session.matches.count - 1]

        return "\(first.surah):\(first.ayah) - \(last.surah):\(last.ayah)"
    }
}

private struct Shimmer: ViewModifier {
    private let animation: Animation
    private let gradient: Gradient
    private let bandSize: CGFloat

    @State private var isInitialState = true

    init(
        animation: Animation,
        gradient: Gradient,
        bandSize: CGFloat
    ) {
        self.animation = animation
        self.gradient = gradient
        self.bandSize = bandSize
    }

    private var startPoint: UnitPoint {
        isInitialState
            ? UnitPoint(
                x: -bandSize,
                y: -bandSize
            )
            : UnitPoint(
                x: 1,
                y: 1
            )
    }

    private var endPoint: UnitPoint {
        isInitialState
            ? UnitPoint(x: 0, y: 0)
            : UnitPoint(
                x: 1 + bandSize,
                y: 1 + bandSize
            )
    }

    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    gradient: gradient,
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
            .animation(
                animation,
                value: isInitialState
            )
            .onAppear {
                DispatchQueue.main.async {
                    isInitialState = false
                }
            }
    }
}
