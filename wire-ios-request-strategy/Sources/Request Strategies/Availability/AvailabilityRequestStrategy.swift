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

// MARK: - AvailabilityRequestStrategy

public class AvailabilityRequestStrategy: NSObject, ZMContextChangeTrackerSource {
    // MARK: Lifecycle

    public init(context: NSManagedObjectContext, messageSender: MessageSenderInterface) {
        self.context = context
        self.modifiedKeysSync = ModifiedKeyObjectSync(trackedKey: AvailabilityKey)
        self.messageSender = messageSender

        super.init()

        modifiedKeysSync.transcoder = self
    }

    // MARK: Public

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [modifiedKeysSync]
    }

    // MARK: Private

    private let maximumBroadcastRecipients = 500
    private let context: NSManagedObjectContext
    private let modifiedKeysSync: ModifiedKeyObjectSync<AvailabilityRequestStrategy>
    private let messageSender: MessageSenderInterface
}

// MARK: ModifiedKeyObjectSyncTranscoder

extension AvailabilityRequestStrategy: ModifiedKeyObjectSyncTranscoder {
    typealias Object = ZMUser

    func synchronize(key: String, for object: ZMUser, completion: @escaping () -> Void) {
        guard object.isSelfUser else { return completion() }

        let message = GenericMessage(content: WireProtos.Availability(object.availability))
        let recipients = ZMUser.recipientsForAvailabilityStatusBroadcast(
            in: context,
            maxCount: maximumBroadcastRecipients
        )
        let proteusMessage = GenericMessageEntity(
            message: message,
            context: context,
            targetRecipients: .users(recipients),
            completionHandler: nil
        )

        WaitingGroupTask(context: context) { [self] in
            do {
                try await messageSender.broadcastMessage(message: proteusMessage)
            } catch {
                WireLogger.userClient.error("Failed to update user Status with broadcast message: \(error)")
            }
            await context.perform { [self] in
                completion()
                // saving since the `modifiedKeys` of the self user are reset in the completion block
                context.enqueueDelayedSave()
            }
        }
    }
}

// MARK: ZMEventConsumer

extension AvailabilityRequestStrategy: ZMEventConsumer {
    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        for event in events {
            guard
                let senderUUID = event.senderUUID, event.isGenericMessageEvent,
                let message = GenericMessage(from: event), message.hasAvailability
            else {
                continue
            }

            guard let user = ZMUser.fetch(with: senderUUID, in: context) else {
                assertionFailure("User not found to updateAvailability")
                continue
            }
            user.updateAvailability(from: message)
        }
    }
}
