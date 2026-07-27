import SwiftUI

struct QueueButton: View {
    var body: some View {
        Button {
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "rectangle.stack")
                    .font(.title3)
                    .foregroundStyle(Colors.foreground)
                    .padding(12)
                    .glassEffect()

                Text("1")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Colors.foreground)
                    .frame(
                        width: 23,
                        height: 23
                    )
                    .background(Colors.accent)
                    .clipShape(Circle())
                    .offset(
                        x: 7,
                        y: -7
                    )
            }
        }
    }
}
