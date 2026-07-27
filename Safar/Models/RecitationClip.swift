import Foundation
import SwiftData

@Model
class RecitationClip {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var status: ClipStatus
    var audioURL: String

    @Relationship(deleteRule: .cascade, inverse: \Verse.clip)
    var matches: [Verse]

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        status: ClipStatus = .pending,
        audioURL: String,
        matches: [Verse] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.status = status
        self.audioURL = audioURL
        self.matches = matches
    }
}

enum ClipStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed
}
