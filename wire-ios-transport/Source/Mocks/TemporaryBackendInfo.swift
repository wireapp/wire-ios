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

import Foundation

#if DEBUG

/// For testing: helps to temporary set the backend info domain and reset after call.
public struct TemporaryBackendInfo {

    private let domain: String?
    private let isFederationEnabled: Bool

    public init(
        domain: String? = nil,
        isFederationEnabled: Bool = false
    ) {
        self.domain = domain
        self.isFederationEnabled = isFederationEnabled
    }

    public func callAsFunction(_ perform: () -> Void) {
        let originalStorage = BackendInfo.storage
        BackendInfo.storage = .temporary()

        BackendInfo.domain = domain
        BackendInfo.isFederationEnabled = isFederationEnabled

        perform()

        BackendInfo.storage = originalStorage
    }
}

#endif
