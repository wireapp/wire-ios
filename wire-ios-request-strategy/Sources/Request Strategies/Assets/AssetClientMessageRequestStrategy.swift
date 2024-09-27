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

// MARK: - AssetClientMessageRequestStrategy

/// The `AssetClientMessageRequestStrategy` for creating requests to insert the genericMessage of a
/// `ZMAssetClientMessage` remotely. This is only necessary for the `/assets/v3' endpoint as we
/// upload the asset, receive the asset ID in the response, manually add it to the genericMessage and
/// send it using the `/messages` endpoint like any other message. This is an additional step required
/// as the fan-out was previously done by the backend when uploading a v2 asset.
public final class AssetClientMessageRequestStrategy: NSObject, ZMContextChangeTrackerSource {
    let managedObjectContext: NSManagedObjectContext
    let insertedObjectSync: InsertedObjectSync<AssetClientMessageRequestStrategy>
    let messageSender: MessageSenderInterface

    public init(managedObjectContext: NSManagedObjectContext, messageSender: MessageSenderInterface) {
        self.managedObjectContext = managedObjectContext
        self
            .insertedObjectSync = InsertedObjectSync(
                insertPredicate: Self
                    .shouldBeSentPredicate(context: managedObjectContext)
            )
        self.messageSender = messageSender

        super.init()

        insertedObjectSync.transcoder = self
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [insertedObjectSync]
    }

    static func shouldBeSentPredicate(context: NSManagedObjectContext) -> NSPredicate {
        let notDelivered = NSPredicate(format: "%K == FALSE", DeliveredKey)
        let notExpired = NSPredicate(format: "%K == 0", ZMMessageIsExpiredKey)
        let isUploaded = NSPredicate(format: "%K == \(AssetTransferState.uploaded.rawValue)", "transferState")
        let isAssetV3 = NSPredicate(format: "version >= 3")
        let fromSelf = NSPredicate(format: "%K == %@", ZMMessageSenderKey, ZMUser.selfUser(in: context))
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            notDelivered,
            notExpired,
            isAssetV3,
            isUploaded,
            fromSelf,
        ])
    }
}

// MARK: InsertedObjectSyncTranscoder

extension AssetClientMessageRequestStrategy: InsertedObjectSyncTranscoder {
    typealias Object = ZMAssetClientMessage

    func insert(object: ZMAssetClientMessage, completion: @escaping () -> Void) {
        let logAttributesBuilder = MessageLogAttributesBuilder(context: managedObjectContext)
        let logAttributes = logAttributesBuilder.syncLogAttributes(object)
        WireLogger.messaging.debug("inserting message", attributes: logAttributes)

        // Enter groups to enable waiting for message sending to complete in tests
        let groups = managedObjectContext.enterAllGroupsExceptSecondary()
        Task {
            do {
                try await messageSender.sendMessage(message: object)

                let logAttributes = await logAttributesBuilder.logAttributes(object)
                WireLogger.messaging.debug("successfully sent message", attributes: logAttributes)

                await managedObjectContext.perform {
                    object.markAsSent()
                    self.managedObjectContext.enqueueDelayedSave()
                }
            } catch {
                let logAttributes = await logAttributesBuilder.logAttributes(object)
                WireLogger.messaging.error("failed to send message: \(error)", attributes: logAttributes)

                await managedObjectContext.perform {
                    object.expire()
                    self.managedObjectContext.enqueueDelayedSave()

                    if case let NetworkError.invalidRequestError(responseFailure, _) = error,
                       responseFailure.label == .missingLegalholdConsent {
                        self.managedObjectContext.zm_userInterface.performGroupedBlock {
                            NotificationInContext(
                                name: ZMConversation.failedToSendMessageNotificationName,
                                context: self.managedObjectContext.notificationContext
                            ).post()
                        }
                    }
                }
            }

            await managedObjectContext.perform {
                // make sure completion is called on same calling thread so syncContext
                completion()
            }
            managedObjectContext.leaveAllGroups(groups)
        }
    }
}
