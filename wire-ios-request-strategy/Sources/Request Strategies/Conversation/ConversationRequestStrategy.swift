//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireDataModel
import WireLogging

public class ConversationRequestStrategy: AbstractRequestStrategy, ZMRequestGeneratorSource,
    ZMContextChangeTrackerSource {

    let conversationByIDTranscoder: ConversationByIDTranscoder
    let conversationByIDSync: IdentifierObjectSync<ConversationByIDTranscoder>

    let conversationByQualifiedIDTranscoder: ConversationByQualifiedIDTranscoder
    let conversationByQualifiedIDSync: IdentifierObjectSync<ConversationByQualifiedIDTranscoder>

    lazy var modifiedSync: ZMUpstreamModifiedObjectSync = .init(
        transcoder: self,
        entityName: ZMConversation.entityName(),
        keysToSync: keysToSync,
        managedObjectContext: managedObjectContext
    )

    let addParticipantActionHandler: AddParticipantActionHandler
    let removeParticipantActionHandler: RemoveParticipantActionHandler
    let updateAccessRolesActionHandler: UpdateAccessRolesActionHandler

    let updateRoleActionHandler: UpdateRoleActionHandler

    let actionSync: EntityActionSync

    var isFetchingAllConversations: Bool = false

    var keysToSync: [String] = [
        ZMConversationUserDefinedNameKey,
        ZMConversationArchivedChangedTimeStampKey,
        ZMConversationSilencedChangedTimeStampKey
    ]

    let conversationEventProcessor: ConversationEventProcessor // TO KEEP

    let removeLocalConversation: RemoveLocalConversationUseCaseProtocol
    private let apiVersion: WireTransport.APIVersion?
    private let localDomain: String?

    public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        mlsService: MLSServiceInterface,
        removeLocalConversation: RemoveLocalConversationUseCaseProtocol,
        apiVersion: WireTransport.APIVersion?,
        localDomain: String?,
        isFederationEnabled: Bool
    ) {
        self.removeLocalConversation = removeLocalConversation

        self.conversationByIDTranscoder = ConversationByIDTranscoder(
            context: managedObjectContext,
            removeLocalConversationUseCase: removeLocalConversation,
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled
        )
        self.conversationByIDSync = IdentifierObjectSync(
            managedObjectContext: managedObjectContext,
            transcoder: conversationByIDTranscoder
        )

        self.conversationByQualifiedIDTranscoder = ConversationByQualifiedIDTranscoder(
            context: managedObjectContext,
            removeLocalConversationUseCase: removeLocalConversation,
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled
        )
        self.conversationByQualifiedIDSync = IdentifierObjectSync(
            managedObjectContext: managedObjectContext,
            transcoder: conversationByQualifiedIDTranscoder
        )

        self.conversationEventProcessor = ConversationEventProcessor(
            context: managedObjectContext,
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled
        )
        self.addParticipantActionHandler = AddParticipantActionHandler(
            context: managedObjectContext,
            eventProcessor: conversationEventProcessor
        )
        self.removeParticipantActionHandler = RemoveParticipantActionHandler(
            context: managedObjectContext,
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled
        )
        self.updateAccessRolesActionHandler = UpdateAccessRolesActionHandler(
            context: managedObjectContext,
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled
        )

        self.updateRoleActionHandler = UpdateRoleActionHandler(context: managedObjectContext, localDomain: localDomain)

        self.actionSync = EntityActionSync(actionHandlers: [
            addParticipantActionHandler,
            removeParticipantActionHandler,
            updateAccessRolesActionHandler,
            updateRoleActionHandler,
            SyncConversationActionHandler(
                context: managedObjectContext,
                localDomain: localDomain,
                isFederationEnabled: isFederationEnabled
            ),
            CreateGroupConversationActionHandler(
                context: managedObjectContext,
                removeLocalConversationUseCase: removeLocalConversation,
                localDomain: localDomain,
                isFederationEnabled: isFederationEnabled
            ),
            UpdateConversationProtocolActionHandler(context: managedObjectContext),
            CreateConversationGuestLinkActionHandler(context: managedObjectContext),
            SetAllowGuestsAndAppsActionHandler(
                context: managedObjectContext,
                localDomain: localDomain,
                isFederationEnabled: isFederationEnabled
            )
        ])

        self.apiVersion = apiVersion
        self.localDomain = localDomain

        super.init(
            withManagedObjectContext: managedObjectContext,
            applicationStatus: applicationStatus
        )

        self.configuration = [
            .allowsRequestsWhileOnline,
            .allowsRequestsDuringSlowSync,
            .allowsRequestsDuringQuickSync,
            .allowsRequestsWhileWaitingForWebsocket
        ]
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        requestGenerators.nextRequest(for: apiVersion)
    }

    func fetch(_ conversations: Set<ZMConversation>, for apiVersion: APIVersion) {
        switch apiVersion {
        case .v0:
            conversationByIDSync.sync(identifiers: conversations.compactMap(\.remoteIdentifier))

        case .v1, .v2, .v3, .v4, .v5, .v6, .v7, .v8, .v9, .v10, .v11, .v12, .v13:
            if let qualifiedIDs = conversations.qualifiedIDs {
                conversationByQualifiedIDSync.sync(identifiers: qualifiedIDs)
            } else if let localDomain {
                let qualifiedIDs = conversations.fallbackQualifiedIDs(localDomain: localDomain)
                conversationByQualifiedIDSync.sync(identifiers: qualifiedIDs)
            }
        }
    }

    public var requestGenerators: [ZMRequestGenerator] {
        [
            conversationByIDSync,
            conversationByQualifiedIDSync,
            modifiedSync,
            actionSync
        ]
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [modifiedSync]
    }

}

