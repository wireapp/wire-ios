//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import AVFoundation
import Foundation
import MobileCoreServices
import WireDataModel

private let zmLog = ZMSLog(tag: "UI")

public final class FileMetaDataGenerator: FileMetaDataGeneratorProtocol {

    @available(*, deprecated, message: "This shared instance supports legacy static usage. Don't use it.")
    public static var shared = FileMetaDataGenerator(previewGenerator: SharedPreviewGenerator.generator)

    private let previewGenerator: FilePreviewGenerator

    init(previewGenerator: FilePreviewGenerator) {
        self.previewGenerator = previewGenerator
    }

    public convenience init() {
        self.init(previewGenerator: SharedPreviewGenerator.generator)
    }

    public func metadataForFile(at url: URL) async -> ZMFileMetadata {

        let thumbnail: Data?
        do {
            thumbnail = try await previewGenerator.generatePreviewForFile(at: url)
                .jpegData(compressionQuality: 0.9)
        } catch {
            thumbnail = nil
            WireLogger.ui.error("Failed to generate preview for file: \(url)")
        }

        if let uniformType = url.uniformType, AVURLAsset.wr_isAudioVisualUniformType(uniformType) {
            let asset = AVURLAsset(url: url)
            if let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first {
                return ZMVideoMetadata(fileURL: url, duration: asset.duration.seconds, dimensions: videoTrack.naturalSize, thumbnail: thumbnail)
            } else {
                let loudness = asset.audioSamplesFromAsset(maxSamples: 100)
                return ZMAudioMetadata(fileURL: url, duration: asset.duration.seconds, normalizedLoudness: loudness ?? [])
            }

        } else {
            // swiftlint:disable:next todo_requires_jira_link
            // TODO: set the name of the file (currently there's no API, it always gets it from the URL)
            return ZMFileMetadata(fileURL: url, thumbnail: thumbnail)
        }
    }
}

extension AVURLAsset {

    static func wr_isAudioVisualUniformType(_ uniformType: UTType) -> Bool {
        audiovisualTypes()
            .compactMap { avFileType in UTType(avFileType.rawValue) }
            .contains { uniformType.conforms(to: $0) }
    }
}

extension AVAsset {

    fileprivate func audioSamplesFromAsset(maxSamples: UInt64) -> [Float]? {
        guard let assetTrack: AVAssetTrack = tracks(withMediaType: AVMediaType.audio).first else {
            return .none
        }

        let reader: AVAssetReader
        do {
            reader = try AVAssetReader(asset: self)
        } catch {
            zmLog.error("Cannot read asset metadata for \(self): \(error)")
            return .none
        }

        let outputSettings: [String: Any] = [AVFormatIDKey: NSNumber(value: kAudioFormatLinearPCM),
                                             AVLinearPCMBitDepthKey: 16,
                                             AVLinearPCMIsBigEndianKey: false,
                                             AVLinearPCMIsFloatKey: false,
                                             AVLinearPCMIsNonInterleaved: false]

        let output: AVAssetReaderTrackOutput = AVAssetReaderTrackOutput(track: assetTrack,
                                              outputSettings: outputSettings)
        output.alwaysCopiesSampleData = false
        reader.add(output)
        var sampleCount: UInt64 = 0

        let ratio: Float64 = Float64(duration.value) / Float64(duration.timescale)

        assetTrack.formatDescriptions.forEach { item in
            let formatDescription: CMFormatDescription = item as! CMFormatDescription
            if let mSampleRate: Float64 = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)?.pointee.mSampleRate {
                sampleCount = UInt64(mSampleRate * ratio)
            }
        }

        let stride: Int = Int(max(sampleCount / maxSamples, 1))
        var sampleData: [Float] = []
        var sampleSkipCounter: Int = 0

        reader.startReading()

        while reader.status == .reading {
            if let sampleBuffer: CMSampleBuffer = output.copyNextSampleBuffer() {
                var audioBufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: AudioBuffer(mNumberChannels: 0, mDataByteSize: 0, mData: nil))
                var buffer: CMBlockBuffer?
                var bufferSize: Int = 0
                CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
                    sampleBuffer,
                    bufferListSizeNeededOut: &bufferSize,
                    bufferListOut: nil,
                    bufferListSize: 0,
                    blockBufferAllocator: nil,
                    blockBufferMemoryAllocator: nil,
                    flags: 0,
                    blockBufferOut: nil)

                CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer,
                                                                        bufferListSizeNeededOut: nil,
                                                                        bufferListOut: &audioBufferList,
                                                                        bufferListSize: bufferSize,
                                                                        blockBufferAllocator: nil,
                                                                        blockBufferMemoryAllocator: nil,
                                                                        flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                        blockBufferOut: &buffer)

                let abl = UnsafeMutableAudioBufferListPointer(&audioBufferList)
                var maxAmplitude: Int16 = 0

                for buffer in abl {
                    guard let data: UnsafeMutableRawPointer = buffer.mData else {
                        continue
                    }

                    let i16bufptr = UnsafeBufferPointer(start: data.assumingMemoryBound(to: Int16.self), count: Int(buffer.mDataByteSize) / Int(MemoryLayout<Int16>.size))

                    for sample in Array(i16bufptr) {
                        sampleSkipCounter += 1
                        maxAmplitude = max(maxAmplitude, sample)

                        if sampleSkipCounter == stride {
                            sampleData.append(Float(scalar(maxAmplitude)))
                            sampleSkipCounter = 0
                            maxAmplitude = 0
                        }
                    }
                }
                CMSampleBufferInvalidate(sampleBuffer)
            }
        }

        return sampleData
    }
}
