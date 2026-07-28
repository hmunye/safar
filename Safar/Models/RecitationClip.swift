import Foundation
import SwiftData

@Model
class RecitationClip {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var audioFilename: String

    @Relationship(deleteRule: .cascade, inverse: \Verse.clip)
    var matches: [Verse]

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        audioFilename: String,
        matches: [Verse] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.audioFilename = audioFilename
        self.matches = matches
    }
}
