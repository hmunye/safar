import Foundation
import SwiftData

@Model
class RecitationClip {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var status: ClipStatus
    var audioURL: String

    @Relationship(deleteRule: .cascade, inverse: \RecognizedVerse.clip)
    var matches: [RecognizedVerse]

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        status: ClipStatus = .pending,
        audioURL: String,
        matches: [RecognizedVerse] = []
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
