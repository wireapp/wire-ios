//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

public protocol ProteusMessage: OTREntity, EncryptedPayloadGenerator, Hashable {}

extension ZMClientMessage: ProteusMessage {}
extension ZMAssetClientMessage: ProteusMessage {}

/**
 ProteusMessageSync synchronizes messages with the backend using the Proteus encryption protocol.

 This only works with objects which implements the `ProteusMessage` protocol.
 */
public class ProteusMessageSync<Message: ProteusMessage>: NSObject, EntityTranscoder, ZMContextChangeTrackerSource, ZMRequestGenerator {

    public typealias Entity = Message
    public typealias OnRequestScheduledHandler = (_ message: Message, _ request: ZMTransportRequest) -> Void

    var dependencySync: DependencyEntitySync<ProteusMessageSync>!
    let requestFactory = ClientMessageRequestFactory()
    let applicationStatus: ApplicationStatus
    let context: NSManagedObjectContext
    var onRequestScheduledHandler: OnRequestScheduledHandler?

    public init(context: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        self.context = context
        self.applicationStatus = applicationStatus

        super.init()

        self.dependencySync = DependencyEntitySync<ProteusMessageSync>(transcoder: self, context: context)
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [dependencySync]
    }

    public func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return dependencySync.nextRequest(for: apiVersion)
    }

    public func onRequestScheduled(_ handler: @escaping OnRequestScheduledHandler) {
        onRequestScheduledHandler = handler
    }

    public func sync(_ message: Message, completion: @escaping EntitySyncHandler) {
        WireLogger.messaging.debug("sync proteus message \(message.debugInfo)")
        dependencySync.synchronize(entity: message, completion: completion)
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
    }

    public func expireMessages(withDependency dependency: NSObject) {
        WireLogger.messaging.warn("expiring messages with dependency: \(String(describing: dependency))")
        dependencySync.expireEntities(withDependency: dependency)
    }

    public func request(forEntity entity: Message, apiVersion: APIVersion) -> ZMTransportRequest? {
        WireLogger.messaging.debug("request for message \(entity.debugInfo)")

        guard
            let conversation = entity.conversation,
            let request = requestFactory.upstreamRequestForMessage(entity, in: conversation, apiVersion: apiVersion)
        else {
            WireLogger.messaging.warn("no request for message \(entity.debugInfo)")
            return nil
        }

        if let expirationDate = entity.expirationDate {
            request.expire(at: expirationDate)
        }

        onRequestScheduledHandler?(entity, request)

        return request
    }

    public func request(forEntity entity: Message, didCompleteWithResponse response: ZMTransportResponse) {
        WireLogger.messaging.debug("request for message did complete \(entity.debugInfo)")
        entity.delivered(with: response)

        guard let apiVersion = APIVersion(rawValue: response.apiVersion) else {
            WireLogger.messaging.error("failed to get api version from response, not handling response")
            return
        }

        switch apiVersion {
        case .v0:
            _ = entity.parseUploadResponse(response, clientRegistrationDelegate: applicationStatus.clientRegistrationDelegate)
        case .v1, .v2, .v3, .v4, .v5:
            if let payload = Payload.MessageSendingStatus(response, decoder: .defaultDecoder) {
                _ = payload.updateClientsChanges(for: entity)
            } else {
                WireLogger.messaging.warn("failed to get payload from response")
            }
        }

        purgeEncryptedPayloadCache()
    }

    public func shouldTryToResend(
        entity: Message,
        afterFailureWithResponse response: ZMTransportResponse
    ) -> Bool {
        WireLogger.messaging.debug("should try to resend for message \(entity.debugInfo)?")

        guard let apiVersion = APIVersion(rawValue: response.apiVersion) else {
            WireLogger.messaging.warn("not trying to resend, no api version")
            return false
        }

        switch response.httpStatus {
        case 412:
            switch apiVersion {
            case .v0:
                return entity.parseUploadResponse(response, clientRegistrationDelegate: applicationStatus.clientRegistrationDelegate).contains(.missing)
            case .v1, .v2, .v3, .v4, .v5:
                let payload = Payload.MessageSendingStatus(response, decoder: .defaultDecoder)
                let shouldRetry = payload?.updateClientsChanges(for: entity) ?? false
                WireLogger.messaging.debug("got 412, will retry: \(shouldRetry)")
                return shouldRetry
            }

        case 533:
            guard
                let payload = Payload.ResponseFailure(response, decoder: .defaultDecoder),
                let data = payload.data
            else {
                return false
            }

            switch data.type {
            case .federation:
                payload.updateExpirationReason(for: entity, with: .federationRemoteError)
            case .unknown:
                payload.updateExpirationReason(for: entity, with: .unknown)
            }

            return false
        default:
            let payload = Payload.ResponseFailure(response, decoder: .defaultDecoder)
            if payload?.label == .unknownClient {
                applicationStatus.clientRegistrationDelegate.didDetectCurrentClientDeletion()
            }

            if case .permanentError = response.result {
                WireLogger.messaging.warn("got \(response.httpStatus), not retrying")
                return false
            } else {
                WireLogger.messaging.warn("got \(response.httpStatus), retrying")
                return true
            }
        }
    }

    fileprivate func purgeEncryptedPayloadCache() {
        context.proteusProvider.perform(
            withProteusService: { _ in },
            withKeyStore: { keyStore in
                keyStore.encryptionContext.perform { (session) in
                    session.purgeEncryptedPayloadCache()
                }
            }
        )
    }

}
