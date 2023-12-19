//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

/// Consumes self user client update events
///
/// Self user clients are clients belonging to the self user.

@objcMembers
public class UserClientEventConsumer: NSObject, ZMEventAsyncConsumer {

    let managedObjectContext: NSManagedObjectContext
    let clientRegistrationStatus: ZMClientRegistrationStatus
    let clientUpdateStatus: ClientUpdateStatus

    public init (managedObjectContext: NSManagedObjectContext,
                 clientRegistrationStatus: ZMClientRegistrationStatus,
                 clientUpdateStatus: ClientUpdateStatus) {
        self.managedObjectContext = managedObjectContext
        self.clientRegistrationStatus = clientRegistrationStatus
        self.clientUpdateStatus = clientUpdateStatus

        super.init()
    }

    public func processEvents(_ events: [WireTransport.ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) async {
        await events.asyncForEach(processUpdateEvent)
    }

    fileprivate func processUpdateEvent(_ event: ZMUpdateEvent) async {
        switch event.type {
        case .userClientAdd, .userClientRemove:
            await processClientListUpdateEvent(event)
        default:
            break
        }
    }

    fileprivate func processClientListUpdateEvent(_ event: ZMUpdateEvent) async {
        guard let clientInfo = event.payload["client"] as? [String: AnyObject] else {
            Logging.eventProcessing.error("Client info has unexpected payload")
            return
        }

        switch event.type {
        case .userClientAdd:
            await managedObjectContext.perform {
                if let client = UserClient.createOrUpdateSelfUserClient(clientInfo, context: self.managedObjectContext) {
                    let clientSet: Set<UserClient> = [client]
                    let selfUser = ZMUser.selfUser(in: self.managedObjectContext)
                    selfUser.selfClient()?.addNewClientToIgnored(client)
                    selfUser.selfClient()?.updateSecurityLevelAfterDiscovering(clientSet)
                }
            }
        case .userClientRemove:
            let selfUser = await managedObjectContext.perform { ZMUser.selfUser(in: self.managedObjectContext) }
            let selfClientId = await managedObjectContext.perform { selfUser.selfClient()?.remoteIdentifier }

            guard let clientId = clientInfo["id"] as? String else { return }

            if selfClientId != clientId {
                let deletedClient = await managedObjectContext.perform {
                    selfUser.clients.first { $0.remoteIdentifier == clientId }
                }
                await deletedClient?.deleteClientAndEndSession()
            } else {
                await managedObjectContext.perform {
                    self.clientRegistrationStatus.didDetectCurrentClientDeletion()
                    self.clientUpdateStatus.didDetectCurrentClientDeletion()
                }
            }
        default: break
        }
    }

}