extension ConversationRequestStrategy: ZMUpstreamTranscoder {

    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        false
    }

    public func shouldCreateRequest(
        toSyncObject managedObject: ZMManagedObject,
        forKeys keys: Set<String>,
        withSync sync: Any,
        apiVersion: APIVersion
    ) -> Bool {
        guard (sync as AnyObject) === modifiedSync else {
            return true
        }

        guard let conversation = managedObject as? ZMConversation else {
            return false
        }

        var remainingKeys = keys

        if keys.contains(ZMConversationUserDefinedNameKey), conversation.userDefinedName == nil {
            let conversationUserDefinedNameKeySet: Set<AnyHashable> = [ZMConversationUserDefinedNameKey]
            conversation.resetLocallyModifiedKeys(conversationUserDefinedNameKeySet)
            remainingKeys.remove(ZMConversationUserDefinedNameKey)
        }

        if remainingKeys.count < keys.count {
            let conversationSet: Set<NSManagedObject> = [conversation]
            contextChangeTrackers.forEach { $0.objectsDidChange(conversationSet) }
            managedObjectContext.enqueueDelayedSave()
        }

        return !remainingKeys.isEmpty
    }

    public func shouldRetryToSyncAfterFailed(
        toUpdate managedObject: ZMManagedObject,
        request upstreamRequest: ZMUpstreamRequest,
        response: ZMTransportResponse,
        keysToParse keys: Set<String>
    ) -> Bool {
        false
    }

    public func updateInsertedObject(
        _ managedObject: ZMManagedObject,
        request upstreamRequest: ZMUpstreamRequest,
        response: ZMTransportResponse
    ) {
        // no op
    }

    public func updateUpdatedObject(
        _ managedObject: ZMManagedObject,
        requestUserInfo: [AnyHashable: Any]? = nil,
        response: ZMTransportResponse,
        keysToParse: Set<String>
    ) -> Bool {
        guard
            keysToParse.contains(ZMConversationUserDefinedNameKey),
            let payload = response.payload
        else {
            return false
        }

        // There is one case where you end up here:
        // selfUser edits the conversation name: a save will be enqueue when user is done editing
        conversationEventProcessor.processConversationRenamePayload(payload)

        return false
    }

    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        nil
    }

    public func request(
        forUpdating managedObject: ZMManagedObject,
        forKeys keys: Set<String>,
        apiVersion: APIVersion
    ) -> ZMUpstreamRequest? {
        guard
            let conversation = managedObject as? ZMConversation,
            let conversationID = conversation.remoteIdentifier?.transportString()
        else {
            return nil
        }

        if keys.contains(ZMConversationUserDefinedNameKey) {
            guard
                let payload = Payload.UpdateConversationName(conversation),
                let payloadData = payload.payloadData(encoder: .defaultEncoder),
                let payloadAsString = String(bytes: payloadData, encoding: .utf8)
            else {
                return nil
            }

            let request: ZMTransportRequest
            switch apiVersion {

            case .v0:
                request = ZMTransportRequest(
                    path: "/conversations/\(conversationID)",
                    method: .put,
                    payload: payloadAsString as ZMTransportData?,
                    apiVersion: apiVersion.rawValue
                )

            case .v1, .v2, .v3, .v4, .v5, .v6, .v7, .v8, .v9, .v10, .v11, .v12, .v13:
                let domain = if let domain = conversation.domain, !domain.isEmpty { domain } else { localDomain }
                guard let domain else { return nil }

                request = ZMTransportRequest(
                    path: "/conversations/\(domain)/\(conversationID)/name",
                    method: .put,
                    payload: payloadAsString as ZMTransportData?,
                    apiVersion: apiVersion.rawValue
                )
            }

            let conversationUserDefinedNameKey = Set([ZMConversationUserDefinedNameKey])
            return ZMUpstreamRequest(
                keys: conversationUserDefinedNameKey,
                transportRequest: request
            )
        }

        if keys.contains(ZMConversationArchivedChangedTimeStampKey) ||
            keys.contains(ZMConversationSilencedChangedTimeStampKey) {
            let payload = Payload.UpdateConversationStatus(conversation)

            guard
                let payloadData = payload.payloadData(encoder: .defaultEncoder),
                let payloadAsString = String(bytes: payloadData, encoding: .utf8)
            else {
                return nil
            }

            let request: ZMTransportRequest

            switch apiVersion {

            case .v0:
                request = ZMTransportRequest(
                    path: "/conversations/\(conversationID)/self",
                    method: .put,
                    payload: payloadAsString as ZMTransportData?,
                    apiVersion: apiVersion.rawValue
                )

            case .v1, .v2, .v3, .v4, .v5, .v6, .v7, .v8, .v9, .v10, .v11, .v12, .v13:
                let domain = if let domain = conversation.domain, !domain.isEmpty { domain } else { localDomain }
                guard let domain else { return nil }

                request = ZMTransportRequest(
                    path: "/conversations/\(domain)/\(conversationID)/self",
                    method: .put,
                    payload: payloadAsString as ZMTransportData?,
                    apiVersion: apiVersion.rawValue
                )
            }

            let changedKeys = keys.intersection([
                ZMConversationArchivedChangedTimeStampKey,
                ZMConversationSilencedChangedTimeStampKey
            ])

            return ZMUpstreamRequest(
                keys: changedKeys,
                transportRequest: request
            )
        }

        return nil
    }

    public func request(
        forInserting managedObject: ZMManagedObject,
        forKeys keys: Set<String>?,
        apiVersion: APIVersion
    ) -> ZMUpstreamRequest? {
        nil
    }

}

