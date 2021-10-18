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

public class ConversationRequestStrategy: AbstractRequestStrategy, ZMRequestGeneratorSource, ZMContextChangeTrackerSource, FederationAware {

    let syncProgress: SyncProgress
    let conversationIDsSync: PaginatedSync<Payload.PaginatedConversationIDList>
    let conversationQualifiedIDsSync: PaginatedSync<Payload.PaginatedQualifiedConversationIDList>

    let conversationByIDTranscoder: ConversationByIDTranscoder
    let conversationByIDSync: IdentifierObjectSync<ConversationByIDTranscoder>

    let conversationByQualifiedIDTranscoder: ConversationByQualifiedIDTranscoder
    let conversationByQualifiedIDSync: IdentifierObjectSync<ConversationByQualifiedIDTranscoder>

    let conversationByIDListTranscoder: ConversationByIDListTranscoder
    let conversationByIDListSync: IdentifierObjectSync<ConversationByIDListTranscoder>

    let conversationByQualifiedIDListTranscoder: ConversationByQualifiedIDListTranscoder
    let conversationByQualifiedIDListSync: IdentifierObjectSync<ConversationByQualifiedIDListTranscoder>

    lazy var insertSync: ZMUpstreamInsertedObjectSync = {
        ZMUpstreamInsertedObjectSync(transcoder: self,
                                     entityName: ZMConversation.entityName(),
                                     managedObjectContext: managedObjectContext)
    }()
    lazy var modifiedSync: ZMUpstreamModifiedObjectSync = {
        ZMUpstreamModifiedObjectSync(transcoder: self,
                                     entityName: ZMConversation.entityName(),
                                     keysToSync: keysToSync,
                                     managedObjectContext: managedObjectContext)
    }()

    let addParticipantActionHandler: AddParticipantActionHandler
    let removeParticipantActionHandler: RemoveParticipantActionHandler

    let updateSync: KeyPathObjectSync<ConversationRequestStrategy>
    let actionSync: EntityActionSync

    var isFetchingAllConversations: Bool = false

    var keysToSync: [String] = [
        ZMConversationUserDefinedNameKey,
        ZMConversationArchivedChangedTimeStampKey,
        ZMConversationSilencedChangedTimeStampKey
    ]

    let eventsToProcess: [ZMUpdateEventType] = [
        .conversationCreate,
        .conversationDelete,
        .conversationMemberLeave,
        .conversationMemberJoin,
        .conversationRename,
        .conversationMemberUpdate,
        .conversationAccessModeUpdate,
        .conversationMessageTimerUpdate,
        .conversationReceiptModeUpdate,
        .conversationConnectRequest
    ]

    public var useFederationEndpoint: Bool = true {
        didSet {
            conversationByQualifiedIDTranscoder.isAvailable = useFederationEndpoint
            addParticipantActionHandler.useFederationEndpoint = useFederationEndpoint
            removeParticipantActionHandler.useFederationEndpoint = useFederationEndpoint
        }
    }

