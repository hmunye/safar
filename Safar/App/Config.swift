import SwiftUI

enum Config {
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
