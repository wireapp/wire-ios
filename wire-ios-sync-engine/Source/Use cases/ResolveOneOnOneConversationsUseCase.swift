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

import Foundation

protocol ResolveOneOnOneConversationsUseCaseProtocol {

    func invoke() async throws

}

struct ResolveOneOnOneConversationsUseCase: ResolveOneOnOneConversationsUseCaseProtocol {

    let context: NSManagedObjectContext
    let supportedProtocolService: SupportedProtocolsServiceInterface
    let resolver: OneOnOneResolverInterface

    func invoke() async throws {
        var getFeatureConfigAction = GetFeatureConfigsAction()
        try await getFeatureConfigAction.perform(in: context.notificationContext)

        let supportedProtocols = await context.perform {
            supportedProtocolService.calculateSupportedProtocols()
        }
        let shouldPushSupportedProtocols = await context.perform {
            let selfUser = ZMUser.selfUser(in: context)
           return selfUser.supportedProtocols != supportedProtocols
        }

        if shouldPushSupportedProtocols {
            var action = PushSupportedProtocolsAction(supportedProtocols: supportedProtocols)
            try await action.perform(in: context.notificationContext)

            await context.perform {
                let selfUser = ZMUser.selfUser(in: context)
                selfUser.supportedProtocols = supportedProtocols
            }
        }

        if supportedProtocols.contains(.mls) {
            try await resolver.resolveAllOneOnOneConversations(in: context)
        }

    }
}
