import SwiftUI

struct RootView: View {
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            FeedView()
        }
        .safeAreaInset(edge: .top) {
            HStack {
                ImportButton()
                Spacer()
                QueueButton()
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
        }
    }
}

#Preview {
    RootView()
}
