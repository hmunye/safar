import SwiftUI

struct ProgressSheet: View {
    @State private var playbackController = PlaybackController()

    let session: ImportSession
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            switch session.state {
            case .preview:
                previewContent
            default:
                processingContent
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(340)])
        .presentationBackground(.clear)
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder
    private var processingContent: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 34))
            .foregroundStyle(Colors.accent)

        VStack(spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(session.message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .animation(.easeInOut, value: session.message)
        }

        ProgressView(value: session.progress)
            .tint(Colors.accent)
            .scaleEffect(y: 2)
            .animation(.easeInOut(duration: 0.6), value: session.progress)
    }

    @ViewBuilder
    private var previewContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(Colors.accent)

            VStack(spacing: 6) {
                Text("Recitation Ready")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Review before saving")
                    .foregroundStyle(.secondary)
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
                Button {
                    playbackController.stop()
                    onCancel()
                } label: {
                    Text("Discard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(Colors.accent)

                Button {
                    playbackController.stop()
                    onConfirm()
                } label: {
                    Text("Save Recitation")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Colors.accent)
            }
        }
    }

    private var detectedTitle: String {
        guard let first = session.matches.first else {
            return "Recitation"
        }

        return Metadata.surahName(first.surah)
    }

    private var detectedRange: String {
        guard
            let first = session.matches.first,
            let last = session.matches.last
        else {
            return ""
        }

        return "\(first.surah):\(first.ayah) - \(last.surah):\(last.ayah)"
    }
    private var title: String {
        switch session.state {
        case .idle:
            "Preparing Recitation"
        case .extractingAudio:
            "Preparing Your Audio"
        case .recognizing:
            "Finding Your Verses"
        case .preview:
            "Recitation Ready"
        case .failed:
            "Unable to Process"
        }
    }
}
