import PhotosUI
import SwiftData
import SwiftUI

struct RootView: View {
    private let recitationProcessor: RecitationProcessor

    @State private var selectedItem: PhotosPickerItem?

    @Environment(\.modelContext)
    private var modelContext

    init(runtime: RecognitionRuntime) {
        self.recitationProcessor = RecitationProcessor(
            assetManager: AssetManager(),
            audioProcessor: AudioProcessor(),
            runtime: runtime
        )
    }

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            FeedView()
        }
        .safeAreaInset(edge: .top) {
            HStack {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .videos
                ) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundStyle(Colors.foreground)
                        .padding(12)
                        .glassEffect()
                }

                Spacer()

                Button {
                } label: {
                    Image(systemName: "rectangle.stack")
                        .font(.title3)
                        .foregroundStyle(Colors.foreground)
                        .padding(12)
                        .glassEffect()

                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
        }
        .onChange(of: selectedItem) { _, item in
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
            try await recitationProcessor.process(
                item: item,
                modelContext: modelContext
            )
        } catch {
            print(
                "Processing failed:",
                error.localizedDescription
            )
        }
    }
}
