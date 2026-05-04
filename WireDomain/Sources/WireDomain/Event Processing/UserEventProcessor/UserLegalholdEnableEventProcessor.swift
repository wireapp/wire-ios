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

import CoreData
import WireNetwork

struct UserLegalholdEnableEventProcessor: UserLegalholdEnableEventProcessorProtocol {

    let context: NSManagedObjectContext
    let userRepository: any UserRepositoryProtocol
    let userClientsRepository: any UserClientsRepositoryProtocol

    func processEvent(_ event: UserLegalholdEnableEvent) async throws {
        let userID = event.userID

        let selfUser = await userRepository.fetchSelfUser()

        let selfUserID = await context.perform {
            selfUser.remoteIdentifier
        }

        guard userID == selfUserID else {
            return
        }

        try await userClientsRepository.pullSelfClients()
    }

}
