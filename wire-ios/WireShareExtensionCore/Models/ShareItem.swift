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

/// Type of content being shared
public enum ShareItemType: Hashable {
    case image
    case video
    case file
}

/// Represents an item being shared through the share extension
public struct ShareItem: Identifiable, Hashable {

    public let id = UUID()
    public let type: ShareItemType
    public let url: URL
    public let name: String
    public let mimeType: String
    public let size: Int?

    public init(
        type: ShareItemType,
        url: URL,
        name: String,
        mimeType: String,
        size: Int?
    ) {
        self.type = type
        self.url = url
        self.name = name
        self.mimeType = mimeType
        self.size = size
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: ShareItem, rhs: ShareItem) -> Bool {
        lhs.id == rhs.id
    }
}
