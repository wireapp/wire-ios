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

struct PullSelfLegalholdInfoSync: PullSelfLegalholdInfoSyncProtocol {

    private let selfUserID: UUID
    private let api: any TeamsAPI
    private let store: any UserLocalStoreProtocol

    init(
        selfUserID: UUID,
        api: any TeamsAPI,
        store: any UserLocalStoreProtocol
    ) {
        self.selfUserID = selfUserID
        self.api = api
        self.store = store
    }

    func pull(selfTeamID: UUID) async throws {
        let remoteLegalholdInfo = try await api.getLegalholdInfo(
            for: selfTeamID,
            userID: selfUserID
        )

        switch remoteLegalholdInfo.status {
        case .pending:
            guard let clientID = remoteLegalholdInfo.clientID else {
                throw PullSelfLegalholdInfoSyncError.missingClientID
            }

            guard let lastPrekey = remoteLegalholdInfo.prekey else {
                throw PullSelfLegalholdInfoSyncError.missingPrekey
            }

            guard let mappedPrekey = lastPrekey.toDomainModel() else {
                throw PullSelfLegalholdInfoSyncError.invalidPrekey
            }

            await store.addSelfLegalHoldRequest(
                userID: selfUserID,
                clientID: clientID,
                lastPrekey: mappedPrekey
            )

        case .disabled:
            await store.cancelSelfUserLegalholdRequest()

        default:
            break
        }
    }

}
