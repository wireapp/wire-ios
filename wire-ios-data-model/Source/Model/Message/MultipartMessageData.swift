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

import Foundation
import GenericMessageProtocol

// TODO: [WPB-16311] This is currently just a stub and needs to be implemented properly.
public final class MultipartMessageData: NSObject {

    public enum Metadata: Equatable {

        /// Image metadata, containing width and height in pixels.
        case image(width: Int?, height: Int?)

        /// Video metadata, containing width and height in pixels, and duration in milliseconds.
        case video(width: Int?, height: Int?, duration: Int?)

        /// Audio metadata, containing duration in milliseconds and normalized loudness data.
        ///
        /// - note: Currently, normalized loudness is not sent.
        case audio(duration: Int?, normalizedLoudness: Data?)

    }

    public struct Attachment: Equatable {
        public let nodeID: UUID
        public let contentType: String?
        public let initialName: String?
        public let initialSize: Int?
        public let initialMetadata: Metadata?
    }

    public let attachments: [Attachment]

    init(multipart: Multipart) {
        self.attachments = multipart.attachments.compactMap { attachment in
            let asset = attachment.cellAsset

            guard let nodeID = UUID(uuidString: asset.uuid) else { return nil }

            return Attachment(
                nodeID: nodeID,
                contentType: asset.hasContentType ? asset.contentType : nil,
                initialName: asset.hasInitialName ? URL(string: asset.initialName)?.lastPathComponent : nil,
                initialSize: asset.hasInitialSize ? Int(attachment.cellAsset.initialSize) : nil,
                initialMetadata: asset.initialMetaData?.metadata
            )
        }
    }

}

private extension CellAsset.OneOf_InitialMetaData {

    var metadata: MultipartMessageData.Metadata {
        switch self {
        case let .image(image):
            .image(
                width: image.hasWidth ? Int(image.width) : nil,
                height: image.hasHeight ? Int(image.height) : nil
            )
        case let .video(video):
            .video(
                width: video.hasWidth ? Int(video.width) : nil,
                height: video.hasHeight ? Int(video.height) : nil,
                duration: video.hasDurationInMillis ? Int(video.durationInMillis) : nil
            )
        case let .audio(audio):
            .audio(
                duration: audio.hasDurationInMillis ? Int(audio.durationInMillis) : nil,
                normalizedLoudness: audio.hasNormalizedLoudness ? audio.normalizedLoudness : nil
            )
        }
    }

}
