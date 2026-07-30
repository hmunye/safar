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
                response: 0.50,
                dampingFraction: 0.86,
                blendDuration: 0.12
            ),
            value: session.state
        )
        .presentationDetents([.height(290)])
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder
    private var processingContent: some View {
        VStack(spacing: 50) {
            Text(session.message.capitalized)
                .id(session.message)
                .font(
                    .system(
                        size: 21,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .frame(width: 300)
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

            WaveDots()

            Button(role: .cancel) {
                onCancel()
            } label: {
                Text("Cancel")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Colors.foreground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
            }
            .tint(Colors.destructive)
            .buttonStyle(.glassProminent)
        }
        .padding([.top, .horizontal])
        .animation(
            .spring(
                response: 0.38,
                dampingFraction: 0.82,
                blendDuration: 0.10
            ),
            value: session.message
        )
    }

    @ViewBuilder
    private var previewContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 7) {
                Image(systemName: "waveform")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Colors.accent)
                    .frame(width: 62, height: 62)

                Text("Passage Identified")
                    .font(
                        .system(
                            .title2,
                            design: .rounded,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(Colors.foreground)
            }

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

                    do {
                        try playbackController.load(url: audioURL)
                    } catch {
                        print("failed to load audio clip:", error)
                    }
                }
            }

            HStack(spacing: 12) {
                Button(role: .destructive) {
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

                Button {
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
            HStack(spacing: 7) {
                Image(systemName: "waveform.slash")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Colors.destructive)
                    .frame(width: 62, height: 62)

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

            Button(role: .destructive) {
                onCancel()
            } label: {
                Text("Dismiss")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Colors.foreground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
            }
            .tint(Colors.destructive)
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

private struct WaveDots: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { index in
                Circle()
                    .offset(y: animate ? -6 : 6)
                    .frame(width: 10, height: 10)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}
