import SwiftUI

struct RecitationCardView: View {
    let clip: RecitationClip

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text(
                clip.createdAt.formatted()
            )
            .font(.headline)

            Text(
                "Status: \(clip.status.rawValue)"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            ForEach(clip.matches) { verse in
                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text(
                        "\(verse.surah):\(verse.ayah)"
                    )
                    .font(.subheadline)
                    .bold()

                    Text(
                        verse.text
                    )

                    Text(
                        "Confidence: \(verse.confidence, specifier: "%.2f")"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}
