import AVFoundation

@Observable
final class AudioPlayer {
    private var player: AVAudioPlayer?
    private(set) var isPlaying = false

    func play(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)

            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Audio error:", error)
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }
}
