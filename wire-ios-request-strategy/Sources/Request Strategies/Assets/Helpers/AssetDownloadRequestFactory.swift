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
import WireTransport

public final class AssetDownloadRequestFactory {

    private let localDomain: String?

    init(localDomain: String?) {
        self.localDomain = localDomain
    }

    public func requestToGetAsset(
        withKey key: String,
        token: String?,
        domain: String?,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        let domain = if let domain, !domain.isEmpty { domain } else { localDomain }
        let path: String
        switch apiVersion {
        case .v0:
            path = "/assets/v3/\(key)"
        case .v1:
            guard let domain else { return nil }
            path = "/assets/v4/\(domain)/\(key)"
        case .v2, .v3, .v4, .v5, .v6, .v7, .v8, .v9, .v10, .v11, .v12, .v13, .v14:
            guard let domain else { return nil }
            path = "/assets/\(domain)/\(key)"
        }

        let request = ZMTransportRequest.assetGet(fromPath: path, assetToken: token, apiVersion: apiVersion.rawValue)
        request?.forceToBackgroundSession()
        return request
    }
}
