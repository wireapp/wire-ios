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
import WireDataModel
import WireLegacyLogging
import WireNetwork

// sourcery: AutoMockable
protocol PullEventsUseCaseProtocol {
    func invoke() async throws -> AsyncStream<[UpdateEvent]>
}

struct PullEventsUseCase: PullEventsUseCaseProtocol {
    private let pendingEventsSync: any PullPendingUpdateEventsSyncProtocol
    private let logger = WireLogger.notifications

    enum Failure: Error {
        case unableToPullPendingEvents(Error)
    }

    init(
        pendingEventsSync: any PullPendingUpdateEventsSyncProtocol
    ) {
        self.pendingEventsSync = pendingEventsSync
    }

    func invoke() async throws -> AsyncStream<[UpdateEvent]> {
        logger.info(
            "Attempting to fetch pending events",
            attributes: .newNSE, .safePublic
        )

        do {
            return try await pendingEventsSync.pull()

        } catch {
            throw Failure.unableToPullPendingEvents(error)
        }

    }

}
