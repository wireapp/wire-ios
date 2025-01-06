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

protocol PullSelfUserSyncProtocol {

    func pull() async throws

}

/// An object to keep the local self user up to date
/// with the remote self user.

struct PullSelfUserSync: PullSelfUserSyncProtocol {

    private let api: any SelfUserAPI
    private let store: any UserLocalStoreProtocol

    init(
        api: any SelfUserAPI,
        store: any UserLocalStoreProtocol
    ) {
        self.api = api
        self.store = store
    }

    /// Fetch the self user from remote, then create or update
    /// it locally.

    func pull() async throws {
        let remoteSelfUser = try await api.getSelfUser()

        await store.persistUser(
            userInfo: remoteSelfUser.toDomainModel()
        )
    }

}
