//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

/// Represents an animated image provided by Giphy.

public struct ZiphyAnimatedImage: Codable {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(url: URL, width: ZiphyInt, height: ZiphyInt, fileSize: ZiphyInt) {
        self.url = url
        self.width = width
        self.height = height
        self.fileSize = fileSize
    }

    // MARK: Public

    // MARK: - Codable

    public enum CodingKeys: String, CodingKey {
        case url
        case width
        case height
        case fileSize = "size"
    }

    public let url: URL
    public let width: ZiphyInt
    public let height: ZiphyInt
    public let fileSize: ZiphyInt

    public var description: String {
        let values = [
            "url = \(url.absoluteString)",
            "width = \(width)",
            "height = \(height)",
            "fileSize = \(fileSize)",
        ]

        return "<< " + values.joined(separator: ", ") + ">>"
    }
}
