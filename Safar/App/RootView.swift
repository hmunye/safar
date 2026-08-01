import SwiftUI

struct RootView: View {
    @State private var playbackController = PlaybackController()
    @State private var importExpanded = false

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            FeedView(playbackController: playbackController)

            if importExpanded {
                Color.clear
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light)
                            .impactOccurred()

                        withAnimation(.bouncy) {
                            importExpanded = false
                        }
                    }
            }

            SettingsView()
                .padding(.leading, 30)
                .padding(.top, 20)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )

            ImportView(
                expanded: $importExpanded,
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