class ConversationByIDTranscoder: IdentifierObjectSyncTranscoder {
    public typealias T = UUID

    var fetchLimit: Int = 1

    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    private let processor: ConversationEventPayloadProcessor
    private let removeLocalConversation: RemoveLocalConversationUseCaseProtocol

    init(
        context: NSManagedObjectContext,
        removeLocalConversationUseCase: RemoveLocalConversationUseCaseProtocol,
        localDomain: String?,
        isFederationEnabled: Bool
    ) {
        self.context = context
        self.removeLocalConversation = removeLocalConversationUseCase
        self.processor = ConversationEventPayloadProcessor(
            mlsEventProcessor: MLSEventProcessor(context: context, localDomain: localDomain),
            removeLocalConversation: removeLocalConversation,
            isFederationEnabled: isFederationEnabled
        )
    }

    func request(for identifiers: Set<UUID>, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard let converationID = identifiers.first.map({ $0.transportString() }) else { return nil }

        // GET /conversations/<UUID>
        return ZMTransportRequest(getFromPath: "/conversations/\(converationID)", apiVersion: apiVersion.rawValue)
    }

    func didReceive(
        response: ZMTransportResponse,
        for identifiers: Set<UUID>,
        completionHandler: @escaping () -> Void
    ) {

        guard response.result != .permanentError else {
            if response.httpStatus == 404 {
                WaitingGroupTask(context: context) { [self] in
                    await deleteConversations(identifiers)
                    completionHandler()
                }
                return
            }

            if response.httpStatus == 403 {
                removeSelfUser(identifiers)
                return completionHandler()
            }

            markConversationsAsFetched(identifiers)
            return completionHandler()
        }

        guard
            let apiVersion = APIVersion(rawValue: response.apiVersion),
            let rawData = response.rawData,
            let payload = Payload.Conversation(rawData, apiVersion: apiVersion, decoder: decoder)
        else {
            Logging.network.warn("Can't process response, aborting.")
            return completionHandler()
        }

        WaitingGroupTask(context: context) { [self] in
            await processor.updateOrCreateConversation(
                from: payload,
                in: context
            )
            completionHandler()
        }
    }

