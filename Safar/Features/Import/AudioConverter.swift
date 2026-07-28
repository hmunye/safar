import AVFoundation
import Foundation

enum AudioConverter {
    static func convertTo16kHzMonoPCM16WAV(
        from audioURL: URL
    ) async throws -> URL {
        let asset = AVURLAsset(url: audioURL)

        guard
            let track = try await asset.loadTracks(withMediaType: .audio).first
        else {
            throw AudioConverterError.noAudioTrack
        }

        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ]

        let reader = try AVAssetReader(asset: asset)
        let readerOutput = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: outputSettings
        )

        guard reader.canAdd(readerOutput) else {
            throw AudioConverterError.incompatibleTrack
        }

        reader.add(readerOutput)

        let wavURL = FileManager.default.temporaryDirectory
            .appending(path: "audio-\(UUID().uuidString).wav")

        FileManager.default.createFile(
            atPath: wavURL.path,
            contents: nil
        )

        let wavFile = try FileHandle(forWritingTo: wavURL)
        defer {
            try? wavFile.close()
        }

        try writeWavHeader(
            to: wavFile,
            sampleRate: 16_000,
            channels: 1,
            bitsPerSample: 16,
            dataSize: 0
        )

        guard reader.startReading() else {
            throw reader.error ?? AudioConverterError.failedToStart
        }

        var pcmBytesWritten: UInt32 = 0

        while reader.status == .reading {
            guard let sampleBuffer = readerOutput.copyNextSampleBuffer()
            else {
                break
            }

            var audioBufferList = AudioBufferList()
            var blockBuffer: CMBlockBuffer?

            let status =
                CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
                    sampleBuffer,
                    bufferListSizeNeededOut: nil,
                    bufferListOut: &audioBufferList,
                    bufferListSize: MemoryLayout<AudioBufferList>.size,
                    blockBufferAllocator: nil,
                    blockBufferMemoryAllocator: nil,
                    flags:
                        kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                    blockBufferOut: &blockBuffer
                )

            guard status == noErr else {
                continue
            }

            withUnsafeMutablePointer(to: &audioBufferList) { pointer in
                let buffers = UnsafeMutableAudioBufferListPointer(pointer)

                for buffer in buffers {
                    guard let data = buffer.mData else {
                        continue
                    }

                    let size = Int(buffer.mDataByteSize)

                    wavFile.write(
                        Data(bytes: data, count: size)
                    )

                    pcmBytesWritten += UInt32(size)
                }
            }
        }

        if reader.status == .failed {
            throw reader.error ?? AudioConverterError.processingFailed
        }

        try wavFile.seek(toOffset: 0)
        try writeWavHeader(
            to: wavFile,
            sampleRate: 16_000,
            channels: 1,
            bitsPerSample: 16,
            dataSize: pcmBytesWritten
        )

        return wavURL
    }

    private static func writeWavHeader(
        to file: FileHandle,
        sampleRate: UInt32,
        channels: UInt16,
        bitsPerSample: UInt16,
        dataSize: UInt32
    ) throws {
        let byteRate = sampleRate * UInt32(channels) * UInt32(bitsPerSample / 8)
        let blockAlign = channels * (bitsPerSample / 8)

        var header = Data()

        func appendString(_ value: String) {
            header.append(value.data(using: .ascii)!)
        }

        func appendUInt32(_ value: UInt32) {
            var value = value
            header.append(Data(bytes: &value, count: 4))
        }

        func appendUInt16(_ value: UInt16) {
            var value = value
            header.append(Data(bytes: &value, count: 2))
        }

        appendString("RIFF")
        appendUInt32(36 + dataSize)
        appendString("WAVE")

        appendString("fmt ")
        appendUInt32(16)
        appendUInt16(1)
        appendUInt16(channels)
        appendUInt32(sampleRate)
        appendUInt32(byteRate)
        appendUInt16(blockAlign)
        appendUInt16(bitsPerSample)

        appendString("data")
        appendUInt32(dataSize)

        file.write(header)
    }
}

enum AudioConverterError: Error {
    case noAudioTrack
    case incompatibleTrack
    case failedToStart
    case processingFailed
}
