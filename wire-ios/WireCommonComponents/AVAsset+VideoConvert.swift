//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireLogging
import WireUtilities

// MARK: - audio convert

public extension AVAsset {
    static func convertAudioToUploadFormat(
        _ inPath: String,
        outPath: String,
        completion: ((_ success: Bool) -> Void)? = .none
    ) {
        let fileURL = URL(fileURLWithPath: inPath)
        let alteredAsset = AVAsset(url: fileURL)
        let session = AVAssetExportSession(asset: alteredAsset, presetName: AVAssetExportPresetAppleM4A)
        guard let exportSession = session else {
            WireLogger.ui.error("Failed to create export session with asset \(alteredAsset)")
            completion?(false)
            return
        }
        let encodedEffectAudioURL = URL(fileURLWithPath: outPath)
        exportSession.outputURL = encodedEffectAudioURL as URL
        exportSession.outputFileType = AVFileType.m4a
        exportSession.exportAsynchronously { [unowned exportSession] in
            switch exportSession.status {
            case .failed:
                WireLogger.ui
                    .error("Cannot transcode \(inPath) to \(outPath): \(String(describing: exportSession.error))")
                DispatchQueue.main.async {
                    completion?(false)
                }
            default:
                DispatchQueue.main.async {
                    completion?(true)
                }
            }
        }
    }
}

// MARK: - video convert

public typealias ConvertVideoCompletion = (URL?, AVURLAsset?, Error?) -> Void

public extension AVURLAsset {

    internal enum ConversionFailure: Error {

        case missingVideoTrack
        case exportSessionUnavailable

    }

    static let defaultVideoQuality = AVAssetExportPresetHighestQuality

    /// Convert a Video file URL to a upload format
    ///
    /// - Parameters:
    ///   - url: video file URL
    ///   - quality: video quality, default is AVAssetExportPresetHighestQuality
    ///   - deleteSourceFile: set to false for testing only
    ///   - completion: ConvertVideoCompletion closure. URL: exported file's URL. AVURLAsset: assert of converted video.
    /// Error: error of conversion
    static func convertVideoToUploadFormat(
        at url: URL,
        quality: String = AVURLAsset.defaultVideoQuality,
        deleteSourceFile: Bool = true,
        fileLengthLimit: Int64? = nil,
        completion: @escaping ConvertVideoCompletion
    ) {
        let filename = url.deletingPathExtension().lastPathComponent + ".mp4"
        let asset = AVURLAsset(url: url, options: nil)

        guard let track = AVAsset(url: url as URL).tracks(withMediaType: AVMediaType.video).first else {
            completion(nil, nil, ConversionFailure.missingVideoTrack)
            return
        }

        let size = track.naturalSize

        let cappedQuality: String = if size.width > 1920 || size.height > 1920 {
            AVAssetExportPreset1920x1080
        } else {
            quality
        }

        asset.convert(
            filename: filename,
            quality: cappedQuality,
            fileLengthLimit: fileLengthLimit
        ) { URL, asset, error in
            if deleteSourceFile {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch let deleteError {
                    WireLogger.ui.error("Cannot delete file: \(url) (\(deleteError))")
                }
            }

            completion(URL, asset, error)
        }
    }

    func convert(
        filename: String,
        quality: String = defaultVideoQuality,
        fileLengthLimit: Int64? = nil,
        completion: @escaping ConvertVideoCompletion
    ) {
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)

        // Export into a uniquely named intermediate file rather than directly to `outputURL`.
        // `outputURL`'s name is derived from the source asset's filename with the extension
        // swapped to `.mp4`, so when the source is already an `.mp4` it collides with the
        // source path itself. Deleting that "leftover" file out from under the export session
        // while it's still reading from it caused it to fail.
        let exportingURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(outputURL.pathExtension)

        guard let exportSession = AVAssetExportSession(asset: self, presetName: quality) else {
            return completion(nil, nil, ConversionFailure.exportSessionUnavailable)
        }

        if let fileLengthLimit {
            exportSession.fileLengthLimit = fileLengthLimit
        }

        exportSession.exportVideo(exportURL: exportingURL) { _, error in
            guard error == nil else {
                try? FileManager.default.removeItem(at: exportingURL)
                DispatchQueue.main.async {
                    completion(nil, self, error)
                }
                return
            }

            do {
                if FileManager.default.fileExists(atPath: outputURL.path) {
                    try FileManager.default.removeItem(at: outputURL)
                }
                try FileManager.default.moveItem(at: exportingURL, to: outputURL)
            } catch let moveError {
                WireLogger.ui.error("Cannot move converted video to \(outputURL): \(moveError)")
                DispatchQueue.main.async {
                    completion(nil, self, moveError)
                }
                return
            }

            DispatchQueue.main.async {
                completion(outputURL, self, nil)
            }
        }
    }
}

extension AVAssetExportSession {

    func exportVideo(
        exportURL: URL,
        completion: @escaping (URL?, Error?) -> Void
    ) {
        if FileManager.default.fileExists(atPath: exportURL.path) {
            do {
                try FileManager.default.removeItem(at: exportURL)
            } catch {
                WireLogger.ui.error("Cannot delete old leftover at \(exportURL): \(error)")
            }
        }
        outputURL = exportURL
        shouldOptimizeForNetworkUse = true
        outputFileType = .mp4
        metadata = []
        metadataItemFilter = AVMetadataItemFilter.forSharing()
        weak var session: AVAssetExportSession? = self
        exportAsynchronously {
            if let session,
               let error = session.error {
                WireLogger.ui
                    .error("Export session error: status=\(session.status.rawValue) error=\(error) output=\(exportURL)")
            }
            completion(exportURL, session?.error)
        }
    }
}
