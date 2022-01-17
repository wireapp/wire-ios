// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

public final class AssetDownloadRequestFactory: NSObject, FederationAware {

    public var useFederationEndpoint: Bool = false

    public func requestToGetAsset(withKey key: String, token: String?, domain: String?) -> ZMTransportRequest? {

        let path: String
        if useFederationEndpoint {
            guard let domain = domain else { return nil }

            path = "/assets/v4/\(domain)/\(key)"
        } else {
            path = "/assets/v3/\(key)"
        }

        let request = ZMTransportRequest.assetGet(fromPath: path, assetToken: token)
        request?.forceToBackgroundSession()
        return request

    }

}
