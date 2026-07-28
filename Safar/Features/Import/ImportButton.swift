import PhotosUI
import SwiftData
import SwiftUI

struct ImportButton: View {
    @Namespace private var namespace

    @State private var importSession = ImportSession()

    @State private var inputURL = ""
    @State private var selectedItem: PhotosPickerItem?

    @State private var showURLAlert = false
    @State private var showPhotosPicker = false
    @State private var showImportSheet = false

    @Binding private var isExpanded: Bool

    @Environment(\.modelContext)
    private var modelContext

    private let playbackController: PlaybackController
    private let processor: ImportProcessor

    init(
        isExpanded: Binding<Bool>,
        playbackController: PlaybackController
    ) {
        self._isExpanded = isExpanded

        self.playbackController = playbackController
        self.processor = ImportProcessor(
            assetManager: AssetManager(),
            runtime: RecognitionRuntime()
        )
    }

    var body: some View {
        ZStack {
            if isExpanded {
                ImportMenu(action: handleSource)
            } else {
                Button {
                    withAnimation(.bouncy) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundStyle(Colors.foreground)
                        .padding(12)
                }
            }
        }
        .alert("Import URL", isPresented: $showURLAlert) {
            TextField("https://...", text: $inputURL)

            Button("Import") {
                guard let url = URL(string: inputURL) else {
                    return
                }

                startImport(
                    input: .url(url)
                )

                inputURL.removeAll()
            }
            .disabled(!isValidURL)

            Button("Cancel", role: .cancel) {
                inputURL.removeAll()
            }
        }
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $selectedItem,
            matching: .videos
        )
        .onChange(of: selectedItem) { _, item in
            guard let item else {
                return
            }

            startImport(
                input: .photosVideo(item)
            )

            selectedItem = nil
        }
        .sheet(isPresented: $showImportSheet) {
            ProgressSheet(
                session: importSession,
                onConfirm: saveImport,
                onCancel: {
                    importSession.reset()
                    showImportSheet.toggle()
                }
            )
            .interactiveDismissDisabled(
                importSession.state != .preview
                    && importSession.state != .failed
            )
        }
        .matchedGeometryEffect(
            id: "import",
            in: namespace
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 32,
                style: .continuous
            )
        )
        .glassEffect(
            .clear,
            in: RoundedRectangle(
                cornerRadius: 32,
                style: .continuous
            )

        )
    }

    private func handleSource(_ source: ImportSource) {
        switch source {
        case .photos:
            showPhotosPicker = true

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.35
            ) {
                withAnimation(.bouncy) {
                    isExpanded.toggle()
                }
            }
        case .url:
            showURLAlert = true

            withAnimation(.bouncy) {
                isExpanded.toggle()
            }
        }
    }

    private func startImport(input: ImportInput) {
        playbackController.stop()

        importSession.reset()
        importSession.state = .extractingAudio
        importSession.message = "Preparing your recitation..."

        showImportSheet = true

        Task {
            do {
                try await processor.process(
                    input: input,
                    session: importSession
                )
            } catch {
                importSession.state = .failed
                importSession.errorMessage =
                    "We couldn't process this recitation. Please try another source."
            }
        }
    }

    private func saveImport() {
        do {
            try processor.saveImport(
                importSession,
                modelContext
            )

            showImportSheet.toggle()
        } catch {
            importSession.state = .failed
            importSession.errorMessage =
                "We couldn't save this recitation."
        }
    }

    private var isValidURL: Bool {
        guard let url = URL(string: inputURL) else {
            return false
        }

        return url.scheme == "https" && url.host != nil
    }
}
