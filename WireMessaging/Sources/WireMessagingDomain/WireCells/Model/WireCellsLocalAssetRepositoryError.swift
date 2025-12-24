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

/// An error specific to the `WireCellsLocalAssetRepository`

public enum WireCellsLocalAssetRepositoryError: Error, Equatable {

    /// The wire cells node contains no download URL for the asset.

    case missingDownloadURL

    /// The wire cells node contains no eTag for the asset.

    case missingETag

    /// The requested asset is unknown to the repository.

    case unknownAsset

    /// The asset has changed on the server compared to the in progress / downloaded asset.

    case assetHasChanged

}
