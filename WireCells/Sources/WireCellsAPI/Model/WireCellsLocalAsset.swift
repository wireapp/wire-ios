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

public import Foundation

public struct WireCellsLocalAsset: Equatable {

    public enum DownloadState: Equatable, Sendable {
        case pending
        case downloading(progress: Double)
        case downloaded(cacheKey: String)
        case failed(error: any Error)

        public static func == (lhs: DownloadState, rhs: DownloadState) -> Bool {
            switch (lhs, rhs) {
            case (.pending, .pending):
                true
            case let (.downloading(lhs), .downloading(rhs)):
                lhs == rhs
            case let (.downloaded(lhs), .downloaded(rhs)):
                lhs == rhs
            case (.failed, .failed):
                true
            default:
                false
            }
        }
    }

    public let nodeID: UUID
    public let eTag: String
    public let path: String
    public let contentType: String?
    public let size: Int64?
    public let downloadState: DownloadState

    public init(
        nodeID: UUID,
        eTag: String,
        path: String,
        contentType: String?,
        size: Int64?,
        downloadState: DownloadState
    ) {
        self.nodeID = nodeID
        self.eTag = eTag
        self.path = path
        self.contentType = contentType
        self.size = size
        self.downloadState = downloadState
    }
}
