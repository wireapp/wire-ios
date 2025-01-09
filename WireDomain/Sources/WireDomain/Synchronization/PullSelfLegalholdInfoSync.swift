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

protocol PullSelfLegalholdInfoSyncProtocol {

    func pull(selfTeamID: UUID) async throws

}

/// An object to keep the local self legal hold info
/// up to date with the remote self legal hold info.

struct PullSelfLegalholdInfoSync: PullSelfLegalholdInfoSyncProtocol {

    private let selfUserID: UUID
    private let selfClientID: String
    private let api: any TeamsAPI
    private let store: any UserLocalStoreProtocol

    init(
        selfUserID: UUID,
        selfClientID: String,
        api: any TeamsAPI,
        store: any UserLocalStoreProtocol
    ) {
        self.selfUserID = selfUserID
        self.selfClientID = selfClientID
        self.api = api
        self.store = store
    }

    /// Fetch the self user from remote, then create or update
    /// it locally.
    ///
    /// - Parameters:
    ///   - selfTeamID: The id of the self user's team.

    func pull(selfTeamID: UUID) async throws {
        let remoteLegalholdInfo = try await api.getLegalholdInfo(
            for: selfTeamID,
            userID: selfUserID
        )

        switch remoteLegalholdInfo.status {
        case .pending:
            let lastPrekey = remoteLegalholdInfo.prekey
            guard let mappedPrekey = lastPrekey.toDomainModel() else {
                return WireLogger.eventProcessing.error(
                    "Invalid legal hold request payload: invalid base64 encoded key \(lastPrekey.base64EncodedKey)"
                )
            }

            await store.addSelfLegalHoldRequest(
                userID: selfUserID,
                clientID: selfClientID,
                lastPrekey: mappedPrekey
            )

        case .disabled:
            await store.cancelSelfUserLegalholdRequest()

        default:
            break
        }
    }

}
