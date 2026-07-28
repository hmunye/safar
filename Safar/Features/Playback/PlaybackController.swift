import AVFoundation

@Observable
final class PlaybackController: NSObject {
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var loadedURL: URL?

    private(set) var isPlaying = false
    private(set) var duration: TimeInterval = 0

    var currentTime: TimeInterval = 0

    func load(url: URL, autoplay: Bool = false) throws {
        if loadedURL == url {
            if autoplay {
                play()
            }
            return
        }

        stop()

        let player = try AVAudioPlayer(contentsOf: url)

        player.delegate = self
        player.prepareToPlay()

        self.player = player
        loadedURL = url
        duration = player.duration
        currentTime = 0

        if autoplay {
            play()
        }
    }

    func togglePlayback() {
        guard let player else {
            return
        }

        if player.isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
    }

    func stop() {
        stopTimer()

        player?.stop()
        player = nil
        loadedURL = nil

        currentTime = 0
        duration = 0
        isPlaying.toggle()

        // try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func play() {
        guard let player else {
            return
        }

        if player.currentTime >= player.duration {
            player.currentTime = 0
            currentTime = 0
        }

        // try? AVAudioSession.sharedInstance().setActive(true)

        player.play()

        isPlaying.toggle()
        startTimer()
    }

    private func pause() {
        player?.pause()

        stopTimer()

        isPlaying.toggle()

        // try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func startTimer() {
        stopTimer()

        timer = .scheduledTimer(
            withTimeInterval: 0.05,
            repeats: true
        ) { [weak self] _ in
            guard let self else {
                return
            }

            currentTime = player?.currentTime ?? 0
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

extension PlaybackController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        player.currentTime = 0
        currentTime = 0

        player.play()
    }
}
