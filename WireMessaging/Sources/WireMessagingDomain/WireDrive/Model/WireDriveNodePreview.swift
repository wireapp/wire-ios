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

/// Node preview data.
/// - Parameters:
///   - url: URL of the preview.
///   - dimension: Max preview thumbnail dimension.
///   - processing: Whether the preview is currently being processed.
public struct WireDriveNodePreview: Equatable, Hashable, Sendable {
    public let url: URL?
    public let dimension: Int
    public let processing: Bool

    package init(
        url: URL?,
        dimension: Int,
        processing: Bool
    ) {
        self.url = url
        self.dimension = dimension
        self.processing = processing
    }
}
