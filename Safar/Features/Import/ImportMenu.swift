import SwiftUI

struct ImportMenu: View {
    let action: (ImportSource) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                action(.photos)
            } label: {
                Label(
                    "Photos Library",
                    systemImage: "photo.on.rectangle"
                )
                .padding([.horizontal, .vertical], 10)
            }

            if AppConfig.isURLImportEnabled {
                Button {
                    action(.url)
                } label: {
                    Label(
                        "URL",
                        systemImage: "link"
                    )
                    .padding([.horizontal, .vertical], 10)
                }
            }
        }
        .foregroundStyle(Colors.foreground)
        .padding()
    }
}
