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
import WireMessagingDomain

extension WireDriveLocalAsset {

    /// Builds a key that acts as an identifier for the particular version of the downloaded file.
    /// This cache key is also used to build the URL which points to the downloaded file.
    /// The file name of the URL path will be shown as the title in the QuickLook preview when the file os opened,
    /// so it's important to make it readable and correspond to the actual file name, rather than a generated id.
    static func cacheKey(nodeID: UUID, eTag: String, path: String) -> String {
        let filename = path.split(separator: "/").last.flatMap(String.init) ?? "-"
        return "\(nodeID.uuidString)-\(eTag)/\(filename)"
    }

}
