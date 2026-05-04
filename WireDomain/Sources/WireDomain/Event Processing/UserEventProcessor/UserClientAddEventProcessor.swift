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

import WireNetwork

struct UserClientAddEventProcessor: UserClientAddEventProcessorProtocol {

    enum Error: Swift.Error {
        case failedToUpdateUserClient(Swift.Error)
    }

    let repository: any UserClientsRepositoryProtocol

    func processEvent(_ event: UserClientAddEvent) async {
        let localUserClient = await repository.fetchOrCreateClient(
            id: event.client.id
        )

        await repository.updateClient(
            id: event.client.id,
            from: event.client,
            isNewClient: localUserClient.isNew
        )
    }

}
