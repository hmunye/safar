import SwiftUI

struct SettingsButton: View {
    var body: some View {
        Button {
        } label: {
            MenuIcon()
                .font(.title3)
                .foregroundStyle(Colors.foreground)
                .padding(14)
                .glassEffect(
                    .clear,
                    in: RoundedRectangle(
                        cornerRadius: 32,
                        style: .continuous
                    )
                )
        }
    }
}

struct MenuIcon: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Capsule()
                .frame(width: 18, height: 2)

            Capsule()
                .frame(width: 18, height: 2)

            Capsule()
                .frame(width: 10, height: 2)
        }
    }
}
