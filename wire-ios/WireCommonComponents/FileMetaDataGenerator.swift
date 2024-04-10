//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

import Foundation
import MobileCoreServices
import WireDataModel
import AVFoundation

private let zmLog = ZMSLog(tag: "UI")

public final class FileMetaDataGenerator: NSObject {

    static public func metadataForFileAtURL(_ url: URL, UTI uti: String, name: String, completion: @escaping (ZMFileMetadata) -> Void) {
        SharedPreviewGenerator.generator.generatePreview(url, UTI: uti) { (preview) in
            let thumbnail = preview != nil ? preview!.jpegData(compressionQuality: 0.9) : nil

            if AVURLAsset.wr_isAudioVisualUTI(uti) {
                let asset = AVURLAsset(url: url)

                if let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first {
                    completion(ZMVideoMetadata(fileURL: url, duration: asset.duration.seconds, dimensions: videoTrack.naturalSize, thumbnail: thumbnail))
                } else {
                    let loudness = asset.audioSamplesFromAsset(maxSamples: 100)

                    completion(ZMAudioMetadata(fileURL: url, duration: asset.duration.seconds, normalizedLoudness: loudness ?? []))
                }
            } else {
                // swiftlint:disable todo_requires_jira_link
                // TODO: set the name of the file (currently there's no API, it always gets it from the URL)
                // swiftlint:enable todo_requires_jira_link
                completion(ZMFileMetadata(fileURL: url, thumbnail: thumbnail))
            }
        }
    }

}

extension AVURLAsset {
    static func wr_isAudioVisualUTI(_ UTI: String) -> Bool {
        return audiovisualTypes().contains(where: { compatibleUTI -> Bool in
            UTTypeConformsTo(UTI as CFString, compatibleUTI as CFString)
        })
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
        } catch let error {
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