    public init(withManagedObjectContext managedObjectContext: NSManagedObjectContext,
         applicationStatus: ApplicationStatus,
         syncProgress: SyncProgress) {

        self.syncProgress = syncProgress
        self.conversationIDsSync =
            PaginatedSync<Payload.PaginatedConversationIDList>(basePath: "/conversations/ids",
                                                               pageSize: 32,
                                                               context: managedObjectContext)

        self.conversationQualifiedIDsSync =
            PaginatedSync<Payload.PaginatedQualifiedConversationIDList>(basePath: "/conversations/list-ids",
                                                                        pageSize: 500,
                                                                        method: .post,
                                                                        context: managedObjectContext)

        self.conversationByIDListTranscoder = ConversationByIDListTranscoder(context: managedObjectContext)
        self.conversationByIDListSync = IdentifierObjectSync(managedObjectContext: managedObjectContext,
                                                             transcoder: conversationByIDListTranscoder)

        self.conversationByQualifiedIDListTranscoder = ConversationByQualifiedIDListTranscoder(context: managedObjectContext)
        self.conversationByQualifiedIDListSync = IdentifierObjectSync(managedObjectContext: managedObjectContext,
                                                                      transcoder: conversationByQualifiedIDListTranscoder)

        self.conversationByIDTranscoder = ConversationByIDTranscoder(context: managedObjectContext)
        self.conversationByIDSync = IdentifierObjectSync(managedObjectContext: managedObjectContext,
                                                         transcoder: conversationByIDTranscoder)

        self.conversationByQualifiedIDTranscoder = ConversationByQualifiedIDTranscoder(context: managedObjectContext)
        self.conversationByQualifiedIDSync = IdentifierObjectSync(managedObjectContext: managedObjectContext,
                                                                  transcoder: conversationByQualifiedIDTranscoder)

        self.updateSync = KeyPathObjectSync(entityName: ZMConversation.entityName(), \.needsToBeUpdatedFromBackend)

        self.addParticipantActionHandler = AddParticipantActionHandler(context: managedObjectContext)
        self.removeParticipantActionHandler = RemoveParticipantActionHandler(context: managedObjectContext)

        self.actionSync = EntityActionSync(actionHandlers: [
            addParticipantActionHandler,
            removeParticipantActionHandler
        ])

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        self.configuration = [.allowsRequestsWhileOnline,
                              .allowsRequestsDuringSlowSync]

        self.updateSync.transcoder = self
        self.conversationByIDListSync.delegate = self
        self.conversationByQualifiedIDListSync.delegate = self
    }

    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        if syncProgress.currentSyncPhase == .fetchingConversations {
            fetchAllConversations()
        }

        return requestGenerators.nextRequest()
    }

    func fetch(_ converations: Set<ZMConversation>) {
        if conversationByQualifiedIDSync.isAvailable, let identifiers = converations.qualifiedIDs {
            conversationByQualifiedIDSync.sync(identifiers: identifiers)
        } else {
            conversationByIDSync.sync(identifiers: converations.compactMap(\.remoteIdentifier))
        }
    }

    func fetchAllConversations() {
        guard !isFetchingAllConversations else { return }

        isFetchingAllConversations = true

        // Mark all existing conversationt to be re-fetched since they might have
        // been deleted. If not the flag will be reset after syncing the conversations
        // with the BE and no extra work will be done.
        ZMUser.selfUser(in: managedObjectContext).conversations.forEach {
            $0.needsToBeUpdatedFromBackend = true
        }

        if useFederationEndpoint {
            conversationQualifiedIDsSync.fetch { [weak self] (result) in
                switch result {
                case .success(let qualifiedConversationIDList):
                    self?.conversationByQualifiedIDListSync.sync(identifiers: qualifiedConversationIDList.conversations)
                case .failure:
                    self?.syncProgress.failCurrentSyncPhase(phase: .fetchingConversations)
                }
            }
        } else {
            conversationIDsSync.fetch { [weak self] (result) in
                switch result {
                case .success(let conversationIDList):
                    self?.conversationByIDListSync.sync(identifiers: conversationIDList.conversations)
                case .failure:
                    self?.syncProgress.failCurrentSyncPhase(phase: .fetchingConversations)
                }
            }
        }
    }

    public var requestGenerators: [ZMRequestGenerator] {
        if syncProgress.currentSyncPhase == .fetchingConversations {
            return [conversationIDsSync,
                    conversationQualifiedIDsSync,
                    conversationByIDListSync,
                    conversationByQualifiedIDListSync]
        } else {
            return [conversationByIDSync,
                    conversationByQualifiedIDSync,
                    insertSync,
                    modifiedSync,
                    actionSync]
        }

    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [updateSync, insertSync, modifiedSync]
    }
    
}

