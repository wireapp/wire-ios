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
import WireLogging
import WireNetwork

struct PullLastUpdateEventIDSync: PullLastUpdateEventIDSyncProtocol {

    private let selfClientID: String?
    private let api: any UpdateEventsAPI
    private let store: any UpdateEventsLocalStoreProtocol

    init(
        selfClientID: String?,
        api: any UpdateEventsAPI,
        store: any UpdateEventsLocalStoreProtocol
    ) {
        self.selfClientID = selfClientID
        self.api = api
        self.store = store
    }

    func pull() async throws {
        do {
            let lastEvent = try await api.getLastUpdateEvent(
                selfClientID: selfClientID
            )

            let id = lastEvent.id

            WireLogger.sync.debug(
                "storing last event id",
                attributes: [.eventEnvelopeID: id]
            )

            store.storeLastEventID(id: id)

        } catch UpdateEventsAPIError.notFound {
            WireLogger.sync.warn("no last event found", attributes: .safePublic)
        }
    }

}
