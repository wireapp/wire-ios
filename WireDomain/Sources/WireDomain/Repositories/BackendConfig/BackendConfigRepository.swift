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
import WireLogging

final class BackendConfigRepository: BackendConfigRepositoryProtocol {

    // MARK: - Properties

    private let backendInfoAPI: any BackendInfoAPI
    private let backendConfigLocalStore: any BackendConfigLocalStoreProtocol
    private let logger = WireLogger.mls

    // MARK: - Object lifecycle

    init(
        backendInfoAPI: any BackendInfoAPI,
        backendConfigLocalStore: any BackendConfigLocalStoreProtocol
    ) {
        self.backendInfoAPI = backendInfoAPI
        self.backendConfigLocalStore = backendConfigLocalStore
    }

    // MARK: - Public

    func pullMLSBackendStatus() async {
        do {
            let backendMLSPublicKeys = try await backendInfoAPI.getBackendMLSPublicKeys()
            let hasValidKeys = backendMLSPublicKeys.removal.hasValidKey()
            backendConfigLocalStore.storeIsMLSEnabledStatus(newValue: hasValidKeys)
        } catch {
            backendConfigLocalStore.storeIsMLSEnabledStatus(newValue: false)
            logger.info("no backend MLS public keys")
        }
    }

}