extension ConversationRequestStrategy: ZMEventConsumer {

    public func processEvents(_ events: [ZMUpdateEvent],
                              liveEvents: Bool,
                              prefetchResult: ZMFetchRequestBatchResult?) {
        for event in events {
            guard
                eventsToProcess.contains(event.type),
                let payloadAsDictionary = event.payload as? [String: Any],
                let payloadData = try? JSONSerialization.data(withJSONObject: payloadAsDictionary, options: [])
            else {
                continue
            }

            switch event.type {
            case .conversationCreate:
                let conversationEvent = Payload.ConversationEvent<Payload.Conversation>(payloadData)
                conversationEvent?.process(in: managedObjectContext, originalEvent: event)

            case .conversationDelete:
                let conversationEvent = Payload.ConversationEvent<Payload.UpdateConversationDeleted>(payloadData)
                conversationEvent?.process(in: managedObjectContext, originalEvent: event)

            case .conversationMemberLeave:
                let conversationEvent = Payload.ConversationEvent<Payload.UpdateConverationMemberLeave>(payloadData)
                conversationEvent?.process(in: managedObjectContext, originalEvent: event)

            case .conversationMemberJoin:
                let conversationEvent = Payload.ConversationEvent<Payload.UpdateConverationMemberJoin>(payloadData)
                conversationEvent?.process(in: managedObjectContext, originalEvent: event)

            case .conversationRename:
                let conversationEvent = Payload.ConversationEvent<Payload.UpdateConversationName>(payloadData)
                conversationEvent?.process(in: managedObjectContext, originalEvent: event)

            case .conversationMemberUpdate:
                let conversationEvent = Payload.ConversationEvent<Payload.ConversationMember>(payloadData)
                conversationEvent?.process(in: managedObjectContext, originalEvent: event)

            case .conversationAccessModeUpdate:
                let conversationEvent = Payload.ConversationEvent<Payload.UpdateConversationAccess>(payloadData)
                conversationEvent?.process(in: managedObjectContext, originalEvent: event)

            case .conversationMessageTimerUpdate:
                let conversationEvent = Payload.ConversationEvent<Payload.UpdateConversationMessageTimer>(payloadData)
                conversationEvent?.process(in: managedObjectContext, originalEvent: event)

            case .conversationReceiptModeUpdate:
                let conversationEvent = Payload.ConversationEvent<Payload.UpdateConversationReceiptMode>(payloadData)
                conversationEvent?.process(in: managedObjectContext, originalEvent: event)

            case .conversationConnectRequest:
                let conversationEvent = Payload.ConversationEvent<Payload.UpdateConversationConnectionRequest>(payloadData)
                conversationEvent?.process(in: managedObjectContext, originalEvent: event)

            default:
                break
            }
        }
    }
}

extension ConversationRequestStrategy: KeyPathObjectSyncTranscoder {

    typealias T = ZMConversation

    func synchronize(_ object: ZMConversation, completion: @escaping () -> Void) {
        if conversationByQualifiedIDSync.isAvailable, let identifiers = object.qualifiedID {
            conversationByQualifiedIDSync.sync(identifiers: Set(arrayLiteral: identifiers))
        } else if let identifier = object.remoteIdentifier {
            conversationByIDSync.sync(identifiers: Set(arrayLiteral: identifier))
        }
    }

    func cancel(_ object: ZMConversation) {
        if let identifier = object.qualifiedID {
            conversationByQualifiedIDSync.cancel(identifiers: Set(arrayLiteral: identifier))
        }
        if let identifier = object.remoteIdentifier {
            conversationByIDSync.cancel(identifiers: Set(arrayLiteral: identifier))
        }
    }

}

extension ConversationRequestStrategy: IdentifierObjectSyncDelegate {