    private func deleteConversations(_ conversations: Set<UUID>) async {
        for conversationID in conversations {
            let (conversation, conversationType) = await context.perform { [context] in
                let conversation = ZMConversation.fetch(with: conversationID, domain: nil, in: context)
                return (conversation, conversation?.conversationType)
            }

            guard let conversation, conversationType == .group else { continue }

            do {
                try await removeLocalConversation.invoke(
                    with: conversation,
                    syncContext: context
                )
            } catch {
                WireLogger.mls.error("removeLocalConversation threw error: \(String(reflecting: error))")
            }
        }
    }

    private func removeSelfUser(_ conversations: Set<UUID>) {
        for conversationID in conversations {
            guard let conversation = ZMConversation.fetch(with: conversationID, domain: nil, in: context) else {
                continue
            }

            guard conversation.conversationType == .group,
                  conversation.isSelfAnActiveMember
            else {
                conversation.needsToBeUpdatedFromBackend = false
                continue
            }

            let selfUser = ZMUser.selfUser(in: context)
            conversation.removeParticipantAndUpdateConversationState(user: selfUser, initiatingUser: selfUser)
            conversation.needsToBeUpdatedFromBackend = false
        }
    }

    private func markConversationsAsFetched(_ conversations: Set<UUID>) {
        for conversationID in conversations {
            guard
                let conversation = ZMConversation.fetch(with: conversationID, domain: nil, in: context)
            else {
                continue
            }
            conversation.needsToBeUpdatedFromBackend = false
        }
    }
}

class ConversationByQualifiedIDTranscoder: IdentifierObjectSyncTranscoder {
    public typealias T = QualifiedID

    var fetchLimit: Int = 1

    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    private let processor: ConversationEventPayloadProcessor
    private let removeLocalConversation: RemoveLocalConversationUseCaseProtocol

    init(
        context: NSManagedObjectContext,
        removeLocalConversationUseCase: RemoveLocalConversationUseCaseProtocol,
        localDomain: String?,
        isFederationEnabled: Bool
    ) {
        self.context = context
        self.removeLocalConversation = removeLocalConversationUseCase
        self.processor = ConversationEventPayloadProcessor(
            mlsEventProcessor: MLSEventProcessor(context: context, localDomain: localDomain),
            removeLocalConversation: removeLocalConversation,
            isFederationEnabled: isFederationEnabled
        )
    }

    func request(for identifiers: Set<QualifiedID>, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard
            let conversationID = identifiers.first.map({ $0.uuid.transportString() }),
            let domain = identifiers.first?.domain
        else {
            return nil
        }

        // GET /conversations/domain/<UUID>
        return ZMTransportRequest(
            getFromPath: "/conversations/\(domain)/\(conversationID)",
            apiVersion: apiVersion.rawValue
        )
    }

