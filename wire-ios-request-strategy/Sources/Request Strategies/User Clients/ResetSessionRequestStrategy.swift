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

public class ResetSessionRequestStrategy: NSObject, ZMContextChangeTrackerSource {

    fileprivate let keyPathSync: KeyPathObjectSync<ResetSessionRequestStrategy>
    fileprivate let messageSender: MessageSenderInterface
    fileprivate let managedObjectContext: NSManagedObjectContext

    public init(managedObjectContext: NSManagedObjectContext,
                messageSender: MessageSenderInterface) {

        self.managedObjectContext = managedObjectContext
        self.keyPathSync = KeyPathObjectSync(entityName: UserClient.entityName(), \.needsToNotifyOtherUserAboutSessionReset)
        self.messageSender = messageSender

        super.init()

        keyPathSync.transcoder = self
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [keyPathSync]
    }

}

extension ResetSessionRequestStrategy: KeyPathObjectSyncTranscoder {

    typealias T = UserClient

    func synchronize(_ userClient: UserClient, completion: @escaping () -> Void) {

        guard let conversation = userClient.user?.oneToOneConversation else {
            return
        }

        let message = GenericMessageEntity(conversation: conversation,
                                           message: GenericMessage(clientAction: .resetSession),
                                           completionHandler: nil)

        // Enter groups to enable waiting for message sending to complete in tests
        let groups = managedObjectContext.enterAllGroupsExceptSecondary()
        Task {
            let result = await messageSender.sendMessage(message: message)

            switch result {
            case .success:
                managedObjectContext.performAndWait {
                    userClient.resolveDecryptionFailedSystemMessages()
                }
            case .failure:
                break
            }

            managedObjectContext.performAndWait {
                completion()
            }
            managedObjectContext.leaveAllGroups(groups)
        }
    }

    func cancel(_ object: UserClient) {

    }

}
