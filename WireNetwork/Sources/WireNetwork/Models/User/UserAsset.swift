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

/// Describes the size of the user asset.

public enum UserAssetSize: Equatable, Sendable {

    /// Smaller version of the asset optimised for size

    case preview

    /// Complete version of the asset

    case complete
}

/// Describes the purpose of the user asset.

public enum UserAssetType: Equatable, Sendable {

    /// User profile image

    case image
}

/// An asset associated with a user, typically a profile picture.

public struct UserAsset: Equatable, Sendable {

    /// Unique key for this asset, if the asset is updated it will be assigned new key.

    public let key: String

    /// Asset size

    public let size: UserAssetSize

    /// Asset type

    public let type: UserAssetType

    public init(
        key: String,
        size: UserAssetSize,
        type: UserAssetType
    ) {
        self.key = key
        self.size = size
        self.type = type
    }
}

struct UserAssetV0: Equatable, Sendable, Decodable, ToAPIModelConvertible {

    let key: String
    let size: UserAssetSizeV0
    let type: UserAssetTypeV0

    func toAPIModel() -> UserAsset {
        UserAsset(key: key, size: size.toAPIModel(), type: type.toAPIModel())
    }
}

enum UserAssetSizeV0: String, Equatable, Sendable, Decodable, ToAPIModelConvertible {

    case preview
    case complete

    func toAPIModel() -> UserAssetSize {
        switch self {

        case .preview:
            .preview
        case .complete:
            .complete
        }
    }
}

enum UserAssetTypeV0: String, Equatable, Sendable, Decodable, ToAPIModelConvertible {

    case image

    func toAPIModel() -> UserAssetType {
        switch self {
        case .image:
            .image
        }
    }
}
