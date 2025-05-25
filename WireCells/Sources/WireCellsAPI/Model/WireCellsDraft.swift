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

package import Foundation
package import UniformTypeIdentifiers

public struct WireCellsDraft: Hashable, Sendable {

    public let id: WireCellsNodeID
    package let assetURL: URL
    package let fileType: UTType?
    public var status: WireCellsUploadStatus
    package var name: String
    package let bytes: Int

    package init(
        id: WireCellsNodeID,
        assetURL: URL,
        fileType: UTType?,
        status: WireCellsUploadStatus,
        name: String,
        bytes: Int
    ) {
        self.id = id
        self.assetURL = assetURL
        self.fileType = fileType
        self.status = status
        self.name = name
        self.bytes = bytes
    }
}
