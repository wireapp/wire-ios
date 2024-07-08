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

import WireTransport

/// For testing: helps to temporary set the backend info domain and reset on dealloc.
public final class TemporaryBackendInfoToken {

    private let originalStorage: UserDefaults

    public var apiVersion: APIVersion? {
        get { BackendInfo.apiVersion }
        set { BackendInfo.apiVersion = newValue }
    }

    public var domain: String? {
        get { BackendInfo.domain }
        set { BackendInfo.domain = newValue }
    }

    public var isFederationEnabled: Bool {
        get { BackendInfo.isFederationEnabled }
        set { BackendInfo.isFederationEnabled = newValue }
    }

    public var preferredAPIVersion: APIVersion? {
        get { BackendInfo.preferredAPIVersion }
        set { BackendInfo.preferredAPIVersion = newValue }
    }

    public init(
        apiVersion: APIVersion? = nil,
        domain: String? = nil,
        isFederationEnabled: Bool = false,
        preferredAPIVersion: APIVersion? = nil
    ) {
        originalStorage = BackendInfo.storage

        // initialized

        BackendInfo.storage = .temporary()

        self.apiVersion = apiVersion
        self.domain = domain
        self.isFederationEnabled = isFederationEnabled
        self.preferredAPIVersion = preferredAPIVersion
    }

    deinit {
        BackendInfo.storage = originalStorage
    }
}
