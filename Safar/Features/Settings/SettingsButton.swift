import SwiftUI

struct SettingsButton: View {
    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light)
                .impactOccurred()
        } label: {
            MenuIcon()
                .font(.title3)
                .foregroundStyle(Colors.foreground)
                .padding(14.5)
        }
    }
}

struct MenuIcon: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Capsule()
                .frame(width: 16, height: 2)

            Capsule()
                .frame(width: 16, height: 2)

            Capsule()
                .frame(width: 8, height: 2)
        }
    }
}
