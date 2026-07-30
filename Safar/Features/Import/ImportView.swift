import PhotosUI
import SwiftData
import SwiftUI

struct ImportView: View {
    @Namespace private var namespace

    @State private var importSession = ImportSession()
    @State private var importTask: Task<Void, Never>?

    @State private var selectedItem: PhotosPickerItem?
    @State private var inputURL = ""

    @State private var showPhotosPicker = false
    @State private var showURLAlert = false

    @State private var showImportSheet = false

    @Binding private var expanded: Bool

    @Environment(\.modelContext)
    private var modelContext

    private let playbackController: PlaybackController
    private let importProcessor: ImportProcessor

    init(expanded: Binding<Bool>, playbackController: PlaybackController) {
        self._expanded = expanded

        self.playbackController = playbackController
        self.importProcessor = ImportProcessor(
            assetManager: AssetManager(),
            runtime: RecognitionRuntime()
        )
    }

    var body: some View {
        ZStack {
            if expanded {
                ImportMenu(
                    action: handleSource
                )
            } else {
                ImportButton(
                    expanded: $expanded
                )
            }
        }
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $selectedItem,
            matching: .videos
        )
        .alert("Import from URL", isPresented: $showURLAlert) {
            TextField("Enter a URL", text: $inputURL)
                .submitLabel(.go)
                .keyboardType(.URL)
                .disableAutocorrection(true)
                .foregroundStyle(Colors.foreground)
                .textInputAutocapitalization(.never)

            Button("Import", role: .confirm) {
                UIImpactFeedbackGenerator(style: .light)
                    .impactOccurred()

                guard let url = URL(string: inputURL) else {
                    return
                }

                inputURL.removeAll()
                startImport(.url(url))
            }
            .disabled(
                URL(string: inputURL)?.scheme != "https"
                    || URL(string: inputURL)?.host == nil
            )
            .foregroundStyle(Colors.foreground)

            Button("Cancel", role: .cancel) {
                UIImpactFeedbackGenerator(style: .light)
                    .impactOccurred()

                inputURL.removeAll()
            }
            .foregroundStyle(Colors.foreground)
        }
        .sheet(isPresented: $showImportSheet) {
            ProgressSheet(
                session: importSession,
                onConfirm: {
                    do {
                        try importProcessor.saveImport(
                            session: importSession,
                            modelContext: modelContext
                        )

                        importSession.reset()
                        showImportSheet = false
                    } catch {
                        importSession.state = .error
                        importSession.errorMessage =
                            "We couldn't save this recording. Please import again or choose a different source."
                    }
                },
                onCancel: {
                    importProcessor.discardImport(
                        session: importSession
                    )

                    importSession.reset()
                    showImportSheet = false
                }
            )
            .interactiveDismissDisabled()
            .onDisappear {
                importTask?.cancel()
                importTask = nil
            }
        }
        .onChange(of: selectedItem) { _, item in
            guard let item else {
                return
            }

            startImport(.photosVideo(item))
            selectedItem = nil
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

    private func handleSource(
        _ source: ImportSource
    ) {
        switch source {
        case .photos:
            showPhotosPicker = true

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.35
            ) {
                withAnimation(.bouncy) {
                    expanded = false
                }
            }
        case .url:
            guard Config.isURLImportEnabled else {
                return
            }

            showURLAlert = true

            withAnimation(.bouncy) {
                expanded = false
            }
        }
    }

    private func startImport(
        _ input: ImportInput
    ) {
        playbackController.stop()

        importSession.reset()
        showImportSheet = true

        importTask?.cancel()
        importTask = Task {
            do {
                try await importProcessor.process(
                    input: input,
                    session: importSession
                )
            } catch is CancellationError {
                importSession.state = .error
                importSession.errorMessage =
                    "The import was interrupted unexpectedly. Please try again."
            } catch {
                importSession.state = .error
                importSession.errorMessage =
                    "We couldn't process this recording. Please try again or choose a different source."
            }
        }
    }
}
