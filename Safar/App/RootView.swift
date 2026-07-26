import PhotosUI
import SwiftData
import SwiftUI

struct RootView: View {
    let runtime: SafarRuntime

    private let assetManager = AssetManager()
    private let audioProcessor = AudioProcessor()

    @Environment(\.modelContext) private var modelContext

    @Query(
        sort: \RecitationClip.createdAt,
        order: .reverse
    )
    private var clips: [RecitationClip]

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var status = "Select a recitation video"

    var body: some View {
        VStack(spacing: 20) {
            PhotosPicker(
                "Select Recitation Video",
                selection: $selectedPhotoItem,
                matching: .videos
            )

            Text(status)
                .multilineTextAlignment(.center)
                .font(.caption)

            List(clips) { clip in
                VStack(alignment: .leading, spacing: 8) {
                    Text(
                        clip.createdAt.formatted()
                    )
                    .font(.headline)

                    Text(
                        "Status: \(clip.status.rawValue)"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Text(
                        clip.audioURL
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    ForEach(clip.matches) { verse in
                        VStack(alignment: .leading) {
                            Text(
                                "\(verse.surah):\(verse.ayah)"
                            )
                            .font(.subheadline)

                            Text(
                                verse.text
                            )

                            Text(
                                "Confidence: \(verse.confidence, specifier: "%.2f")"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

        }
        .padding()
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }

            Task {
                await process(item: item)
            }
        }
    }

    private func process(item: PhotosPickerItem) async {
        do {
            status = "Loading video..."

            guard let data = try await item.loadTransferable(type: Data.self)
            else {
                throw NSError(
                    domain: "RootView",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Failed to load video data"
                    ]
                )
            }

            let tempURL = FileManager.default.temporaryDirectory
                .appending(
                    path: "video-\(UUID()).mov"
                )

            try data.write(to: tempURL)

            status = "Saving audio clip..."

            let savedClip = try await assetManager.saveAudio(
                from: tempURL
            )

            let clip = RecitationClip(
                audioURL: savedClip.audioURL
            )

            modelContext.insert(clip)

            try modelContext.save()

            await processAudio(
                URL(fileURLWithPath: savedClip.audioURL),
                clip: clip
            )

        } catch {
            status = "Error: \(error.localizedDescription)"
        }
    }

    private func processAudio(
        _ url: URL,
        clip: RecitationClip
    ) async {

        do {
            clip.status = .processing
            try modelContext.save()

            status = """
                Preparing recognition:
                \(url.lastPathComponent)
                """

            let wavURL =
                try await audioProcessor
                .convertTo16kHzMonoPCM16Wav(
                    from: url
                )

            status = "Running identifier..."

            let matches = await runtime.identifyVerses(
                from: wavURL
            )

            for match in matches {

                let verse = RecognizedVerse(
                    surah: match.surah,
                    ayah: match.ayah,
                    confidence: match.confidence,
                    text: match.text,
                    clip: clip
                )

                modelContext.insert(verse)
            }

            clip.status =
                matches.isEmpty
                ? .failed
                : .completed

            try modelContext.save()

            if matches.isEmpty {
                status = "Finished - no matches"
            } else {
                status = "Finished - \(matches.count) matches"
            }

        } catch {
            clip.status = .failed
            try? modelContext.save()

            status = "Error: \(error.localizedDescription)"
        }
    }
}
