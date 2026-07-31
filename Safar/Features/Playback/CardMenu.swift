import SwiftUI

struct CardMenu: View {
    let onDelete: () -> Void

    var body: some View {
        Button(role: .destructive) {
            onDelete()
        } label: {
            Label(
                "Delete",
                systemImage: "trash"
            )
        }
    }
}
