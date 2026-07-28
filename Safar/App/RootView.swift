import SwiftUI

struct RootView: View {
    @State private var importExpanded = false
    @State private var playbackController = PlaybackController()

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            FeedView(
                playbackController: playbackController
            )

            if importExpanded {
                Color.clear
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            importExpanded.toggle()
                        }
                    }
            }

            SettingsButton()
                .padding(.leading, 30)
                .padding(.top, 20)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )

            ImportButton(
                isExpanded: $importExpanded,
                playbackController: playbackController
            )
            .padding(.trailing, 30)
            .padding(.top, 20)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topTrailing
            )
        }
    }
}

#Preview {
    RootView()
}
