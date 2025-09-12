//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
package import Foundation
import ImageIO
package import WireMessagingDomain

package struct WireCellsDraftMetadataRepository: WireCellsDraftMetadataRepositoryProtocol {

    package init() {}

    package func imageMetadata(fileURL: URL) async throws -> WireCellsDraft.Metadata? {
        guard
            let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? Int,
            let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }

        return .image(width: width, height: height)
    }

    package func videoMetadata(fileURL: URL) async throws -> WireCellsDraft.Metadata? {
        let asset = AVAsset(url: fileURL)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else { return nil }

        let dimensions = try await track.load(.naturalSize)
        let milliseconds = try await asset.load(.duration).seconds * 1000

        return .video(width: Int(dimensions.width), height: Int(dimensions.height), duration: Int(milliseconds))
    }

    package func audioMetadata(fileURL: URL) async throws -> WireCellsDraft.Metadata? {
        let asset = AVAsset(url: fileURL)
        let milliseconds = try await asset.load(.duration).seconds * 1000

        return .audio(duration: Int(milliseconds))
    }

}