    public func didFinishSyncingAllObjects() {
        guard
            syncProgress.currentSyncPhase == .fetchingConversations,
            conversationIDsSync.status == .done,
            conversationQualifiedIDsSync.status == .done,
            !conversationByIDListSync.isSyncing,
            !conversationByQualifiedIDListSync.isSyncing
        else {
            return
        }

        syncProgress.finishCurrentSyncPhase(phase: .fetchingConversations)
        isFetchingAllConversations = false
    }

    public func didFailToSyncAllObjects() {
        if syncProgress.currentSyncPhase == .fetchingConversations {
            syncProgress.failCurrentSyncPhase(phase: .fetchingConversations)
            isFetchingAllConversations = false
        }
    }

}

extension ConversationRequestStrategy: ZMUpstreamTranscoder {

    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        return false
    }

    public func shouldCreateRequest(toSyncObject managedObject: ZMManagedObject,
                                    forKeys keys: Set<String>,
                                    withSync sync: Any) -> Bool {
        guard (sync as AnyObject) === modifiedSync else {
            return true
        }

        guard let conversation = managedObject as? ZMConversation else {
            return false
        }

        var remainingKeys = keys

        if keys.contains(ZMConversationUserDefinedNameKey) && conversation.userDefinedName == nil {
            conversation.resetLocallyModifiedKeys(Set(arrayLiteral: ZMConversationUserDefinedNameKey))
            remainingKeys.remove(ZMConversationUserDefinedNameKey)
        }

        if remainingKeys.count < keys.count {
            contextChangeTrackers.forEach({ $0.objectsDidChange(Set(arrayLiteral: conversation)) })
            managedObjectContext.enqueueDelayedSave()
        }

        return remainingKeys.count > 0
    }

    public func shouldRetryToSyncAfterFailed(toUpdate managedObject: ZMManagedObject,
                                             request upstreamRequest: ZMUpstreamRequest,
                                             response: ZMTransportResponse,
                                             keysToParse keys: Set<String>) -> Bool {

        guard let newConversation = managedObject as? ZMConversation else {
            return false
        }

        if let responseFailure = Payload.ResponseFailure(response, decoder: .defaultDecoder),
           responseFailure.code == 412 && responseFailure.label == .missingLegalholdConsent {
            newConversation.notifyMissingLegalHoldConsent()
        }

        return false
    }

    public func updateInsertedObject(_ managedObject: ZMManagedObject,
                                     request upstreamRequest: ZMUpstreamRequest,
                                     response: ZMTransportResponse) {

        guard
            let newConversation = managedObject as? ZMConversation,
            let rawData = response.rawData,
            let payload = Payload.Conversation(rawData, decoder: .defaultDecoder),
            let conversationID = payload.id
        else {
            Logging.network.warn("Can't process response, aborting.")
            return
        }

        var deletedDuplicate = false
        if let existingConversation = ZMConversation.fetch(with: conversationID,
                                                           domain: payload.qualifiedID?.domain,
                                                           in: managedObjectContext) {
            managedObjectContext.delete(existingConversation)
            deletedDuplicate = true
        }

        newConversation.remoteIdentifier = conversationID
        payload.updateOrCreate(in: managedObjectContext)
        newConversation.needsToBeUpdatedFromBackend = deletedDuplicate
    }

    public func updateUpdatedObject(_ managedObject: ZMManagedObject,
                                    requestUserInfo: [AnyHashable : Any]? = nil,
                                    response: ZMTransportResponse, keysToParse: Set<String>) -> Bool {

        guard
            keysToParse.contains(ZMConversationUserDefinedNameKey),
            let payload = response.payload
        else {
            return false
        }

        if let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil) {
            processEvents([event], liveEvents: true, prefetchResult: nil)
        }

        return false
    }

    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        return nil
    }

    public func request(forUpdating managedObject: ZMManagedObject,
                        forKeys keys: Set<String>) -> ZMUpstreamRequest? {
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
            if useFederationEndpoint {
                guard let domain = conversation.domain else {
                    return nil
                }
                request = ZMTransportRequest(path: "/conversations/\(domain)/\(conversationID)/name",
                                             method: .methodPUT,
                                             payload: payloadAsString as ZMTransportData?)
            } else {
                request = ZMTransportRequest(path: "/conversations/\(conversationID)",
                                             method: .methodPUT,
                                             payload: payloadAsString as ZMTransportData?)
            }

            return ZMUpstreamRequest(keys: Set(arrayLiteral: ZMConversationUserDefinedNameKey),
                                     transportRequest: request)
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
            if (useFederationEndpoint) {
                guard let domain = conversation.domain else {
                    return nil
                }
                request = ZMTransportRequest(path: "/conversations/\(domain)/\(conversationID)/self",
                                             method: .methodPUT,
                                             payload: payloadAsString as ZMTransportData?)
            } else {
                request = ZMTransportRequest(path: "/conversations/\(conversationID)/self",
                                             method: .methodPUT,
                                             payload: payloadAsString as ZMTransportData?)
            }

            let changedKeys = keys.intersection([ZMConversationArchivedChangedTimeStampKey,
                                                 ZMConversationSilencedChangedTimeStampKey])

            return ZMUpstreamRequest(keys: changedKeys,
                                     transportRequest: request)

        }

        return nil
    }

    public func request(forInserting managedObject: ZMManagedObject,
                        forKeys keys: Set<String>?) -> ZMUpstreamRequest? {

        guard let conversation = managedObject as? ZMConversation else {
            return nil
        }

        let payload = Payload.NewConversation(conversation)

        guard
            let payloadData = payload.payloadData(encoder: .defaultEncoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            return nil
        }

        let request = ZMTransportRequest(path: "/conversations",
                                         method: .methodPOST,
                                         payload: payloadAsString as ZMTransportData?)

        return ZMUpstreamRequest(transportRequest: request)
    }

}

