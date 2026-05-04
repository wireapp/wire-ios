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
import WireNetwork

struct PullSelfTeamRolesSync: PullSelfTeamRolesSyncProtocol {

    private let api: any TeamsAPI
    private let store: any TeamLocalStoreProtocol

    init(
        api: any TeamsAPI,
        store: any TeamLocalStoreProtocol
    ) {
        self.api = api
        self.store = store
    }

    func pull(selfTeamID: UUID) async throws {
        let remoteTeamRoles = try await api.getTeamRoles(for: selfTeamID)

        let teamRolesInfo = remoteTeamRoles.map {
            $0.toDomainModel()
        }

        try await store.storeTeamRoles(
            selfTeamID: selfTeamID,
            teamRolesInfo: teamRolesInfo
        )
    }

}
