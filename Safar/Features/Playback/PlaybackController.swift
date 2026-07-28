import AVFoundation

@Observable
final class PlaybackController: NSObject {
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private(set) var isPlaying = false
    private(set) var duration: TimeInterval = 0

    var currentTime: TimeInterval = 0

    func load(url: URL) {
        stop()

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()

            duration = player?.duration ?? 0
            currentTime = 0
        } catch {
            print(error)
        }
    }

    func togglePlayback() {
        guard let player else { return }

        if player.isPlaying {
            pause()
        } else {
            player.play()
            isPlaying = true
            startTimer()
        }
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
    }

    func stop() {
        timer?.invalidate()
        timer = nil

        player?.stop()
        player = nil

        currentTime = 0
        duration = 0
        isPlaying = false
    }

    private func pause() {
        player?.pause()
        timer?.invalidate()
        timer = nil
        isPlaying = false
    }

    private func startTimer() {
        timer?.invalidate()

        timer = .scheduledTimer(withTimeInterval: 0.05, repeats: true) {
            [weak self] _ in
            guard let self else { return }
            self.currentTime = self.player?.currentTime ?? 0
        }
    }
}

extension PlaybackController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        timer?.invalidate()
        timer = nil

        currentTime = 0
        isPlaying = false

        player.currentTime = 0
    }
}