class ConversationByIDTranscoder: IdentifierObjectSyncTranscoder {
    public typealias T = UUID

    var fetchLimit: Int = 1
    var isAvailable: Bool = true

    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func request(for identifiers: Set<UUID>) -> ZMTransportRequest? {
        guard let converationID = identifiers.first.map({ $0.transportString() }) else { return nil }

        // GET /conversations/<UUID>
        return ZMTransportRequest(getFromPath: "/conversations/\(converationID)")
    }

    func didReceive(response: ZMTransportResponse, for identifiers: Set<UUID>) {

        guard response.result != .permanentError else {
            if response.httpStatus == 404 {
                deleteConversations(identifiers)
                return
            }

            if response.httpStatus == 403 {
                removeSelfUser(identifiers)
                return
            }

            markConversationsAsFetched(identifiers)
            return
        }
        

        guard
            let rawData = response.rawData,
            let payload = Payload.Conversation(rawData, decoder: decoder)
        else {
            Logging.network.warn("Can't process response, aborting.")
            return
        }

        payload.updateOrCreate(in: context)
    }

    private func deleteConversations(_ conversations: Set<UUID>) {
        for conversationID in conversations {
            guard
                let conversation = ZMConversation.fetch(with: conversationID, domain: nil, in: context),
                conversation.conversationType == .group
            else {
                continue
            }
            context.delete(conversation)
        }
    }

