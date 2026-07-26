import Foundation
import SwiftData

@Model
class RecognizedVerse {
    var surah: Int
    var ayah: Int
    var confidence: Float
    var text: String

    var clip: RecitationClip?

    init(
        surah: Int,
        ayah: Int,
        confidence: Float,
        text: String,
        clip: RecitationClip? = nil
    ) {
        self.surah = surah
        self.ayah = ayah
        self.confidence = confidence
        self.text = text
        self.clip = clip
    }
}
