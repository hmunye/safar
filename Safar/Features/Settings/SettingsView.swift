import SwiftUI

struct SettingsView: View {
    var body: some View {
        SettingsButton()
            .glassEffect(
                .clear,
                in: RoundedRectangle(
                    cornerRadius: 32,
                    style: .continuous
                )
            )
    }
}
