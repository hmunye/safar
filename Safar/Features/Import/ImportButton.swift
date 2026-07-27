import PhotosUI
import SwiftData
import SwiftUI

struct ImportButton: View {
    private let processor: ImportProcessor

    @State
    private var selectedItem: PhotosPickerItem?

    @Environment(\.modelContext)
    private var modelContext

    init() {
        self.processor = ImportProcessor(
            assetManager: AssetManager(),
            runtime: RecognitionRuntime()
        )
    }

    var body: some View {
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
        .onChange(of: selectedItem) { _, item in
            guard let item else {
                return
            }

            Task {
                try? await processor.process(
                    item: item,
                    modelContext: modelContext
                )

                selectedItem = nil
            }
        }
    }
}
