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

import WireDataModel
import WireLegacyLogging
import WireNetwork

struct UserClientRemoveEventProcessor: UserClientRemoveEventProcessorProtocol {
    let userClientsRepository: any UserClientsRepositoryProtocol
    let calculateSupportedProtocolsUseCase: any CalculateSupportedProtocolsUseCaseProtocol
    let pushSupportedProtocolsUseCase: any PushSupportedProtocolsUseCaseProtocol
    let oneOnOneResolver: any OneOnOneResolverProtocol
    let context: NSManagedObjectContext
    let onSelfClientInvalidated: () async -> Void // Defined at the app level in `ZMUserSession`

    func processEvent(_ event: UserClientRemoveEvent) async throws {
        let clientID = event.clientID

        let isSelfClient = await context.perform { [context] in
            let selfClient = ZMUser.selfUser(in: context).selfClient()
            return selfClient?.remoteIdentifier == clientID
        }

        if isSelfClient == true {
            await userClientsRepository.invalidateSelfClient()
            await onSelfClientInvalidated()
        } else {
            await userClientsRepository.deleteClient(id: clientID)
            try await resolveOneOnOneConversations()
        }

    }

    private func resolveOneOnOneConversations() async throws {
        let oldProtocols = await context.perform {
            let selfUser = ZMUser.selfUser(in: context)
            return selfUser.supportedProtocols
        }

        let newProtocols = await calculateSupportedProtocols().toDomainModel()

        if oldProtocols != newProtocols {
            try await pushSupportedProtocolsUseCase.invoke()

            await context.perform {
                let selfUser = ZMUser.selfUser(in: context)
                selfUser.supportedProtocols = newProtocols
            }
        }

        if newProtocols.contains(.mls) {
            try await oneOnOneResolver.resolveAllOneOnOneConversations()
        }
    }

    private func calculateSupportedProtocols() async -> Set<WireNetwork.MessageProtocol> {
        do {
            // we need the self clients to be up to date before calculating supported protocols.
            try await userClientsRepository.pullSelfClients()
        } catch {
            WireLogger.userClient.error(
                "error syncing selfclients: \(error.localizedDescription)"
            )
        }

        return await calculateSupportedProtocolsUseCase.invoke()
    }

}
