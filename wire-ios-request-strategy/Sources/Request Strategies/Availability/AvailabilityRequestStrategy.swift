//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

public class AvailabilityRequestStrategy: NSObject, ZMContextChangeTrackerSource {

    private let maximumBroadcastRecipients = 500
    private let context: NSManagedObjectContext
    private let modifiedKeysSync: ModifiedKeyObjectSync<AvailabilityRequestStrategy>
    private let messageSender: MessageSenderInterface

    public init(context: NSManagedObjectContext, messageSender: MessageSenderInterface) {
        self.context = context
        self.modifiedKeysSync = ModifiedKeyObjectSync(trackedKey: AvailabilityKey)
        self.messageSender = messageSender

        super.init()

        self.modifiedKeysSync.transcoder = self
    }

<<<<<<< HEAD
=======
    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return modifiedSync.nextRequest(for: apiVersion)
    }

    public var expirationReasonCode: NSNumber?

}

extension AvailabilityRequestStrategy: ZMUpstreamTranscoder {

    public func request(forUpdating managedObject: ZMManagedObject, forKeys keys: Set<String>, apiVersion: APIVersion) -> ZMUpstreamRequest? {
        guard let selfUser = managedObject as? ZMUser else { return nil }

        let originalPath = "/broadcast/otr/messages"
        let message = GenericMessage(content: WireProtos.Availability(selfUser.availability))
        let recipients = ZMUser.recipientsForAvailabilityStatusBroadcast(in: context, maxCount: maximumBroadcastRecipients)

        guard let dataAndMissingClientStrategy = message.encryptForTransport(forBroadcastRecipients: recipients, in: context) else {
            return nil
        }

        let protobufContentType = "application/x-protobuf"
        let path = originalPath.pathWithMissingClientStrategy(strategy: dataAndMissingClientStrategy.strategy)

        let request = ZMTransportRequest(path: path,
                                         method: .methodPOST,
                                         binaryData: dataAndMissingClientStrategy.data,
                                         type: protobufContentType,
                                         contentDisposition: nil,
                                         apiVersion: apiVersion.rawValue)

        return ZMUpstreamRequest(keys: keys, transportRequest: request)
    }

    public func dependentObjectNeedingUpdate(beforeProcessingObject dependant: ZMManagedObject) -> Any? {
        return dependentObjectNeedingUpdateBeforeProcessing
    }

    public func updateUpdatedObject(_ managedObject: ZMManagedObject, requestUserInfo: [AnyHashable: Any]? = nil, response: ZMTransportResponse, keysToParse: Set<String>) -> Bool {
        guard let clientRegistrationDelegate = applicationStatus?.clientRegistrationDelegate else { return false }

        _ = parseUploadResponse(response, clientRegistrationDelegate: clientRegistrationDelegate)

        return false
    }

    public func shouldRetryToSyncAfterFailed(toUpdate managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse, keysToParse keys: Set<String>) -> Bool {
        guard let clientRegistrationDelegate = applicationStatus?.clientRegistrationDelegate else { return false }

        return parseUploadResponse(response, clientRegistrationDelegate: clientRegistrationDelegate).contains(.missing)
    }

    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        return false
    }

    public func request(forInserting managedObject: ZMManagedObject, forKeys keys: Set<String>?, apiVersion: APIVersion) -> ZMUpstreamRequest? {
        return nil // we will never insert objects
    }

    public func updateInsertedObject(_ managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse) {
        // we will never insert objects
    }

    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        return nil
    }

}

extension AvailabilityRequestStrategy: OTREntity {

    public var context: NSManagedObjectContext {
        return managedObjectContext
    }

    public var conversation: ZMConversation? {
        return nil
    }

    public func missesRecipients(_ recipients: Set<UserClient>!) {
        // BE notified us about a new client. A session will be established and then we'll try again
    }

    public func addFailedToSendRecipients(_ recipients: [ZMUser]) {
        // no-op
    }

    public func detectedRedundantUsers(_ users: [ZMUser]) {
        // We were sending a message to clients which should not receive it. To recover
        // from this we must sync resources again.
        applicationStatus?.requestResyncResources()
    }

    public func delivered(with response: ZMTransportResponse) {
        // no-op
    }

    public var dependentObjectNeedingUpdateBeforeProcessing: NSObject? {
        let recipients = ZMUser.recipientsForAvailabilityStatusBroadcast(in: context, maxCount: maximumBroadcastRecipients)
        return self.dependentObjectNeedingUpdateBeforeProcessingOTREntity(recipients: recipients)
    }

    public var isExpired: Bool {
        return false
    }

    public var expirationDate: Date? {
        return nil
    }

    public func expire() {
        // nop
    }

}

extension AvailabilityRequestStrategy: ZMContextChangeTrackerSource {

>>>>>>> 9841bde581 (fix: request loop slow sync - WPB-6502 (#988))
    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [modifiedKeysSync]
    }
}

extension AvailabilityRequestStrategy: ModifiedKeyObjectSyncTranscoder {
    typealias Object = ZMUser

    func synchronize(key: String, for object: ZMUser, completion: @escaping () -> Void) {
        guard object.isSelfUser else { return completion() }

        let message = GenericMessage(content: WireProtos.Availability(object.availability))
        let recipients = ZMUser.recipientsForAvailabilityStatusBroadcast(in: context, maxCount: maximumBroadcastRecipients)
        let proteusMessage = GenericMessageEntity(message: message, context: context, targetRecipients: .users(recipients), completionHandler: nil)

        WaitingGroupTask(context: context) { [self] in
            try? await messageSender.broadcastMessage(message: proteusMessage)
            await context.perform { [self] in
                completion()
                // saving since the `modifiedKeys` of the self user are reset in the completion block
                context.enqueueDelayedSave()
            }
        }
    }
}

extension AvailabilityRequestStrategy: ZMEventConsumer {

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        for event in events {
            guard
                let senderUUID = event.senderUUID, event.isGenericMessageEvent,
                let message = GenericMessage(from: event), message.hasAvailability
            else {
                continue
            }

            let user = ZMUser.fetch(with: senderUUID, in: context)
            user?.updateAvailability(from: message)
        }
    }

}
