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

import GenericMessageProtocol
import WireFoundation

public struct MultipartAttachment {

    public enum Metadata {

        /// Image metadata, containing width and height in pixels.

        case image(width: Int, height: Int)

        /// Video metadata, containing width and height in pixels, and duration in milliseconds.

        case video(width: Int?, height: Int?, duration: Int?)

        /// Audio metadata, containing duration in milliseconds and normalized loudness data.
        ///
        /// - note: Currently, normalized loudness is not sent.

        case audio(duration: Int?, normalizedLoudness: Data?)

    }

    /// The wire cells UUID of the attachment.

    public let uuid: UUID

    /// The mime type of the attachment.

    public let contentType: String

    /// The full name of the attachment, including cell prefix. E.g. "<conversation-qualified-id>/<file-name>"
    ///
    /// - note: This is the initial value when the document was first sent and may no longer be accurate.

    public let initialName: String?

    /// The initial size of the attachment, in bytes.
    ///
    /// - note: This is the initial value when the document was first sent and may no longer be accurate.

    public let initialSize: Int?

    /// The initial metadata of the attachment, if relevant.
    ///
    /// - note: This is the initial value when the document was first sent and may no longer be accurate.

    public let initialMetadata: Metadata?

    public init(
        uuid: UUID,
        contentType: String?,
        initialName: String?,
        initialSize: Int?,
        initialMetadata: Metadata?
    ) {
        self.uuid = uuid
        self.contentType = contentType ?? "application/octet-stream"
        self.initialName = initialName
        self.initialSize = initialSize
        self.initialMetadata = initialMetadata
    }

}

extension MultipartAttachment {

    func toProto() -> Attachment {
        Attachment.with { attachment in
            attachment.cellAsset = CellAsset.with { asset in
                asset.uuid = uuid.transportString()
                asset.contentType = contentType

                // Only set if values are not nil to avoid protobufs setting nonsense defaults.
                initialName.map { asset.initialName = $0 }
                initialSize.map { asset.initialSize = Int64($0) }

                switch initialMetadata {
                case let .image(width, height):
                    asset.initialMetaData = .image(
                        CellAsset.ImageMetaData.with { metadata in
                            // Only set if values are not nil to avoid protobufs setting nonsense defaults.
                            metadata.width = Int32(width)
                            metadata.height = Int32(height)
                        }
                    )
                case let .video(width, height, duration):
                    asset.initialMetaData = .video(
                        CellAsset.VideoMetaData.with { metadata in
                            // Only set if values are not nil to avoid protobufs setting nonsense defaults.
                            width.map { metadata.width = Int32($0) }
                            height.map { metadata.height = Int32($0) }
                            duration.map { metadata.durationInMillis = UInt64($0) }
                        }
                    )
                case let .audio(duration, normalizedLoudness):
                    asset.initialMetaData = .audio(
                        CellAsset.AudioMetaData.with { metadata in
                            // Only set if values are not nil to avoid protobufs setting nonsense defaults.
                            duration.map { metadata.durationInMillis = UInt64($0) }
                            normalizedLoudness.map { metadata.normalizedLoudness = $0 }
                        }
                    )
                case .none:
                    break
                }
            }
        }
    }

}
