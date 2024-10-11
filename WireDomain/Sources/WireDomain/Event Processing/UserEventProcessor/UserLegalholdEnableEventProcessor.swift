//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireAPI

/// Process user legalhold enable events.

protocol UserLegalholdEnableEventProcessorProtocol {

    /// Process a user legalhold enable event.
    ///
    /// - Parameter event: A user legalhold enable event.

    func processEvent(_ event: UserLegalholdEnableEvent) async throws

}

struct UserLegalholdEnableEventProcessor: UserLegalholdEnableEventProcessorProtocol {

    let context: NSManagedObjectContext
    let userRepository: any UserRepositoryProtocol
    let clientRepository: any ClientRepositoryProtocol

    func processEvent(_ event: UserLegalholdEnableEvent) async throws {
        let userID = event.userID

        let selfUserID = await context.perform {
            let selfUser = userRepository.fetchSelfUser()
            return selfUser.remoteIdentifier
        }

        guard userID == selfUserID else {
            return
        }

        try await processSelfUserClients()
    }

    /// Fetches, creates and updates clients for self user and removes the deleted clients locally.

    private func processSelfUserClients() async throws {
        let remoteSelfClients = try await clientRepository.fetchSelfClients()
        let localSelfClients = await context.perform {
            let selfUser = userRepository.fetchSelfUser()
            return selfUser.clients
        }

        for remoteSelfClient in remoteSelfClients {
            let localUserClient = try await clientRepository.fetchOrCreateClient(
                with: remoteSelfClient.id
            )

            try await clientRepository.updateClient(
                with: remoteSelfClient.id,
                from: remoteSelfClient,
                isNewClient: localUserClient.isNew
            )
        }

        let deletedSelfClientsIDs = localSelfClients.compactMap(\.remoteIdentifier).filter { !remoteSelfClients.map(\.id).contains($0)
        }

        for deletedSelfClientID in deletedSelfClientsIDs {
            await clientRepository.deleteClient(with: deletedSelfClientID)
        }
    }
}
