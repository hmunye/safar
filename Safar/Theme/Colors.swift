import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )

        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255

        self.init(
            red: r,
            green: g,
            blue: b
        )
    }

    init(
        light: String,
        dark: String
    ) {
        self.init(
            UIColor { traitCollection in
                let hex =
                    traitCollection.userInterfaceStyle == .dark
                    ? dark
                    : light

                return UIColor(Color(hex: hex))
            }
        )
    }
}

enum Colors {
    static let background = Color(
        light: "#2B2A27",
        dark: "#2B2A27"
    )

    static let foreground = Color(
        light: "#F4F3EE",
        dark: "#F4F3EE"
    )

    static let accent = Color(
        light: "#5F8C5A",
        dark: "#5F8C5A",
    )
}
