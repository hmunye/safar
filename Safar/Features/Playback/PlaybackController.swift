import AVFoundation

@Observable
final class PlaybackController: NSObject {
    private var player: AVAudioPlayer?
    private var timerTask: Task<Void, Never>?
    private var loadedURL: URL?

    private(set) var isPlaying = false
    private(set) var duration: TimeInterval = 0

    var currentTime: TimeInterval = 0

    func load(url: URL, autoplay: Bool = false) async throws {
        if loadedURL == url {
            if autoplay {
                play()
            }
            return
        }

        stop()

        let newPlayer = try await Task.detached {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        }.value

        newPlayer.delegate = self

        player = newPlayer
        loadedURL = url
        duration = newPlayer.duration
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
        isPlaying = false

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

        isPlaying = true
        startTimer()
    }

    private func pause() {
        player?.pause()

        stopTimer()

        isPlaying = false

        // try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func startTimer() {
        stopTimer()

        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else {
                    return
                }

                currentTime = player?.currentTime ?? 0

                try? await Task.sleep(
                    nanoseconds: 100_000_000
                )
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
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
