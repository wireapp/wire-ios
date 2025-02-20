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

import Foundation
import WireAPI
import WireDataModel
import WireLogging

public struct PullMLSStatusSync: PullMLSStatusSyncProtocol {

    private let api: any BackendInfoAPI
    private let store: any BackendConfigLocalStoreProtocol

    public init(
        api: any BackendInfoAPI,
        store: any BackendConfigLocalStoreProtocol
    ) {
        self.api = api
        self.store = store
    }

    public func pull() async throws {
        do {
            let keys = try await api.getBackendMLSPublicKeys()
            let hasValidKeys = keys.removal.hasValidKey()
            store.storeIsMLSEnabledStatus(newValue: hasValidKeys)
        } catch let error as BackendInfoAPIError {
            switch error {
            case .unsupportedEndpointForAPIVersion, .mlsNotEnabled:
                WireLogger.mls.info("backend has no MLS public keys")
                store.storeIsMLSEnabledStatus(newValue: false)
            }
        }
    }

}
