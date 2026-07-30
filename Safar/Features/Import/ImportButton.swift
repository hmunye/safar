import SwiftUI

struct ImportButton: View {
    @Binding var expanded: Bool

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light)
                .impactOccurred()

            withAnimation(.bouncy) {
                expanded = true
            }
        } label: {
            Image(systemName: "plus")
                .font(.title3)
                .foregroundStyle(Colors.foreground)
                .padding(12)
        }
    }
}
