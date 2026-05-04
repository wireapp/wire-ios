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

import CoreData
import Foundation

/// Information of a Wire Cells local asset (e.g file) including whether it is downloaded.
///
/// Its download location is determined by its `nodeID` and `eTag` properties.

public final class WireCellsLocalAsset: NSManagedObject {

    /// The name of the associated Core Data entity.

    public static let entityName = "WireCellsLocalAsset"

    /// The identifier of the asset on the Wire Cells backend.

    @NSManaged public var nodeID: UUID

    /// The eTag of the asset. An eTag is a unique identifier for a specific version of a resource.
    ///
    /// If this changes the file represented by `nodeID` has changed and should be re-downloaded.

    @NSManaged public var eTag: String

    /// The remote key path representing the asset in the Wire Cells file system.
    ///
    /// This is **not** the path on the local file system. It encodes information such as file name and extension.

    @NSManaged public var path: String

    /// The content type of the asset as defined by the backend.
    ///
    /// This is a MIME type (e.g. "image/png", "application/pdf").

    @NSManaged public var contentType: String?

    /// The size of the asset in bytes as defined by the backend or `-1` if unknown.

    @NSManaged public var size: Int64

    /// Whether the asset is downloaded or not.

    @NSManaged public var isDownloaded: Bool

}