    func didReceive(
        response: ZMTransportResponse,
        for identifiers: Set<QualifiedID>,
        completionHandler: @escaping () -> Void
    ) {

        guard response.result != .permanentError else {
            markConversationsAsFetched(identifiers)

            if response.httpStatus == 404 {
                WaitingGroupTask(context: context) { [self] in
                    await deleteConversations(identifiers)
                    completionHandler()
                }
                return
            }

            if response.httpStatus == 403 {
                removeSelfUser(identifiers)
                return completionHandler()
            }
            return completionHandler()
        }

        guard
            let apiVersion = APIVersion(rawValue: response.apiVersion),
            let rawData = response.rawData,
            let payload = Payload.Conversation(
                rawData,
                apiVersion: apiVersion,
                decoder: decoder
            )
        else {
            Logging.network.warn("Can't process response, aborting.")
            return completionHandler()
        }

        WaitingGroupTask(context: context) { [self] in
            await processor.updateOrCreateConversation(
                from: payload,
                in: context
            )
            completionHandler()
        }
    }

    private func deleteConversations(_ conversationIds: Set<QualifiedID>) async {
        for qualifiedID in conversationIds {

            let conversation: ZMConversation? = await context.perform { [context] in
                let conversation = ZMConversation.fetch(
                    with: qualifiedID.uuid,
                    domain: qualifiedID.domain,
                    in: context
                )
                if conversation?.conversationType == .group {
                    return conversation
                } else {
                    return nil
                }
            }

            guard let conversation else { continue }

            do {
                try await removeLocalConversation.invoke(
                    with: conversation,
                    syncContext: context
                )
            } catch {
                WireLogger.mls.error("removeLocalConversation threw error: \(String(reflecting: error))")
            }
        }
    }

    private func removeSelfUser(_ conversations: Set<QualifiedID>) {
        for qualifiedID in conversations {
            guard
                let conversation = ZMConversation.fetch(
                    with: qualifiedID.uuid,
                    domain: qualifiedID.domain,
                    in: context
                ),
                conversation.conversationType == .group,
                conversation.isSelfAnActiveMember
            else {
                continue
            }
            let selfUser = ZMUser.selfUser(in: context)
            conversation.removeParticipantAndUpdateConversationState(user: selfUser, initiatingUser: selfUser)
        }
    }

    private func markConversationsAsFetched(_ conversations: Set<QualifiedID>) {
        for qualifiedID in conversations {
            guard
                let conversation = ZMConversation.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: context)
            else {
                continue
            }
            conversation.needsToBeUpdatedFromBackend = false
        }
    }
}

final class ConversationByIDListTranscoder: IdentifierObjectSyncTranscoder {

    public typealias T = UUID

    var fetchLimit: Int = 32

    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    private let processor: ConversationEventPayloadProcessor

    init(
        context: NSManagedObjectContext,
        localDomain: String?,
        isFederationEnabled: Bool
    ) {
        self.context = context
        self.processor = ConversationEventPayloadProcessor(
            mlsEventProcessor: MLSEventProcessor(context: context, localDomain: localDomain),
            removeLocalConversation: RemoveLocalConversationUseCase(),
            isFederationEnabled: isFederationEnabled
        )
    }

    func request(for identifiers: Set<UUID>, apiVersion: APIVersion) -> ZMTransportRequest? {
        // GET /conversations?ids=?
        guard apiVersion < .v2 else { return nil }
        let converationIDs = identifiers.map { $0.transportString() }.joined(separator: ",")
        return ZMTransportRequest(getFromPath: "/conversations?ids=\(converationIDs)", apiVersion: apiVersion.rawValue)
    }

    func didReceive(
        response: ZMTransportResponse,
        for identifiers: Set<UUID>,
        completionHandler: @escaping () -> Void
    ) {
        guard
            let apiVersion = APIVersion(rawValue: response.apiVersion),
            let rawData = response.rawData,
            let payload = Payload.ConversationList(rawData, apiVersion: apiVersion, decoder: decoder)
        else {
            Logging.network.warn("Can't process response, aborting.")
            return completionHandler()
        }

        WaitingGroupTask(context: context) { [self] in
            await processor.updateOrCreateConversations(
                from: payload,
                in: context
            )

            await context.perform {
                let missingIdentifiers = identifiers.subtracting(payload.conversations.compactMap(\.id))
                self.queryStatusForMissingConversations(missingIdentifiers)
            }
            completionHandler()
        }
    }

