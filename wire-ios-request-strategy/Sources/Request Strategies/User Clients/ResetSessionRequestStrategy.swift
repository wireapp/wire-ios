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

// MARK: - ResetSessionRequestStrategy

public class ResetSessionRequestStrategy: NSObject, ZMContextChangeTrackerSource {
    // MARK: Lifecycle

    public init(
        managedObjectContext: NSManagedObjectContext,
        messageSender: MessageSenderInterface
    ) {
        self.managedObjectContext = managedObjectContext
        self.keyPathSync = KeyPathObjectSync(
            entityName: UserClient.entityName(),
            \.needsToNotifyOtherUserAboutSessionReset
        )
        self.messageSender = messageSender

        super.init()

        keyPathSync.transcoder = self
    }

    // MARK: Public

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [keyPathSync]
    }

    // MARK: Fileprivate

    fileprivate let keyPathSync: KeyPathObjectSync<ResetSessionRequestStrategy>
    fileprivate let messageSender: MessageSenderInterface
    fileprivate let managedObjectContext: NSManagedObjectContext
}

// MARK: KeyPathObjectSyncTranscoder

extension ResetSessionRequestStrategy: KeyPathObjectSyncTranscoder {
    typealias T = UserClient

    func synchronize(_ userClient: UserClient, completion: @escaping () -> Void) {
        guard let conversation = userClient.user?.oneToOneConversation else {
            return
        }

        let message = GenericMessageEntity(
            message: GenericMessage(clientAction: .resetSession),
            context: managedObjectContext,
            conversation: conversation,
            completionHandler: nil
        )

        WaitingGroupTask(context: managedObjectContext) { [self] in
            do {
                try await messageSender.sendMessage(message: message)
                await managedObjectContext.perform {
                    userClient.resolveDecryptionFailedSystemMessages()
                }
            } catch {
                WireLogger.messaging.error("Failed to send reset session message: \(error)")
            }

            await managedObjectContext.perform {
                completion()
                // saving since the `needsToNotifyOtherUserAboutSessionReset` are reset in the completion block
                self.managedObjectContext.enqueueDelayedSave()
            }
        }
    }

    func cancel(_: UserClient) {}
}
