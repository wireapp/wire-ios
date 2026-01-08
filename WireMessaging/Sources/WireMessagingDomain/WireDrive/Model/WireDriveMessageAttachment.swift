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

public import Foundation

/// Data for a single attachment sent with a message
public struct WireDriveMessageAttachment: Hashable, Sendable {

    public enum Metadata: Hashable, Sendable {

        /// Image metadata, containing width and height in pixels.
        case image(width: Int?, height: Int?)

        /// Video metadata, containing width and height in pixels, and duration in milliseconds.
        case video(width: Int?, height: Int?, duration: Int?)

        /// Audio metadata, containing duration in milliseconds and normalized loudness data.
        ///
        /// - note: Currently, normalized loudness is not sent.
        case audio(duration: Int?, normalizedLoudness: Data?)

        package var dimension: CGSize? {
            switch self {
            case let .image(width, height), let .video(width, height, _):
                guard let width, let height else { return nil }

                return CGSize(width: Double(width), height: Double(height))
            default:
                return nil
            }
        }

        package var duration: Int? {
            switch self {
            case let .video(_, _, duration), let .audio(duration, _):
                duration
            default:
                nil
            }
        }

        package var normalizedLoudness: Data? {
            switch self {
            case let .audio(_, normalizedLoudness):
                normalizedLoudness
            default:
                nil
            }
        }

    }

    /// The `nodeID` of the attachment.
    public let nodeID: UUID

    /// The mime type of the attachment.
    public let contentType: String?

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
        nodeID: UUID,
        contentType: String?,
        initialName: String?,
        initialSize: Int?,
        initialMetadata: Metadata?
    ) {
        self.nodeID = nodeID
        self.contentType = contentType
        self.initialName = initialName
        self.initialSize = initialSize
        self.initialMetadata = initialMetadata
    }

}
