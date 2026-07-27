import Foundation
import SwiftData

@Model
class Verse {
    var surah: UInt16
    var ayah: UInt16
    var confidence: Float32
    var text: String

    var clip: RecitationClip?

    init(
        surah: UInt16,
        ayah: UInt16,
        confidence: Float32,
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
