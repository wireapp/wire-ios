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

import WireDomain
import WireNetwork
import WireTransport

public class BackendMetadataProvider {

    let journal: Journal?
    let newBackendMetadata: WireNetwork.ResolvedBackendMetadata?

    init(
        journal: Journal?,
        newBackendMetadata: WireNetwork.ResolvedBackendMetadata?
    ) {
        self.journal = journal
        self.newBackendMetadata = newBackendMetadata
    }

    public var apiVersion: WireTransport.APIVersion? {
        if let apiVersion = newBackendMetadata?.apiVersion {
            .init(rawValue: Int32(apiVersion.rawValue))
        } else {
            BackendInfo.apiVersion
        }
    }

    public var domain: String? {
        if let domain = newBackendMetadata?.domain {
            domain
        } else {
            BackendInfo.domain
        }
    }

    public var isFederationEnabled: Bool {
        if let isFederationEnabled = newBackendMetadata?.isFederationEnabled {
            isFederationEnabled
        } else {
            BackendInfo.isFederationEnabled
        }
    }

    public var isMLSEnabled: Bool {
        if let isBackendMLSEnabled = journal?[.isBackendMLSEnabled] {
            isBackendMLSEnabled
        } else {
            BackendInfo.isMLSEnabled
        }
    }

}