    private func removeSelfUser(_ conversations: Set<UUID>) {
        for conversationID in conversations {
            guard
                let conversation = ZMConversation.fetch(with: conversationID, domain: nil, in: context),
                conversation.conversationType == .group,
                conversation.isSelfAnActiveMember
            else {
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
    var isAvailable: Bool = true

    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func request(for identifiers: Set<QualifiedID>) -> ZMTransportRequest? {
        guard
            let conversationID = identifiers.first.map({ $0.uuid.transportString() }),
            let domain = identifiers.first?.domain
        else {
            return nil
        }

        // GET /conversations/domain/<UUID>
        return ZMTransportRequest(getFromPath: "/conversations/\(domain)/\(conversationID)")
    }

    func didReceive(response: ZMTransportResponse, for identifiers: Set<QualifiedID>) {

        guard response.result != .permanentError else {
            markConversationsAsFetched(identifiers)

            if response.httpStatus == 404 {
                deleteConversations(identifiers)
                return
            }

            if response.httpStatus == 403 {
                removeSelfUser(identifiers)
                return
            }
            return
        }


        guard
            let rawData = response.rawData,
            let payload = Payload.Conversation(rawData, decoder: decoder)
        else {
            Logging.network.warn("Can't process response, aborting.")
            return
        }

        payload.updateOrCreate(in: context)
    }

    private func deleteConversations(_ conversations: Set<QualifiedID>) {
        for qualifiedID in conversations {
            guard
                let conversation = ZMConversation.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: context),
                conversation.conversationType == .group
            else {

                continue
            }
            context.delete(conversation)
        }
    }

    private func removeSelfUser(_ conversations: Set<QualifiedID>) {
        for qualifiedID in conversations {
            guard
                let conversation = ZMConversation.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: context),
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

class ConversationByIDListTranscoder: IdentifierObjectSyncTranscoder {

    public typealias T = UUID

    var fetchLimit: Int = 32
    var isAvailable: Bool = true

    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func request(for identifiers: Set<UUID>) -> ZMTransportRequest? {
        // GET /conversations?ids=?
        let converationIDs = identifiers.map({ $0.transportString() }).joined(separator: ",")
        return ZMTransportRequest(getFromPath: "/conversations?ids=\(converationIDs)")
    }

    func didReceive(response: ZMTransportResponse, for identifiers: Set<UUID>) {

        guard
            let rawData = response.rawData,
            let payload = Payload.ConversationList(rawData, decoder: decoder)
        else {
            Logging.network.warn("Can't process response, aborting.")
            return
        }

        payload.updateOrCreateConverations(in: context)

        let missingIdentifiers = identifiers.subtracting(payload.conversations.compactMap(\.id))
        queryStatusForMissingConversations(missingIdentifiers)
    }

    /// Query the backend if a converation is deleted or the self user has been removed
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
    var isAvailable: Bool = true

    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func request(for identifiers: Set<QualifiedID>) -> ZMTransportRequest? {
        // GET /conversations?ids=?

        guard
            let payloadData = Payload.QualifiedUserIDList(qualifiedIDs: Array(identifiers)).payloadData(encoder: encoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            return nil
        }

        return ZMTransportRequest(path: "/conversations/list/v2", method: .methodPOST, payload: payloadAsString as ZMTransportData)
    }

    func didReceive(response: ZMTransportResponse, for identifiers: Set<QualifiedID>) {

        guard
            let rawData = response.rawData,
            let payload = Payload.QualifiedConversationList(rawData, decoder: decoder)
        else {
            Logging.network.warn("Can't process response, aborting.")
            return
        }

        payload.updateOrCreateConverations(in: context)

        queryStatusForMissingConversations(payload.notFound)
        queryStatusForFailedConversations(payload.failed)
    }

    /// Query the backend if a converation is deleted or the self user has been removed
    private func queryStatusForMissingConversations(_ conversations: [QualifiedID]) {
        for qualifiedID in conversations {
            let conversation = ZMConversation.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: context)
            conversation?.needsToBeUpdatedFromBackend = true
        }
    }

    /// Query the backend again if a converation couldn't be fetched
    private func queryStatusForFailedConversations(_ conversations: [QualifiedID]) {

        for qualifiedID in conversations {
            let conversation = ZMConversation.fetchOrCreate(with: qualifiedID.uuid, domain: qualifiedID.domain, in: context)
            conversation.needsToBeUpdatedFromBackend = true
        }
    }

}
