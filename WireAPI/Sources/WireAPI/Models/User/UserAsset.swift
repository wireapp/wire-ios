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

/// Describes the size of the user asset.

public enum UserAssetSize: String, Codable, Equatable, Sendable {

    /// Smaller version of the asset optimised for size

    case preview

    /// Complete version of the asset

    case complete
}

/// Describes the purpose of the user asset.

public enum UserAssetType: String, Codable, Equatable, Sendable {

    /// User profile image

    case image
}

/// An asset associated with a user, typically a profile picture.

public struct UserAsset: Codable, Equatable, Sendable {

    /// Unique key for this asset, if the asset is updated it will be assigned new key.

    public let key: String

    /// Asset size

    public let size: UserAssetSize

    /// Asset type

    public let type: UserAssetType
}
