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

// MARK: - ZiphyImageType

/// The types of image provided by the Giphy API.

public enum ZiphyImageType: String, CodingKey {
    case fixedHeight = "fixed_height"
    case fixedHeightDownsampled = "fixed_height_downsampled"
    case fixedHeightSmall = "fixed_height_small"
    case fixedWidth = "fixed_width"
    case fixedWidthDownsampled = "fixed_width_downsampled"
    case fixedWidthSmall = "fixed_width_small"
    case downsized
    case downsizedLarge = "downsized_large"
    case downsizedMedium = "downsized_medium"
    case downsizedSmall = "downsized_small"
    case original
    case preview = "preview_gif"
}

extension ZiphyImageType {
    static var previewFallbackList: [ZiphyImageType] {
        [.fixedWidthDownsampled, .fixedWidth, .downsized, .original]
    }
}
