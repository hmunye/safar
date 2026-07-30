import AVFoundation
import SwiftData
import SwiftUI
import UIKit

@main
struct SafarApp: App {
    init() {
        UITextField.appearance().tintColor = UIColor(Colors.accent)

        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(
            for: [RecitationClip.self, Verse.self]
        )
    }
}

enum AppConfig {
    static var serverIP: String? {
        value(for: "ServerIP")
    }

    static var serverPort: Int? {
        guard
            let value = value(for: "ServerPort"),
            let port = Int(value)
        else {
            return nil
        }

        return port
    }

    static var isURLImportEnabled: Bool {
        serverIP != nil && serverPort != nil
    }

    private static func value(for key: String) -> String? {
        guard
            let value = Bundle.main.object(
                forInfoDictionaryKey: key
            ) as? String,
            !value.isEmpty
        else {
            return nil
        }

        return value
    }
}
