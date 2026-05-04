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

import WireTransport

public class BackendMetadataProvider {

    // Set these values when multibackend is on with the metadata
    // resolved during session loading. If no values are set, then
    // the fallback legacy values from BackendInfo will be used.
    private let apiVersionOverride: WireTransport.APIVersion?
    private let domainOverride: String?
    private let isFederationEnabledOverride: Bool?
    private let isBackendMLSEnabledOverride: Bool?

    public init(
        apiVersionOverride: WireTransport.APIVersion?,
        domainOverride: String?,
        isFederationEnabledOverride: Bool?,
        isBackendMLSEnabledOverride: Bool?
    ) {
        self.apiVersionOverride = apiVersionOverride
        self.domainOverride = domainOverride
        self.isFederationEnabledOverride = isFederationEnabledOverride
        self.isBackendMLSEnabledOverride = isBackendMLSEnabledOverride
    }

    public var apiVersion: WireTransport.APIVersion? {
        if let apiVersion = apiVersionOverride {
            .init(rawValue: Int32(apiVersion.rawValue))
        } else {
            BackendInfo.apiVersion
        }
    }

    public var domain: String? {
        if let domain = domainOverride {
            domain
        } else {
            BackendInfo.domain
        }
    }

    public var isFederationEnabled: Bool {
        if let isFederationEnabled = isFederationEnabledOverride {
            isFederationEnabled
        } else {
            BackendInfo.isFederationEnabled
        }
    }

    public var isMLSEnabled: Bool {
        if let isBackendMLSEnabled = isBackendMLSEnabledOverride {
            isBackendMLSEnabled
        } else {
            BackendInfo.isMLSEnabled
        }
    }

}
