import SwiftUI

struct RootView: View {
    @State private var playbackController = PlaybackController()
    @State private var importExpanded = false

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            DotGrid()
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

private struct DotGrid: View {
    private let spacing: CGFloat = 26.7
    private let dotSize: CGFloat = 2

    var body: some View {
        Canvas { context, size in
            let columns = Int(size.width / spacing) + 1
            let rows = Int(size.height / spacing) + 1

            let offsetX = (size.width - CGFloat(columns - 1) * spacing) / 2
            let offsetY = (size.height - CGFloat(rows - 1) * spacing) / 2

            for column in 0..<columns {
                for row in 0..<rows {
                    let x = offsetX + CGFloat(column) * spacing
                    let y = offsetY + CGFloat(row) * spacing

                    context.fill(
                        Path(
                            ellipseIn: CGRect(
                                x: x,
                                y: y,
                                width: dotSize,
                                height: dotSize
                            )
                        ),
                        with: .color(
                            Colors.foreground.opacity(0.06)
                        )
                    )
                }
            }
        }
    }
}

#Preview {
    RootView()
}