    /// Query the backend if a conversation is deleted or the self user has been removed
    private func queryStatusForMissingConversations(_ conversations: Set<UUID>) {
        for conversationID in conversations {
            let conversation = ZMConversation.fetch(with: conversationID, in: context)
            conversation?.needsToBeUpdatedFromBackend = true
        }
    }

}

class ConversationByQualifiedIDListTranscoder: IdentifierObjectSyncTranscoder {

    public typealias T = QualifiedID

    var fetchLimit: Int = 100

    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    private let processor: ConversationEventPayloadProcessor
    private let removeLocalConversation: RemoveLocalConversationUseCaseProtocol

    private let isFederationEnabled: Bool

    init(
        context: NSManagedObjectContext,
        removeLocalConversationUseCase: RemoveLocalConversationUseCaseProtocol,
        localDomain: String?,
        isFederationEnabled: Bool
    ) {
        self.context = context
        self.removeLocalConversation = removeLocalConversationUseCase
        self.processor = ConversationEventPayloadProcessor(
            mlsEventProcessor: MLSEventProcessor(context: context, localDomain: localDomain),
            removeLocalConversation: removeLocalConversation,
            isFederationEnabled: isFederationEnabled
        )
        self.isFederationEnabled = isFederationEnabled
    }

    func request(for identifiers: Set<QualifiedID>, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard
            let payloadData = Payload.QualifiedUserIDList(qualifiedIDs: Array(identifiers))
            .payloadData(encoder: encoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            return nil
        }

        let path = apiVersion >= .v2 ? "/conversations/list" : "/conversations/list/v2"

        return ZMTransportRequest(
            path: path,
            method: .post,
            payload: payloadAsString as ZMTransportData,
            apiVersion: apiVersion.rawValue
        )
    }

    func didReceive(
        response: ZMTransportResponse,
        for identifiers: Set<QualifiedID>,
        completionHandler: @escaping () -> Void
    ) {

        guard
            let apiVersion = APIVersion(rawValue: response.apiVersion),
            let rawData = response.rawData,
            let payload = Payload.QualifiedConversationList(rawData, apiVersion: apiVersion, decoder: decoder)
        else {
            Logging.network.warn("Can't process response, aborting.")
            return completionHandler()
        }

        WaitingGroupTask(context: context) { [self] in
            await processor.updateOrCreateConverations(
                from: payload,
                in: context
            )

            await context.perform {
                self.queryStatusForMissingConversations(payload.notFound)
                self.queryStatusForFailedConversations(payload.failed)
            }
            completionHandler()
        }
    }

    /// Query the backend if a conversation is deleted or the self user has been removed
    private func queryStatusForMissingConversations(_ conversations: [QualifiedID]) {
        for qualifiedID in conversations {
            let conversation = ZMConversation.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: context)
            conversation?.needsToBeUpdatedFromBackend = true
        }
    }

    /// Query the backend again if a converation couldn't be fetched
    private func queryStatusForFailedConversations(_ conversations: [QualifiedID]) {

        for qualifiedID in conversations {
            let conversation = ZMConversation.fetchOrCreate(
                with: qualifiedID.uuid,
                domain: qualifiedID.domain,
                in: context
            )
            conversation.isPendingMetadataRefresh = true
            conversation.needsToBeUpdatedFromBackend = true
        }
    }

}

private extension Collection<ZMConversation> {

    func fallbackQualifiedIDs(localDomain: String) -> [QualifiedID] {
        compactMap { conversation in
            if let qualifiedID = conversation.qualifiedID {
                qualifiedID
            } else if let identifier = conversation.remoteIdentifier {
                QualifiedID(uuid: identifier, domain: localDomain)
            } else {
                nil
            }
        }
    }

}
