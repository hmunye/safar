import PhotosUI
import SwiftData
import SwiftUI

struct ImportButton: View {
    private let processor: ImportProcessor

    @Namespace private var namespace

    @State private var selectedItem: PhotosPickerItem?
    @State private var importSession = ImportSession()
    @State private var showingPhotosPicker = false
    @State private var showingImportSheet = false

    @Binding private var expanded: Bool

    @Environment(\.modelContext)
    private var modelContext

    init(expanded: Binding<Bool>) {
        self._expanded = expanded

        self.processor = ImportProcessor(
            assetManager: AssetManager(),
            runtime: RecognitionRuntime()
        )
    }

    var body: some View {
        ZStack {
            if expanded {
                ImportMenu { source in
                    switch source {
                    case .photos:
                        showingPhotosPicker = true

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            withAnimation(.bouncy) {
                                expanded.toggle()
                            }
                        }
                    }
                }
            } else {
                Button {
                    withAnimation(.bouncy) {
                        expanded.toggle()
                    }

                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundStyle(Colors.foreground)
                        .padding(12)
                }
            }
        }
        .photosPicker(
            isPresented: $showingPhotosPicker,
            selection: $selectedItem,
            matching: .videos
        )
        .sheet(isPresented: $showingImportSheet) {
            ProgressSheet(
                session: importSession,
                onConfirm: saveImport,
                onCancel: {
                    importSession.reset()
                    showingImportSheet = false
                }
            )
            .interactiveDismissDisabled(
                importSession.state != .preview
                    && importSession.state != .failed
            )
        }
        .onChange(of: selectedItem) { _, item in
            guard let item else {
                return
            }

            importSession.reset()

            importSession.state =
                .extractingAudio

            importSession.message =
                "Preparing your recitation..."

            showingImportSheet = true

            Task {
                do {
                    try await processor.processVideo(
                        item: item,
                        modelContext: modelContext,
                        session: importSession,
                    )
                } catch {
                    importSession.state = .failed
                    importSession.errorMessage =
                        "We couldn't process this recitation. Please try another video."
                }
            }
        }
        .matchedGeometryEffect(
            id: "import",
            in: namespace
        )
        .glassEffect(
            .clear,
            in: RoundedRectangle(
                cornerRadius: 32,
                style: .continuous
            )
        )
    }

    private func saveImport() {
        guard let audioURL = importSession.audioURL else {
            return
        }

        let clip = RecitationClip(audioFilename: audioURL.lastPathComponent)

        modelContext.insert(clip)

        for match in importSession.matches {
            let verse = Verse(
                surah: match.surah,
                ayah: match.ayah,
                confidence: match.confidence,
                text: match.text,
                clip: clip
            )

            modelContext.insert(verse)
        }

        do {
            try modelContext.save()

            importSession.reset()
            showingImportSheet = false
            selectedItem = nil
        } catch {
            importSession.state = .failed
            importSession.errorMessage = "We couldn't save this recitation."
        }
    }

}
