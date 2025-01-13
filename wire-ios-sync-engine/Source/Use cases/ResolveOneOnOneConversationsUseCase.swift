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
import WireDomain
import WireLogging

// sourcery: AutoMockable
public protocol ResolveOneOnOneConversationsUseCaseProtocol {

    func invoke() async throws

}

typealias PullSelfUserClientsFactory = (NSManagedObjectContext) -> PullSelfUserClientsProtocol

struct ResolveOneOnOneConversationsUseCase: ResolveOneOnOneConversationsUseCaseProtocol {

    let context: NSManagedObjectContext
    let supportedProtocolService: any SupportedProtocolsServiceInterface
    let resolver: any OneOnOneResolverInterface
    let pullSelfUserClientsFactory: PullSelfUserClientsFactory
    
    func invoke() async throws {
        let oldProtocols = await context.perform {
            let selfUser = ZMUser.selfUser(in: context)
            return selfUser.supportedProtocols
        }
        
        let newProtocols = await calculateSupportedProtocols()
        if oldProtocols != newProtocols {
            var action = PushSupportedProtocolsAction(supportedProtocols: newProtocols)
            try await action.perform(in: context.notificationContext)
            
            await context.perform {
                let selfUser = ZMUser.selfUser(in: context)
                selfUser.supportedProtocols = newProtocols
            }
        }
        
        if newProtocols.contains(.mls) {
            try await resolver.resolveAllOneOnOneConversations(in: context)
        }
    }
    
    private func calculateSupportedProtocols() async -> Set<WireDataModel.MessageProtocol> {
        // we need the self clients to be up to date before calculating supported protocols
        let pullSelfUserClients = pullSelfUserClientsFactory(context)
        do {
            try await pullSelfUserClients.pullSelfClients()
        } catch {
            WireLogger.userClient.error("error syncing selfclients: \(error.localizedDescription)")
        }
        return await context.perform { supportedProtocolService.calculateSupportedProtocols() }
    }
}
