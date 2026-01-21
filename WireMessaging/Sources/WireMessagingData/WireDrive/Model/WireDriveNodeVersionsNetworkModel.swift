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

import CellsSDK
import WireMessagingDomain
package import Foundation

package struct WireDriveNodeVersionsNetworkModel: Equatable, Hashable, Sendable {
    package let versions: [Version]

    package struct Version: Equatable, Hashable, Sendable {
        package let contentUrl: URL?
        package let contentHash: String?
        package let description: String?
        package let isDraft: Bool
        package let eTag: String?
        package let isHead: Bool?
        package let mTime: UInt64?
        package let ownerName: String?
        package let ownerUuid: String?
        package let size: UInt64?
        package let versionId: UUID
        package let downloadUrl: URL?
    }
}

extension WireDriveNodeVersionsNetworkModel {
    func toDomainModel() -> [WireDriveNodeVersion] {
        versions.map {
            WireDriveNodeVersion(
                id: $0.versionId,
                ownerName: $0.ownerName,
                modified: $0.mTime.map { Date(timeIntervalSince1970: Double($0)) },
                eTag: $0.eTag,
                size: $0.size,
                downloadUrl: $0.downloadUrl
            )
        }
    }
}

package extension RestVersionCollection {
    func toDTO() -> WireDriveNodeVersionsNetworkModel? {
        guard let versions else { return nil }

        let dtoVersions = versions.compactMap { value -> WireDriveNodeVersionsNetworkModel.Version? in
            guard let id = UUID(uuidString: value.versionId) else { return nil }

            return WireDriveNodeVersionsNetworkModel.Version(
                contentUrl: value.preSignedGET?.url.flatMap(URL.init(string:)),
                contentHash: value.contentHash,
                description: value.description,
                isDraft: value.draft ?? false,
                eTag: value.eTag,
                isHead: value.isHead,
                mTime: value.mTime.flatMap(UInt64.init),
                ownerName: value.ownerName,
                ownerUuid: value.ownerUuid,
                size: value.size.flatMap(UInt64.init),
                versionId: id,
                downloadUrl: value.preSignedGET?.url.flatMap(URL.init(string:))
            )
        }

        return WireDriveNodeVersionsNetworkModel(
            versions: dtoVersions
        )
    }
}
