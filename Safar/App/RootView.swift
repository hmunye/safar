import PhotosUI
import SwiftData
import SwiftUI

struct RootView: View {
    private let recitationProcessor: RecitationProcessor

    @Environment(\.modelContext)
    private var modelContext

    @Query(
        sort: \RecitationClip.createdAt,
        order: .reverse
    )
    private var clips: [RecitationClip]

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var status = "Select a Recitation Video"

    init(runtime: RecognitionRuntime) {
        self.recitationProcessor = RecitationProcessor(
            assetManager: AssetManager(),
            audioProcessor: AudioProcessor(),
            runtime: runtime
        )
    }

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
                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {
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
                        VStack(
                            alignment: .leading
                        ) {
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
            guard let item else {
                return
            }

            Task {
                await process(item)
            }
        }
    }

    private func process(
        _ item: PhotosPickerItem
    ) async {

        do {
            status = "Processing..."

            try await recitationProcessor.process(
                item: item,
                modelContext: modelContext
            )

            status = "Finished"

        } catch {
            status = """
                Error:
                \(error.localizedDescription)
                """
        }
    }
}
