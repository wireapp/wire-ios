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

public struct WireDriveLocalAssetMetadata: Equatable, Sendable {

    public let nodeID: UUID
    public var eTag: String
    public var path: String
    public var contentType: String?
    public var size: UInt64?
    public var isDownloaded: Bool

    public init(
        nodeID: UUID,
        eTag: String,
        path: String,
        contentType: String?,
        size: UInt64?,
        isDownloaded: Bool
    ) {
        self.nodeID = nodeID
        self.eTag = eTag
        self.path = path
        self.contentType = contentType
        self.size = size
        self.isDownloaded = isDownloaded
    }

}
