import SwiftUI

struct RootView: View {
    @State private var importExpanded = false

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            if importExpanded {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            importExpanded.toggle()
                        }
                    }
            }

            FeedView()

            SettingsButton()
                .padding(.leading, 30)
                .padding(.top, 20)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )

            ImportButton(expanded: $importExpanded)
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
