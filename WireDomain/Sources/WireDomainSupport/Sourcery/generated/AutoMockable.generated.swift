// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
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

// swiftlint:disable superfluous_disable_command
// swiftlint:disable vertical_whitespace
// swiftlint:disable line_length
// swiftlint:disable variable_name


import GenericMessageProtocol
import WireNetwork
import WireDataModel
import WireDomainPackage
import WireCoreCrypto
import Combine

@testable import WireDomain
























class MockAppExtensionPushChannelCoordinatorProtocol: AppExtensionPushChannelCoordinatorProtocol {

    // MARK: - Life cycle



    // MARK: - listenForYieldRequests

    var listenForYieldRequests_Invocations: [Void] = []
    var listenForYieldRequests_MockMethod: (() async -> YieldRequest)?
    var listenForYieldRequests_MockValue: YieldRequest?

    func listenForYieldRequests() async -> YieldRequest {
        listenForYieldRequests_Invocations.append(())

        if let mock = listenForYieldRequests_MockMethod {
            return await mock()
        } else if let mock = listenForYieldRequests_MockValue {
            return mock
        } else {
            fatalError("no mock for `listenForYieldRequests`")
        }
    }

}

public class MockAssetTransferStateResolverProtocol: AssetTransferStateResolverProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - resolveTransferState

    public var resolveTransferStateAssetMessageGenericMessageContext_Invocations: [(assetMessage: ZMAssetClientMessage, genericMessage: GenericMessage, context: NSManagedObjectContext)] = []
    public var resolveTransferStateAssetMessageGenericMessageContext_MockMethod: ((ZMAssetClientMessage, GenericMessage, NSManagedObjectContext) -> Void)?

    public func resolveTransferState(assetMessage: ZMAssetClientMessage, genericMessage: GenericMessage, context: NSManagedObjectContext) {
        resolveTransferStateAssetMessageGenericMessageContext_Invocations.append((assetMessage: assetMessage, genericMessage: genericMessage, context: context))

        guard let mock = resolveTransferStateAssetMessageGenericMessageContext_MockMethod else {
            fatalError("no mock for `resolveTransferStateAssetMessageGenericMessageContext`")
        }

        mock(assetMessage, genericMessage, context)
    }

}

public class MockBackendConfigLocalStoreProtocol: BackendConfigLocalStoreProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - isMLSEnabled

    public var isMLSEnabled: Bool {
        get { return underlyingIsMLSEnabled }
        set(value) { underlyingIsMLSEnabled = value }
    }

    public var underlyingIsMLSEnabled: Bool!


    // MARK: - storeIsMLSEnabledStatus

    public var storeIsMLSEnabledStatusNewValue_Invocations: [Bool] = []
    public var storeIsMLSEnabledStatusNewValue_MockMethod: ((Bool) -> Void)?

    public func storeIsMLSEnabledStatus(newValue: Bool) {
        storeIsMLSEnabledStatusNewValue_Invocations.append(newValue)

        guard let mock = storeIsMLSEnabledStatusNewValue_MockMethod else {
            fatalError("no mock for `storeIsMLSEnabledStatusNewValue`")
        }

        mock(newValue)
    }

}

class MockBackendConfigRepositoryProtocol: BackendConfigRepositoryProtocol {

    // MARK: - Life cycle



    // MARK: - pullMLSBackendStatus

    var pullMLSBackendStatus_Invocations: [Void] = []
    var pullMLSBackendStatus_MockMethod: (() async -> Void)?

    func pullMLSBackendStatus() async {
        pullMLSBackendStatus_Invocations.append(())

        guard let mock = pullMLSBackendStatus_MockMethod else {
            fatalError("no mock for `pullMLSBackendStatus`")
        }

        await mock()
    }

}

public class MockCalculateSupportedProtocolsUseCaseProtocol: CalculateSupportedProtocolsUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invoke_Invocations: [Void] = []
    public var invoke_MockMethod: (() async -> Set<WireNetwork.MessageProtocol>)?
    public var invoke_MockValue: Set<WireNetwork.MessageProtocol>?

    public func invoke() async -> Set<WireNetwork.MessageProtocol> {
        invoke_Invocations.append(())

        if let mock = invoke_MockMethod {
            return await mock()
        } else if let mock = invoke_MockValue {
            return mock
        } else {
            fatalError("no mock for `invoke`")
        }
    }

}

public class MockConnectionsLocalStoreProtocol: ConnectionsLocalStoreProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - storeConnection

    public var storeConnection_Invocations: [ConnectionInfo] = []
    public var storeConnection_MockError: Error?
    public var storeConnection_MockMethod: ((ConnectionInfo) async throws -> Void)?

    public func storeConnection(_ connectionInfo: ConnectionInfo) async throws {
        storeConnection_Invocations.append(connectionInfo)

        if let error = storeConnection_MockError {
            throw error
        }

        guard let mock = storeConnection_MockMethod else {
            fatalError("no mock for `storeConnection`")
        }

        try await mock(connectionInfo)
    }

    // MARK: - markConversationAsNeedUpdatedFromBackend

    public var markConversationAsNeedUpdatedFromBackend_Invocations: [ConnectionInfo] = []
    public var markConversationAsNeedUpdatedFromBackend_MockError: Error?
    public var markConversationAsNeedUpdatedFromBackend_MockMethod: ((ConnectionInfo) async throws -> Void)?

    public func markConversationAsNeedUpdatedFromBackend(_ connectionInfo: ConnectionInfo) async throws {
        markConversationAsNeedUpdatedFromBackend_Invocations.append(connectionInfo)

        if let error = markConversationAsNeedUpdatedFromBackend_MockError {
            throw error
        }

        guard let mock = markConversationAsNeedUpdatedFromBackend_MockMethod else {
            fatalError("no mock for `markConversationAsNeedUpdatedFromBackend`")
        }

        try await mock(connectionInfo)
    }

}

public class MockConnectionsRepositoryProtocol: ConnectionsRepositoryProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - pullConnections

    public var pullConnections_Invocations: [Void] = []
    public var pullConnections_MockError: Error?
    public var pullConnections_MockMethod: (() async throws -> Void)?

    public func pullConnections() async throws {
        pullConnections_Invocations.append(())

        if let error = pullConnections_MockError {
            throw error
        }

        guard let mock = pullConnections_MockMethod else {
            fatalError("no mock for `pullConnections`")
        }

        try await mock()
    }

    // MARK: - updateConnection

    public var updateConnection_Invocations: [Connection] = []
    public var updateConnection_MockError: Error?
    public var updateConnection_MockMethod: ((Connection) async throws -> Void)?

    public func updateConnection(_ connection: Connection) async throws {
        updateConnection_Invocations.append(connection)

        if let error = updateConnection_MockError {
            throw error
        }

        guard let mock = updateConnection_MockMethod else {
            fatalError("no mock for `updateConnection`")
        }

        try await mock(connection)
    }

    // MARK: - scheduleToSyncConversation

    public var scheduleToSyncConversationWith_Invocations: [Connection] = []
    public var scheduleToSyncConversationWith_MockError: Error?
    public var scheduleToSyncConversationWith_MockMethod: ((Connection) async throws -> Void)?

    public func scheduleToSyncConversation(with connection: Connection) async throws {
        scheduleToSyncConversationWith_Invocations.append(connection)

        if let error = scheduleToSyncConversationWith_MockError {
            throw error
        }

        guard let mock = scheduleToSyncConversationWith_MockMethod else {
            fatalError("no mock for `scheduleToSyncConversationWith`")
        }

        try await mock(connection)
    }

}

class MockConversationAudioMessageNotificationBuilderProtocol: ConversationAudioMessageNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentConversationIDSenderID_Invocations: [(conversationID: ConversationID, senderID: UserID)] = []
    var buildContentConversationIDSenderID_MockMethod: ((ConversationID, UserID) async -> UserNotification)?
    var buildContentConversationIDSenderID_MockValue: UserNotification?

    func buildContent(conversationID: ConversationID, senderID: UserID) async -> UserNotification {
        buildContentConversationIDSenderID_Invocations.append((conversationID: conversationID, senderID: senderID))

        if let mock = buildContentConversationIDSenderID_MockMethod {
            return await mock(conversationID, senderID)
        } else if let mock = buildContentConversationIDSenderID_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentConversationIDSenderID`")
        }
    }

}

class MockConversationCallingEventNotificationBuilderProtocol: ConversationCallingEventNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentCallingAtConversationIDSenderID_Invocations: [(calling: Calling, time: Date?, conversationID: ConversationID, senderID: UserID)] = []
    var buildContentCallingAtConversationIDSenderID_MockMethod: ((Calling, Date?, ConversationID, UserID) async -> UserNotification?)?
    var buildContentCallingAtConversationIDSenderID_MockValue: UserNotification??

    func buildContent(calling: Calling, at time: Date?, conversationID: ConversationID, senderID: UserID) async -> UserNotification? {
        buildContentCallingAtConversationIDSenderID_Invocations.append((calling: calling, time: time, conversationID: conversationID, senderID: senderID))

        if let mock = buildContentCallingAtConversationIDSenderID_MockMethod {
            return await mock(calling, time, conversationID, senderID)
        } else if let mock = buildContentCallingAtConversationIDSenderID_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentCallingAtConversationIDSenderID`")
        }
    }

}

class MockConversationCreateEventNotificationBuilderProtocol: ConversationCreateEventNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentEvent_Invocations: [ConversationCreateEvent] = []
    var buildContentEvent_MockMethod: ((ConversationCreateEvent) async -> UserNotification?)?
    var buildContentEvent_MockValue: UserNotification??

    func buildContent(event: ConversationCreateEvent) async -> UserNotification? {
        buildContentEvent_Invocations.append(event)

        if let mock = buildContentEvent_MockMethod {
            return await mock(event)
        } else if let mock = buildContentEvent_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentEvent`")
        }
    }

}

class MockConversationDeleteEventNotificationBuilderProtocol: ConversationDeleteEventNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentEvent_Invocations: [ConversationDeleteEvent] = []
    var buildContentEvent_MockMethod: ((ConversationDeleteEvent) async -> UserNotification?)?
    var buildContentEvent_MockValue: UserNotification??

    func buildContent(event: ConversationDeleteEvent) async -> UserNotification? {
        buildContentEvent_Invocations.append(event)

        if let mock = buildContentEvent_MockMethod {
            return await mock(event)
        } else if let mock = buildContentEvent_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentEvent`")
        }
    }

}

class MockConversationEphemeralMessageNotificationBuilderProtocol: ConversationEphemeralMessageNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentEphemeralConversationIDSenderID_Invocations: [(ephemeral: Ephemeral, conversationID: ConversationID, senderID: UserID)] = []
    var buildContentEphemeralConversationIDSenderID_MockMethod: ((Ephemeral, ConversationID, UserID) async -> UserNotification?)?
    var buildContentEphemeralConversationIDSenderID_MockValue: UserNotification??

    func buildContent(ephemeral: Ephemeral, conversationID: ConversationID, senderID: UserID) async -> UserNotification? {
        buildContentEphemeralConversationIDSenderID_Invocations.append((ephemeral: ephemeral, conversationID: conversationID, senderID: senderID))

        if let mock = buildContentEphemeralConversationIDSenderID_MockMethod {
            return await mock(ephemeral, conversationID, senderID)
        } else if let mock = buildContentEphemeralConversationIDSenderID_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentEphemeralConversationIDSenderID`")
        }
    }

}

class MockConversationEventNotificationBuilderProtocol: ConversationEventNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentEvent_Invocations: [ConversationEvent] = []
    var buildContentEvent_MockError: Error?
    var buildContentEvent_MockMethod: ((ConversationEvent) async throws -> [UserNotification]?)?
    var buildContentEvent_MockValue: [UserNotification]??

    func buildContent(event: ConversationEvent) async throws -> [UserNotification]? {
        buildContentEvent_Invocations.append(event)

        if let error = buildContentEvent_MockError {
            throw error
        }

        if let mock = buildContentEvent_MockMethod {
            return try await mock(event)
        } else if let mock = buildContentEvent_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentEvent`")
        }
    }

}

class MockConversationEventProcessorProtocol: ConversationEventProcessorProtocol {

    // MARK: - Life cycle



    // MARK: - processEvent

    var processEvent_Invocations: [ConversationEvent] = []
    var processEvent_MockError: Error?
    var processEvent_MockMethod: ((ConversationEvent) async throws -> Void)?

    func processEvent(_ event: ConversationEvent) async throws {
        processEvent_Invocations.append(event)

        if let error = processEvent_MockError {
            throw error
        }

        guard let mock = processEvent_MockMethod else {
            fatalError("no mock for `processEvent`")
        }

        try await mock(event)
    }

}

class MockConversationFileUploadMessageNotificationBuilderProtocol: ConversationFileUploadMessageNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentConversationIDSenderID_Invocations: [(conversationID: ConversationID, senderID: UserID)] = []
    var buildContentConversationIDSenderID_MockMethod: ((ConversationID, UserID) async -> UserNotification)?
    var buildContentConversationIDSenderID_MockValue: UserNotification?

    func buildContent(conversationID: ConversationID, senderID: UserID) async -> UserNotification {
        buildContentConversationIDSenderID_Invocations.append((conversationID: conversationID, senderID: senderID))

        if let mock = buildContentConversationIDSenderID_MockMethod {
            return await mock(conversationID, senderID)
        } else if let mock = buildContentConversationIDSenderID_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentConversationIDSenderID`")
        }
    }

}

class MockConversationHiddenMessageNotificationBuilderProtocol: ConversationHiddenMessageNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentConversationIDSenderID_Invocations: [(conversationID: ConversationID, senderID: UserID)] = []
    var buildContentConversationIDSenderID_MockMethod: ((ConversationID, UserID) async -> UserNotification)?
    var buildContentConversationIDSenderID_MockValue: UserNotification?

    func buildContent(conversationID: ConversationID, senderID: UserID) async -> UserNotification {
        buildContentConversationIDSenderID_Invocations.append((conversationID: conversationID, senderID: senderID))

        if let mock = buildContentConversationIDSenderID_MockMethod {
            return await mock(conversationID, senderID)
        } else if let mock = buildContentConversationIDSenderID_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentConversationIDSenderID`")
        }
    }

}

class MockConversationImageMessageNotificationBuilderProtocol: ConversationImageMessageNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentConversationIDSenderID_Invocations: [(conversationID: ConversationID, senderID: UserID)] = []
    var buildContentConversationIDSenderID_MockMethod: ((ConversationID, UserID) async -> UserNotification)?
    var buildContentConversationIDSenderID_MockValue: UserNotification?

    func buildContent(conversationID: ConversationID, senderID: UserID) async -> UserNotification {
        buildContentConversationIDSenderID_Invocations.append((conversationID: conversationID, senderID: senderID))

        if let mock = buildContentConversationIDSenderID_MockMethod {
            return await mock(conversationID, senderID)
        } else if let mock = buildContentConversationIDSenderID_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentConversationIDSenderID`")
        }
    }

}

public class MockConversationLabelsLocalStoreProtocol: ConversationLabelsLocalStoreProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - setLabels

    public var setLabels_Invocations: [[ConversationLabelInfo]] = []
    public var setLabels_MockError: Error?
    public var setLabels_MockMethod: (([ConversationLabelInfo]) async throws -> Void)?

    public func setLabels(_ labels: [ConversationLabelInfo]) async throws {
        setLabels_Invocations.append(labels)

        if let error = setLabels_MockError {
            throw error
        }

        guard let mock = setLabels_MockMethod else {
            fatalError("no mock for `setLabels`")
        }

        try await mock(labels)
    }

}

public class MockConversationLabelsRepositoryProtocol: ConversationLabelsRepositoryProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - pullConversationLabels

    public var pullConversationLabels_Invocations: [Void] = []
    public var pullConversationLabels_MockError: Error?
    public var pullConversationLabels_MockMethod: (() async throws -> Void)?

    public func pullConversationLabels() async throws {
        pullConversationLabels_Invocations.append(())

        if let error = pullConversationLabels_MockError {
            throw error
        }

        guard let mock = pullConversationLabels_MockMethod else {
            fatalError("no mock for `pullConversationLabels`")
        }

        try await mock()
    }

    // MARK: - updateConversationLabels

    public var updateConversationLabels_Invocations: [[ConversationLabel]] = []
    public var updateConversationLabels_MockError: Error?
    public var updateConversationLabels_MockMethod: (([ConversationLabel]) async throws -> Void)?

    public func updateConversationLabels(_ conversationLabels: [ConversationLabel]) async throws {
        updateConversationLabels_Invocations.append(conversationLabels)

        if let error = updateConversationLabels_MockError {
            throw error
        }

        guard let mock = updateConversationLabels_MockMethod else {
            fatalError("no mock for `updateConversationLabels`")
        }

        try await mock(conversationLabels)
    }

}

public class MockConversationLocalStoreProtocol: ConversationLocalStoreProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - qualifiedID

    public var qualifiedIDFor_Invocations: [ZMConversation] = []
    public var qualifiedIDFor_MockMethod: ((ZMConversation) async -> QualifiedID?)?
    public var qualifiedIDFor_MockValue: QualifiedID??

    public func qualifiedID(for conversation: ZMConversation) async -> QualifiedID? {
        qualifiedIDFor_Invocations.append(conversation)

        if let mock = qualifiedIDFor_MockMethod {
            return await mock(conversation)
        } else if let mock = qualifiedIDFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `qualifiedIDFor`")
        }
    }

    // MARK: - fetchOrCreateConversation

    public var fetchOrCreateConversationIdDomain_Invocations: [(id: UUID, domain: String?)] = []
    public var fetchOrCreateConversationIdDomain_MockMethod: ((UUID, String?) async -> ZMConversation)?
    public var fetchOrCreateConversationIdDomain_MockValue: ZMConversation?

    public func fetchOrCreateConversation(id: UUID, domain: String?) async -> ZMConversation {
        fetchOrCreateConversationIdDomain_Invocations.append((id: id, domain: domain))

        if let mock = fetchOrCreateConversationIdDomain_MockMethod {
            return await mock(id, domain)
        } else if let mock = fetchOrCreateConversationIdDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateConversationIdDomain`")
        }
    }

    // MARK: - storeConversation

    public var storeConversationTimestampIsFederationEnabledIsMLSEnabled_Invocations: [(conversation: WireDomain.Conversation, timestamp: Date, isFederationEnabled: Bool, isMLSEnabled: Bool)] = []
    public var storeConversationTimestampIsFederationEnabledIsMLSEnabled_MockMethod: ((WireDomain.Conversation, Date, Bool, Bool) async -> Void)?

    public func storeConversation(_ conversation: WireDomain.Conversation, timestamp: Date, isFederationEnabled: Bool, isMLSEnabled: Bool) async {
        storeConversationTimestampIsFederationEnabledIsMLSEnabled_Invocations.append((conversation: conversation, timestamp: timestamp, isFederationEnabled: isFederationEnabled, isMLSEnabled: isMLSEnabled))

        guard let mock = storeConversationTimestampIsFederationEnabledIsMLSEnabled_MockMethod else {
            fatalError("no mock for `storeConversationTimestampIsFederationEnabledIsMLSEnabled`")
        }

        await mock(conversation, timestamp, isFederationEnabled, isMLSEnabled)
    }

    // MARK: - storeConversation

    public var storeConversationNeedsBackendUpdateConversationIDConversationDomain_Invocations: [(needsBackendUpdate: Bool, conversationID: UUID, conversationDomain: String)] = []
    public var storeConversationNeedsBackendUpdateConversationIDConversationDomain_MockMethod: ((Bool, UUID, String) async -> Void)?

    public func storeConversation(needsBackendUpdate: Bool, conversationID: UUID, conversationDomain: String) async {
        storeConversationNeedsBackendUpdateConversationIDConversationDomain_Invocations.append((needsBackendUpdate: needsBackendUpdate, conversationID: conversationID, conversationDomain: conversationDomain))

        guard let mock = storeConversationNeedsBackendUpdateConversationIDConversationDomain_MockMethod else {
            fatalError("no mock for `storeConversationNeedsBackendUpdateConversationIDConversationDomain`")
        }

        await mock(needsBackendUpdate, conversationID, conversationDomain)
    }

    // MARK: - storeFailedConversation

    public var storeFailedConversationConversationIDConversationDomain_Invocations: [(conversationID: UUID, conversationDomain: String)] = []
    public var storeFailedConversationConversationIDConversationDomain_MockMethod: ((UUID, String) async -> Void)?

    public func storeFailedConversation(conversationID: UUID, conversationDomain: String) async {
        storeFailedConversationConversationIDConversationDomain_Invocations.append((conversationID: conversationID, conversationDomain: conversationDomain))

        guard let mock = storeFailedConversationConversationIDConversationDomain_MockMethod else {
            fatalError("no mock for `storeFailedConversationConversationIDConversationDomain`")
        }

        await mock(conversationID, conversationDomain)
    }

    // MARK: - createMLSConversation

    public var createMLSConversationConversationIDConversationDomainMlsGroupID_Invocations: [(conversationID: UUID, conversationDomain: String?, mlsGroupID: MLSGroupID)] = []
    public var createMLSConversationConversationIDConversationDomainMlsGroupID_MockMethod: ((UUID, String?, MLSGroupID) async -> Void)?

    public func createMLSConversation(conversationID: UUID, conversationDomain: String?, mlsGroupID: MLSGroupID) async {
        createMLSConversationConversationIDConversationDomainMlsGroupID_Invocations.append((conversationID: conversationID, conversationDomain: conversationDomain, mlsGroupID: mlsGroupID))

        guard let mock = createMLSConversationConversationIDConversationDomainMlsGroupID_MockMethod else {
            fatalError("no mock for `createMLSConversationConversationIDConversationDomainMlsGroupID`")
        }

        await mock(conversationID, conversationDomain, mlsGroupID)
    }

    // MARK: - fetchAllMLSConversations

    public var fetchAllMLSConversationsDomain_Invocations: [String?] = []
    public var fetchAllMLSConversationsDomain_MockError: Error?
    public var fetchAllMLSConversationsDomain_MockMethod: ((String?) async throws -> [ZMConversation])?
    public var fetchAllMLSConversationsDomain_MockValue: [ZMConversation]?

    public func fetchAllMLSConversations(domain: String?) async throws -> [ZMConversation] {
        fetchAllMLSConversationsDomain_Invocations.append(domain)

        if let error = fetchAllMLSConversationsDomain_MockError {
            throw error
        }

        if let mock = fetchAllMLSConversationsDomain_MockMethod {
            return try await mock(domain)
        } else if let mock = fetchAllMLSConversationsDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchAllMLSConversationsDomain`")
        }
    }

    // MARK: - fetchMLSConversation

    public var fetchMLSConversationGroupID_Invocations: [WireDataModel.MLSGroupID] = []
    public var fetchMLSConversationGroupID_MockMethod: ((WireDataModel.MLSGroupID) async -> ZMConversation?)?
    public var fetchMLSConversationGroupID_MockValue: ZMConversation??

    public func fetchMLSConversation(groupID: WireDataModel.MLSGroupID) async -> ZMConversation? {
        fetchMLSConversationGroupID_Invocations.append(groupID)

        if let mock = fetchMLSConversationGroupID_MockMethod {
            return await mock(groupID)
        } else if let mock = fetchMLSConversationGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchMLSConversationGroupID`")
        }
    }

    // MARK: - fetchConversation

    public var fetchConversationIdDomain_Invocations: [(id: UUID, domain: String?)] = []
    public var fetchConversationIdDomain_MockMethod: ((UUID, String?) async -> ZMConversation?)?
    public var fetchConversationIdDomain_MockValue: ZMConversation??

    public func fetchConversation(id: UUID, domain: String?) async -> ZMConversation? {
        fetchConversationIdDomain_Invocations.append((id: id, domain: domain))

        if let mock = fetchConversationIdDomain_MockMethod {
            return await mock(id, domain)
        } else if let mock = fetchConversationIdDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchConversationIdDomain`")
        }
    }

    // MARK: - wipeMLSGroup

    public var wipeMLSGroupGroupID_Invocations: [WireDataModel.MLSGroupID] = []
    public var wipeMLSGroupGroupID_MockError: Error?
    public var wipeMLSGroupGroupID_MockMethod: ((WireDataModel.MLSGroupID) async throws -> Void)?

    public func wipeMLSGroup(groupID: WireDataModel.MLSGroupID) async throws {
        wipeMLSGroupGroupID_Invocations.append(groupID)

        if let error = wipeMLSGroupGroupID_MockError {
            throw error
        }

        guard let mock = wipeMLSGroupGroupID_MockMethod else {
            fatalError("no mock for `wipeMLSGroupGroupID`")
        }

        try await mock(groupID)
    }

    // MARK: - removeParticipantFromAllGroupConversations

    public var removeParticipantFromAllGroupConversationsParticipantIDParticipantDomainDate_Invocations: [(participantID: UUID, participantDomain: String?, date: Date)] = []
    public var removeParticipantFromAllGroupConversationsParticipantIDParticipantDomainDate_MockError: Error?
    public var removeParticipantFromAllGroupConversationsParticipantIDParticipantDomainDate_MockMethod: ((UUID, String?, Date) async throws -> Void)?

    public func removeParticipantFromAllGroupConversations(participantID: UUID, participantDomain: String?, date: Date) async throws {
        removeParticipantFromAllGroupConversationsParticipantIDParticipantDomainDate_Invocations.append((participantID: participantID, participantDomain: participantDomain, date: date))

        if let error = removeParticipantFromAllGroupConversationsParticipantIDParticipantDomainDate_MockError {
            throw error
        }

        guard let mock = removeParticipantFromAllGroupConversationsParticipantIDParticipantDomainDate_MockMethod else {
            fatalError("no mock for `removeParticipantFromAllGroupConversationsParticipantIDParticipantDomainDate`")
        }

        try await mock(participantID, participantDomain, date)
    }

    // MARK: - addOrUpdateParticipant

    public var addOrUpdateParticipantWithRoleIn_Invocations: [(user: ZMUser, role: String, conversation: ZMConversation)] = []
    public var addOrUpdateParticipantWithRoleIn_MockMethod: ((ZMUser, String, ZMConversation) async -> Void)?

    public func addOrUpdateParticipant(_ user: ZMUser, withRole role: String, in conversation: ZMConversation) async {
        addOrUpdateParticipantWithRoleIn_Invocations.append((user: user, role: role, conversation: conversation))

        guard let mock = addOrUpdateParticipantWithRoleIn_MockMethod else {
            fatalError("no mock for `addOrUpdateParticipantWithRoleIn`")
        }

        await mock(user, role, conversation)
    }

    // MARK: - addParticipants

    public var addParticipantsAddedByAtDateConversation_Invocations: [(participants: [(id: UUID, domain: String?, role: String?)], sender: (id: UUID, domain: String?), date: Date, conversation: (id: UUID, domain: String))] = []
    public var addParticipantsAddedByAtDateConversation_MockError: Error?
    public var addParticipantsAddedByAtDateConversation_MockMethod: (([(id: UUID, domain: String?, role: String?)], (id: UUID, domain: String?), Date, (id: UUID, domain: String)) async throws -> Void)?

    public func addParticipants(_ participants: [(id: UUID, domain: String?, role: String?)], addedBy sender: (id: UUID, domain: String?), atDate date: Date, conversation: (id: UUID, domain: String)) async throws {
        addParticipantsAddedByAtDateConversation_Invocations.append((participants: participants, sender: sender, date: date, conversation: conversation))

        if let error = addParticipantsAddedByAtDateConversation_MockError {
            throw error
        }

        guard let mock = addParticipantsAddedByAtDateConversation_MockMethod else {
            fatalError("no mock for `addParticipantsAddedByAtDateConversation`")
        }

        try await mock(participants, sender, date, conversation)
    }

    // MARK: - updateMemberStatus

    public var updateMemberStatusMutedStatusInfoArchivedStatusInfoFor_Invocations: [(mutedStatusInfo: (status: Int?, referenceDate: Date?), archivedStatusInfo: (status: Bool?, referenceDate: Date?), localConversation: ZMConversation)] = []
    public var updateMemberStatusMutedStatusInfoArchivedStatusInfoFor_MockMethod: (((status: Int?, referenceDate: Date?), (status: Bool?, referenceDate: Date?), ZMConversation) async -> Void)?

    public func updateMemberStatus(mutedStatusInfo: (status: Int?, referenceDate: Date?), archivedStatusInfo: (status: Bool?, referenceDate: Date?), for localConversation: ZMConversation) async {
        updateMemberStatusMutedStatusInfoArchivedStatusInfoFor_Invocations.append((mutedStatusInfo: mutedStatusInfo, archivedStatusInfo: archivedStatusInfo, localConversation: localConversation))

        guard let mock = updateMemberStatusMutedStatusInfoArchivedStatusInfoFor_MockMethod else {
            fatalError("no mock for `updateMemberStatusMutedStatusInfoArchivedStatusInfoFor`")
        }

        await mock(mutedStatusInfo, archivedStatusInfo, localConversation)
    }

    // MARK: - updateAccesses

    public var updateAccessesForAccessModesAccessRoles_Invocations: [(conversation: ZMConversation, accessModes: [String], accessRoles: [String])] = []
    public var updateAccessesForAccessModesAccessRoles_MockMethod: ((ZMConversation, [String], [String]) async -> Void)?

    public func updateAccesses(for conversation: ZMConversation, accessModes: [String], accessRoles: [String]) async {
        updateAccessesForAccessModesAccessRoles_Invocations.append((conversation: conversation, accessModes: accessModes, accessRoles: accessRoles))

        guard let mock = updateAccessesForAccessModesAccessRoles_MockMethod else {
            fatalError("no mock for `updateAccessesForAccessModesAccessRoles`")
        }

        await mock(conversation, accessModes, accessRoles)
    }

    // MARK: - messageProtocol

    public var messageProtocolFor_Invocations: [ZMConversation] = []
    public var messageProtocolFor_MockMethod: ((ZMConversation) async -> WireDataModel.MessageProtocol)?
    public var messageProtocolFor_MockValue: WireDataModel.MessageProtocol?

    public func messageProtocol(for conversation: ZMConversation) async -> WireDataModel.MessageProtocol {
        messageProtocolFor_Invocations.append(conversation)

        if let mock = messageProtocolFor_MockMethod {
            return await mock(conversation)
        } else if let mock = messageProtocolFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `messageProtocolFor`")
        }
    }

    // MARK: - storeConversation

    public var storeConversationHasReadReceiptsEnabledFor_Invocations: [(hasReadReceiptsEnabled: Bool, conversation: ZMConversation)] = []
    public var storeConversationHasReadReceiptsEnabledFor_MockMethod: ((Bool, ZMConversation) async -> Void)?

    public func storeConversation(hasReadReceiptsEnabled: Bool, for conversation: ZMConversation) async {
        storeConversationHasReadReceiptsEnabledFor_Invocations.append((hasReadReceiptsEnabled: hasReadReceiptsEnabled, conversation: conversation))

        guard let mock = storeConversationHasReadReceiptsEnabledFor_MockMethod else {
            fatalError("no mock for `storeConversationHasReadReceiptsEnabledFor`")
        }

        await mock(hasReadReceiptsEnabled, conversation)
    }

    // MARK: - isConversationForcedReadOnly

    public var isConversationForcedReadOnly_Invocations: [ZMConversation] = []
    public var isConversationForcedReadOnly_MockMethod: ((ZMConversation) async -> Bool)?
    public var isConversationForcedReadOnly_MockValue: Bool?

    public func isConversationForcedReadOnly(_ conversation: ZMConversation) async -> Bool {
        isConversationForcedReadOnly_Invocations.append(conversation)

        if let mock = isConversationForcedReadOnly_MockMethod {
            return await mock(conversation)
        } else if let mock = isConversationForcedReadOnly_MockValue {
            return mock
        } else {
            fatalError("no mock for `isConversationForcedReadOnly`")
        }
    }

    // MARK: - removeParticipantsAndUpdateConversationState

    public var removeParticipantsAndUpdateConversationStateConversationUsersInitiatingUser_Invocations: [(conversation: ZMConversation, users: Set<ZMUser>, initiatingUser: ZMUser)] = []
    public var removeParticipantsAndUpdateConversationStateConversationUsersInitiatingUser_MockMethod: ((ZMConversation, Set<ZMUser>, ZMUser) async -> Void)?

    public func removeParticipantsAndUpdateConversationState(conversation: ZMConversation, users: Set<ZMUser>, initiatingUser: ZMUser) async {
        removeParticipantsAndUpdateConversationStateConversationUsersInitiatingUser_Invocations.append((conversation: conversation, users: users, initiatingUser: initiatingUser))

        guard let mock = removeParticipantsAndUpdateConversationStateConversationUsersInitiatingUser_MockMethod else {
            fatalError("no mock for `removeParticipantsAndUpdateConversationStateConversationUsersInitiatingUser`")
        }

        await mock(conversation, users, initiatingUser)
    }

    // MARK: - conversationMessageDestructionTimeout

    public var conversationMessageDestructionTimeout_Invocations: [ZMConversation] = []
    public var conversationMessageDestructionTimeout_MockMethod: ((ZMConversation) async -> MessageDestructionTimeoutValue)?
    public var conversationMessageDestructionTimeout_MockValue: MessageDestructionTimeoutValue?

    public func conversationMessageDestructionTimeout(_ conversation: ZMConversation) async -> MessageDestructionTimeoutValue {
        conversationMessageDestructionTimeout_Invocations.append(conversation)

        if let mock = conversationMessageDestructionTimeout_MockMethod {
            return await mock(conversation)
        } else if let mock = conversationMessageDestructionTimeout_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationMessageDestructionTimeout`")
        }
    }

    // MARK: - storeConversation

    public var storeConversationTimeoutValueFor_Invocations: [(timeoutValue: Double, conversation: ZMConversation)] = []
    public var storeConversationTimeoutValueFor_MockMethod: ((Double, ZMConversation) async -> Void)?

    public func storeConversation(timeoutValue: Double, for conversation: ZMConversation) async {
        storeConversationTimeoutValueFor_Invocations.append((timeoutValue: timeoutValue, conversation: conversation))

        guard let mock = storeConversationTimeoutValueFor_MockMethod else {
            fatalError("no mock for `storeConversationTimeoutValueFor`")
        }

        await mock(timeoutValue, conversation)
    }

    // MARK: - fetchOrCreateRole

    public var fetchOrCreateRoleIn_Invocations: [(role: String, conversation: ZMConversation)] = []
    public var fetchOrCreateRoleIn_MockMethod: ((String, ZMConversation) async -> Role)?
    public var fetchOrCreateRoleIn_MockValue: Role?

    public func fetchOrCreateRole(_ role: String, in conversation: ZMConversation) async -> Role {
        fetchOrCreateRoleIn_Invocations.append((role: role, conversation: conversation))

        if let mock = fetchOrCreateRoleIn_MockMethod {
            return await mock(role, conversation)
        } else if let mock = fetchOrCreateRoleIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateRoleIn`")
        }
    }

    // MARK: - localParticipants

    public var localParticipantsIn_Invocations: [ZMConversation] = []
    public var localParticipantsIn_MockMethod: ((ZMConversation) async -> Set<ZMUser>)?
    public var localParticipantsIn_MockValue: Set<ZMUser>?

    public func localParticipants(in conversation: ZMConversation) async -> Set<ZMUser> {
        localParticipantsIn_Invocations.append(conversation)

        if let mock = localParticipantsIn_MockMethod {
            return await mock(conversation)
        } else if let mock = localParticipantsIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `localParticipantsIn`")
        }
    }

    // MARK: - isGroupConversation

    public var isGroupConversation_Invocations: [ZMConversation] = []
    public var isGroupConversation_MockMethod: ((ZMConversation) async -> Bool)?
    public var isGroupConversation_MockValue: Bool?

    public func isGroupConversation(_ conversation: ZMConversation) async -> Bool {
        isGroupConversation_Invocations.append(conversation)

        if let mock = isGroupConversation_MockMethod {
            return await mock(conversation)
        } else if let mock = isGroupConversation_MockValue {
            return mock
        } else {
            fatalError("no mock for `isGroupConversation`")
        }
    }

    // MARK: - isSelfConversation

    public var isSelfConversation_Invocations: [ZMConversation] = []
    public var isSelfConversation_MockMethod: ((ZMConversation) async -> Bool)?
    public var isSelfConversation_MockValue: Bool?

    public func isSelfConversation(_ conversation: ZMConversation) async -> Bool {
        isSelfConversation_Invocations.append(conversation)

        if let mock = isSelfConversation_MockMethod {
            return await mock(conversation)
        } else if let mock = isSelfConversation_MockValue {
            return mock
        } else {
            fatalError("no mock for `isSelfConversation`")
        }
    }

    // MARK: - deleteConversation

    public var deleteConversation_Invocations: [ZMConversation] = []
    public var deleteConversation_MockMethod: ((ZMConversation) async -> Void)?

    public func deleteConversation(_ conversation: ZMConversation) async {
        deleteConversation_Invocations.append(conversation)

        guard let mock = deleteConversation_MockMethod else {
            fatalError("no mock for `deleteConversation`")
        }

        await mock(conversation)
    }

    // MARK: - storeConversation

    public var storeConversationIsDeletedRemotelyConversation_Invocations: [(isDeletedRemotely: Bool, conversation: ZMConversation)] = []
    public var storeConversationIsDeletedRemotelyConversation_MockMethod: ((Bool, ZMConversation) async -> Void)?

    public func storeConversation(isDeletedRemotely: Bool, conversation: ZMConversation) async {
        storeConversationIsDeletedRemotelyConversation_Invocations.append((isDeletedRemotely: isDeletedRemotely, conversation: conversation))

        guard let mock = storeConversationIsDeletedRemotelyConversation_MockMethod else {
            fatalError("no mock for `storeConversationIsDeletedRemotelyConversation`")
        }

        await mock(isDeletedRemotely, conversation)
    }

    // MARK: - mlsConversationInfo

    public var mlsConversationInfoConversation_Invocations: [ZMConversation] = []
    public var mlsConversationInfoConversation_MockMethod: ((ZMConversation) async -> (mlsGroupID: MLSGroupID, isMLSReady: Bool)?)?
    public var mlsConversationInfoConversation_MockValue: (mlsGroupID: MLSGroupID, isMLSReady: Bool)??

    public func mlsConversationInfo(conversation: ZMConversation) async -> (mlsGroupID: MLSGroupID, isMLSReady: Bool)? {
        mlsConversationInfoConversation_Invocations.append(conversation)

        if let mock = mlsConversationInfoConversation_MockMethod {
            return await mock(conversation)
        } else if let mock = mlsConversationInfoConversation_MockValue {
            return mock
        } else {
            fatalError("no mock for `mlsConversationInfoConversation`")
        }
    }

    // MARK: - updateCommitPendingProposal

    public var updateCommitPendingProposalDateForCommitDelay_Invocations: [(date: Date, conversation: ZMConversation, commitDelay: UInt64)] = []
    public var updateCommitPendingProposalDateForCommitDelay_MockMethod: ((Date, ZMConversation, UInt64) async -> Void)?

    public func updateCommitPendingProposal(date: Date, for conversation: ZMConversation, commitDelay: UInt64) async {
        updateCommitPendingProposalDateForCommitDelay_Invocations.append((date: date, conversation: conversation, commitDelay: commitDelay))

        guard let mock = updateCommitPendingProposalDateForCommitDelay_MockMethod else {
            fatalError("no mock for `updateCommitPendingProposalDateForCommitDelay`")
        }

        await mock(date, conversation, commitDelay)
    }

    // MARK: - updateSecurityLevelAfterReceivingMessage

    public var updateSecurityLevelAfterReceivingMessageConversationGenericMessageDate_Invocations: [(conversation: ZMConversation, genericMessage: GenericMessage, date: Date)] = []
    public var updateSecurityLevelAfterReceivingMessageConversationGenericMessageDate_MockMethod: ((ZMConversation, GenericMessage, Date) async -> Void)?

    public func updateSecurityLevelAfterReceivingMessage(conversation: ZMConversation, genericMessage: GenericMessage, date: Date) async {
        updateSecurityLevelAfterReceivingMessageConversationGenericMessageDate_Invocations.append((conversation: conversation, genericMessage: genericMessage, date: date))

        guard let mock = updateSecurityLevelAfterReceivingMessageConversationGenericMessageDate_MockMethod else {
            fatalError("no mock for `updateSecurityLevelAfterReceivingMessageConversationGenericMessageDate`")
        }

        await mock(conversation, genericMessage, date)
    }

    // MARK: - addParticipantIfNeeded

    public var addParticipantIfNeededParticipantIDParticipantDomainInDate_Invocations: [(participantID: UUID, participantDomain: String?, conversation: ZMConversation, date: Date)] = []
    public var addParticipantIfNeededParticipantIDParticipantDomainInDate_MockMethod: ((UUID, String?, ZMConversation, Date) async -> Void)?

    public func addParticipantIfNeeded(participantID: UUID, participantDomain: String?, in conversation: ZMConversation, date: Date) async {
        addParticipantIfNeededParticipantIDParticipantDomainInDate_Invocations.append((participantID: participantID, participantDomain: participantDomain, conversation: conversation, date: date))

        guard let mock = addParticipantIfNeededParticipantIDParticipantDomainInDate_MockMethod else {
            fatalError("no mock for `addParticipantIfNeededParticipantIDParticipantDomainInDate`")
        }

        await mock(participantID, participantDomain, conversation, date)
    }

    // MARK: - updateLastReadMessageTimestamp

    public var updateLastReadMessageTimestampIn_Invocations: [(lastReadMessage: LastRead, conversation: ZMConversation)] = []
    public var updateLastReadMessageTimestampIn_MockMethod: ((LastRead, ZMConversation) async -> Void)?

    public func updateLastReadMessageTimestamp(_ lastReadMessage: LastRead, in conversation: ZMConversation) async {
        updateLastReadMessageTimestampIn_Invocations.append((lastReadMessage: lastReadMessage, conversation: conversation))

        guard let mock = updateLastReadMessageTimestampIn_MockMethod else {
            fatalError("no mock for `updateLastReadMessageTimestampIn`")
        }

        await mock(lastReadMessage, conversation)
    }

    // MARK: - updateClearedMessageTimestamp

    public var updateClearedMessageTimestampIn_Invocations: [(clearedMessage: Cleared, conversation: ZMConversation)] = []
    public var updateClearedMessageTimestampIn_MockMethod: ((Cleared, ZMConversation) async -> Void)?

    public func updateClearedMessageTimestamp(_ clearedMessage: Cleared, in conversation: ZMConversation) async {
        updateClearedMessageTimestampIn_Invocations.append((clearedMessage: clearedMessage, conversation: conversation))

        guard let mock = updateClearedMessageTimestampIn_MockMethod else {
            fatalError("no mock for `updateClearedMessageTimestampIn`")
        }

        await mock(clearedMessage, conversation)
    }

    // MARK: - obtainPermanentIDs

    public var obtainPermanentIDsUserConversation_Invocations: [(user: ZMUser, conversation: ZMConversation)] = []
    public var obtainPermanentIDsUserConversation_MockMethod: ((ZMUser, ZMConversation) async -> Void)?

    public func obtainPermanentIDs(user: ZMUser, conversation: ZMConversation) async {
        obtainPermanentIDsUserConversation_Invocations.append((user: user, conversation: conversation))

        guard let mock = obtainPermanentIDsUserConversation_MockMethod else {
            fatalError("no mock for `obtainPermanentIDsUserConversation`")
        }

        await mock(user, conversation)
    }

    // MARK: - conversationName

    public var conversationNameConversation_Invocations: [ZMConversation] = []
    public var conversationNameConversation_MockMethod: ((ZMConversation) async -> String?)?
    public var conversationNameConversation_MockValue: String??

    public func conversationName(conversation: ZMConversation) async -> String? {
        conversationNameConversation_Invocations.append(conversation)

        if let mock = conversationNameConversation_MockMethod {
            return await mock(conversation)
        } else if let mock = conversationNameConversation_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationNameConversation`")
        }
    }

    // MARK: - storeConversation

    public var storeConversationNewNameConversation_Invocations: [(newName: String, conversation: ZMConversation)] = []
    public var storeConversationNewNameConversation_MockMethod: ((String, ZMConversation) async -> Void)?

    public func storeConversation(newName: String, conversation: ZMConversation) async {
        storeConversationNewNameConversation_Invocations.append((newName: newName, conversation: conversation))

        guard let mock = storeConversationNewNameConversation_MockMethod else {
            fatalError("no mock for `storeConversationNewNameConversation`")
        }

        await mock(newName, conversation)
    }

    // MARK: - updateOrCreateMLSGroup

    public var updateOrCreateMLSGroupGroupID_Invocations: [MLSGroupID] = []
    public var updateOrCreateMLSGroupGroupID_MockMethod: ((MLSGroupID) async -> Void)?

    public func updateOrCreateMLSGroup(groupID: MLSGroupID) async {
        updateOrCreateMLSGroupGroupID_Invocations.append(groupID)

        guard let mock = updateOrCreateMLSGroupGroupID_MockMethod else {
            fatalError("no mock for `updateOrCreateMLSGroupGroupID`")
        }

        await mock(groupID)
    }

    // MARK: - storeMLSConversationEstablished

    public var storeMLSConversationEstablishedMlsGroupIDEpochConversation_Invocations: [(mlsGroupID: MLSGroupID, epoch: UInt64, conversation: ZMConversation)] = []
    public var storeMLSConversationEstablishedMlsGroupIDEpochConversation_MockMethod: ((MLSGroupID, UInt64, ZMConversation) async -> Void)?

    public func storeMLSConversationEstablished(mlsGroupID: MLSGroupID, epoch: UInt64, conversation: ZMConversation) async {
        storeMLSConversationEstablishedMlsGroupIDEpochConversation_Invocations.append((mlsGroupID: mlsGroupID, epoch: epoch, conversation: conversation))

        guard let mock = storeMLSConversationEstablishedMlsGroupIDEpochConversation_MockMethod else {
            fatalError("no mock for `storeMLSConversationEstablishedMlsGroupIDEpochConversation`")
        }

        await mock(mlsGroupID, epoch, conversation)
    }

    // MARK: - storeMLSConversationPendingJoinAfterReset

    public var storeMLSConversationPendingJoinAfterResetNewMLSGroupIDConversation_Invocations: [(newMLSGroupID: MLSGroupID, conversation: ZMConversation)] = []
    public var storeMLSConversationPendingJoinAfterResetNewMLSGroupIDConversation_MockMethod: ((MLSGroupID, ZMConversation) async -> Void)?

    public func storeMLSConversationPendingJoinAfterReset(newMLSGroupID: MLSGroupID, conversation: ZMConversation) async {
        storeMLSConversationPendingJoinAfterResetNewMLSGroupIDConversation_Invocations.append((newMLSGroupID: newMLSGroupID, conversation: conversation))

        guard let mock = storeMLSConversationPendingJoinAfterResetNewMLSGroupIDConversation_MockMethod else {
            fatalError("no mock for `storeMLSConversationPendingJoinAfterResetNewMLSGroupIDConversation`")
        }

        await mock(newMLSGroupID, conversation)
    }

    // MARK: - fetchOtherUserIDInOneOnOneConversation

    public var fetchOtherUserIDInOneOnOneConversationConversation_Invocations: [ZMConversation] = []
    public var fetchOtherUserIDInOneOnOneConversationConversation_MockMethod: ((ZMConversation) async -> WireDataModel.QualifiedID?)?
    public var fetchOtherUserIDInOneOnOneConversationConversation_MockValue: WireDataModel.QualifiedID??

    public func fetchOtherUserIDInOneOnOneConversation(conversation: ZMConversation) async -> WireDataModel.QualifiedID? {
        fetchOtherUserIDInOneOnOneConversationConversation_Invocations.append(conversation)

        if let mock = fetchOtherUserIDInOneOnOneConversationConversation_MockMethod {
            return await mock(conversation)
        } else if let mock = fetchOtherUserIDInOneOnOneConversationConversation_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOtherUserIDInOneOnOneConversationConversation`")
        }
    }

    // MARK: - name

    public var nameFor_Invocations: [ZMConversation] = []
    public var nameFor_MockMethod: ((ZMConversation) async -> String?)?
    public var nameFor_MockValue: String??

    public func name(for conversation: ZMConversation) async -> String? {
        nameFor_Invocations.append(conversation)

        if let mock = nameFor_MockMethod {
            return await mock(conversation)
        } else if let mock = nameFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `nameFor`")
        }
    }

    // MARK: - shouldHideNotification

    public var shouldHideNotification_Invocations: [Void] = []
    public var shouldHideNotification_MockMethod: (() async -> Bool)?
    public var shouldHideNotification_MockValue: Bool?

    public func shouldHideNotification() async -> Bool {
        shouldHideNotification_Invocations.append(())

        if let mock = shouldHideNotification_MockMethod {
            return await mock()
        } else if let mock = shouldHideNotification_MockValue {
            return mock
        } else {
            fatalError("no mock for `shouldHideNotification`")
        }
    }

    // MARK: - isMessageSilenced

    public var isMessageSilencedSenderIDConversation_Invocations: [(message: GenericMessage, senderID: UUID?, conversation: ZMConversation)] = []
    public var isMessageSilencedSenderIDConversation_MockMethod: ((GenericMessage, UUID?, ZMConversation) async -> Bool)?
    public var isMessageSilencedSenderIDConversation_MockValue: Bool?

    public func isMessageSilenced(_ message: GenericMessage, senderID: UUID?, conversation: ZMConversation) async -> Bool {
        isMessageSilencedSenderIDConversation_Invocations.append((message: message, senderID: senderID, conversation: conversation))

        if let mock = isMessageSilencedSenderIDConversation_MockMethod {
            return await mock(message, senderID, conversation)
        } else if let mock = isMessageSilencedSenderIDConversation_MockValue {
            return mock
        } else {
            fatalError("no mock for `isMessageSilencedSenderIDConversation`")
        }
    }

    // MARK: - conversationMutedMessageTypesIncludingAvailability

    public var conversationMutedMessageTypesIncludingAvailability_Invocations: [ZMConversation] = []
    public var conversationMutedMessageTypesIncludingAvailability_MockMethod: ((ZMConversation) async -> MutedMessageTypes)?
    public var conversationMutedMessageTypesIncludingAvailability_MockValue: MutedMessageTypes?

    public func conversationMutedMessageTypesIncludingAvailability(_ conversation: ZMConversation) async -> MutedMessageTypes {
        conversationMutedMessageTypesIncludingAvailability_Invocations.append(conversation)

        if let mock = conversationMutedMessageTypesIncludingAvailability_MockMethod {
            return await mock(conversation)
        } else if let mock = conversationMutedMessageTypesIncludingAvailability_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationMutedMessageTypesIncludingAvailability`")
        }
    }

    // MARK: - lastReadServerTimestamp

    public var lastReadServerTimestamp_Invocations: [ZMConversation] = []
    public var lastReadServerTimestamp_MockMethod: ((ZMConversation) async -> Date?)?
    public var lastReadServerTimestamp_MockValue: Date??

    public func lastReadServerTimestamp(_ conversation: ZMConversation) async -> Date? {
        lastReadServerTimestamp_Invocations.append(conversation)

        if let mock = lastReadServerTimestamp_MockMethod {
            return await mock(conversation)
        } else if let mock = lastReadServerTimestamp_MockValue {
            return mock
        } else {
            fatalError("no mock for `lastReadServerTimestamp`")
        }
    }

    // MARK: - conversationNeedsBackendUpdate

    public var conversationNeedsBackendUpdate_Invocations: [ZMConversation] = []
    public var conversationNeedsBackendUpdate_MockMethod: ((ZMConversation) async -> Bool)?
    public var conversationNeedsBackendUpdate_MockValue: Bool?

    public func conversationNeedsBackendUpdate(_ conversation: ZMConversation) async -> Bool {
        conversationNeedsBackendUpdate_Invocations.append(conversation)

        if let mock = conversationNeedsBackendUpdate_MockMethod {
            return await mock(conversation)
        } else if let mock = conversationNeedsBackendUpdate_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationNeedsBackendUpdate`")
        }
    }

    // MARK: - increaseUnreadCount

    public var increaseUnreadCountFor_Invocations: [ZMConversation] = []
    public var increaseUnreadCountFor_MockMethod: ((ZMConversation) async -> Void)?

    public func increaseUnreadCount(for conversation: ZMConversation) async {
        increaseUnreadCountFor_Invocations.append(conversation)

        guard let mock = increaseUnreadCountFor_MockMethod else {
            fatalError("no mock for `increaseUnreadCountFor`")
        }

        await mock(conversation)
    }

    // MARK: - decreaseUnreadCount

    public var decreaseUnreadCountFor_Invocations: [ZMConversation] = []
    public var decreaseUnreadCountFor_MockMethod: ((ZMConversation) async -> Void)?

    public func decreaseUnreadCount(for conversation: ZMConversation) async {
        decreaseUnreadCountFor_Invocations.append(conversation)

        guard let mock = decreaseUnreadCountFor_MockMethod else {
            fatalError("no mock for `decreaseUnreadCountFor`")
        }

        await mock(conversation)
    }

    // MARK: - increaseUnreadSelfMentionCount

    public var increaseUnreadSelfMentionCountFor_Invocations: [ZMConversation] = []
    public var increaseUnreadSelfMentionCountFor_MockMethod: ((ZMConversation) async -> Void)?

    public func increaseUnreadSelfMentionCount(for conversation: ZMConversation) async {
        increaseUnreadSelfMentionCountFor_Invocations.append(conversation)

        guard let mock = increaseUnreadSelfMentionCountFor_MockMethod else {
            fatalError("no mock for `increaseUnreadSelfMentionCountFor`")
        }

        await mock(conversation)
    }

    // MARK: - increaseUnreadSelfReplyCount

    public var increaseUnreadSelfReplyCountFor_Invocations: [ZMConversation] = []
    public var increaseUnreadSelfReplyCountFor_MockMethod: ((ZMConversation) async -> Void)?

    public func increaseUnreadSelfReplyCount(for conversation: ZMConversation) async {
        increaseUnreadSelfReplyCountFor_Invocations.append(conversation)

        guard let mock = increaseUnreadSelfReplyCountFor_MockMethod else {
            fatalError("no mock for `increaseUnreadSelfReplyCountFor`")
        }

        await mock(conversation)
    }

    // MARK: - unreadConversationCount

    public var unreadConversationCount_Invocations: [Void] = []
    public var unreadConversationCount_MockMethod: (() async -> UInt)?
    public var unreadConversationCount_MockValue: UInt?

    public func unreadConversationCount() async -> UInt {
        unreadConversationCount_Invocations.append(())

        if let mock = unreadConversationCount_MockMethod {
            return await mock()
        } else if let mock = unreadConversationCount_MockValue {
            return mock
        } else {
            fatalError("no mock for `unreadConversationCount`")
        }
    }

    // MARK: - storeConversation

    public var storeConversationPermissionConversation_Invocations: [(permission: WireDomain.Conversation.ChannelPermission, conversation: ZMConversation)] = []
    public var storeConversationPermissionConversation_MockMethod: ((WireDomain.Conversation.ChannelPermission, ZMConversation) async -> Void)?

    public func storeConversation(permission: WireDomain.Conversation.ChannelPermission, conversation: ZMConversation) async {
        storeConversationPermissionConversation_Invocations.append((permission: permission, conversation: conversation))

        guard let mock = storeConversationPermissionConversation_MockMethod else {
            fatalError("no mock for `storeConversationPermissionConversation`")
        }

        await mock(permission, conversation)
    }

    // MARK: - storeConversation

    public var storeConversationHistoryDepthConversationIDConversationDomain_Invocations: [(historyDepth: String, conversationID: UUID, conversationDomain: String?)] = []
    public var storeConversationHistoryDepthConversationIDConversationDomain_MockError: Error?
    public var storeConversationHistoryDepthConversationIDConversationDomain_MockMethod: ((String, UUID, String?) async throws -> Void)?

    public func storeConversation(historyDepth: String, conversationID: UUID, conversationDomain: String?) async throws {
        storeConversationHistoryDepthConversationIDConversationDomain_Invocations.append((historyDepth: historyDepth, conversationID: conversationID, conversationDomain: conversationDomain))

        if let error = storeConversationHistoryDepthConversationIDConversationDomain_MockError {
            throw error
        }

        guard let mock = storeConversationHistoryDepthConversationIDConversationDomain_MockMethod else {
            fatalError("no mock for `storeConversationHistoryDepthConversationIDConversationDomain`")
        }

        try await mock(historyDepth, conversationID, conversationDomain)
    }

    // MARK: - fetchServerTimeDelta

    public var fetchServerTimeDelta_Invocations: [Void] = []
    public var fetchServerTimeDelta_MockMethod: (() async -> TimeInterval)?
    public var fetchServerTimeDelta_MockValue: TimeInterval?

    public func fetchServerTimeDelta() async -> TimeInterval {
        fetchServerTimeDelta_Invocations.append(())

        if let mock = fetchServerTimeDelta_MockMethod {
            return await mock()
        } else if let mock = fetchServerTimeDelta_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchServerTimeDelta`")
        }
    }

    // MARK: - execute

    public var executeIdentifierBlock_Invocations: [(identifier: MLSGroupID, block: (ZMConversation?, NSManagedObjectContext) -> Void)] = []
    public var executeIdentifierBlock_MockMethod: ((MLSGroupID, @Sendable @escaping (ZMConversation?, NSManagedObjectContext) -> Void) async -> Void)?

    public func execute(identifier: MLSGroupID, block: @Sendable @escaping (ZMConversation?, NSManagedObjectContext) -> Void) async {
        executeIdentifierBlock_Invocations.append((identifier: identifier, block: block))

        guard let mock = executeIdentifierBlock_MockMethod else {
            fatalError("no mock for `executeIdentifierBlock`")
        }

        await mock(identifier, block)
    }

}

class MockConversationLocationMessageNotificationBuilderProtocol: ConversationLocationMessageNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentConversationIDSenderID_Invocations: [(conversationID: ConversationID, senderID: UserID)] = []
    var buildContentConversationIDSenderID_MockMethod: ((ConversationID, UserID) async -> UserNotification)?
    var buildContentConversationIDSenderID_MockValue: UserNotification?

    func buildContent(conversationID: ConversationID, senderID: UserID) async -> UserNotification {
        buildContentConversationIDSenderID_Invocations.append((conversationID: conversationID, senderID: senderID))

        if let mock = buildContentConversationIDSenderID_MockMethod {
            return await mock(conversationID, senderID)
        } else if let mock = buildContentConversationIDSenderID_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentConversationIDSenderID`")
        }
    }

}

class MockConversationMemberJoinEventNotificationBuilderProtocol: ConversationMemberJoinEventNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentEvent_Invocations: [ConversationMemberJoinEvent] = []
    var buildContentEvent_MockMethod: ((ConversationMemberJoinEvent) async -> UserNotification?)?
    var buildContentEvent_MockValue: UserNotification??

    func buildContent(event: ConversationMemberJoinEvent) async -> UserNotification? {
        buildContentEvent_Invocations.append(event)

        if let mock = buildContentEvent_MockMethod {
            return await mock(event)
        } else if let mock = buildContentEvent_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentEvent`")
        }
    }

}

class MockConversationMemberLeaveEventNotificationBuilderProtocol: ConversationMemberLeaveEventNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentEvent_Invocations: [ConversationMemberLeaveEvent] = []
    var buildContentEvent_MockMethod: ((ConversationMemberLeaveEvent) async -> UserNotification?)?
    var buildContentEvent_MockValue: UserNotification??

    func buildContent(event: ConversationMemberLeaveEvent) async -> UserNotification? {
        buildContentEvent_Invocations.append(event)

        if let mock = buildContentEvent_MockMethod {
            return await mock(event)
        } else if let mock = buildContentEvent_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentEvent`")
        }
    }

}

class MockConversationMessageTimerUpdateEventNotificationBuilderProtocol: ConversationMessageTimerUpdateEventNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentEvent_Invocations: [ConversationMessageTimerUpdateEvent] = []
    var buildContentEvent_MockMethod: ((ConversationMessageTimerUpdateEvent) async -> UserNotification?)?
    var buildContentEvent_MockValue: UserNotification??

    func buildContent(event: ConversationMessageTimerUpdateEvent) async -> UserNotification? {
        buildContentEvent_Invocations.append(event)

        if let mock = buildContentEvent_MockMethod {
            return await mock(event)
        } else if let mock = buildContentEvent_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentEvent`")
        }
    }

}

class MockConversationPingMessageNotificationBuilderProtocol: ConversationPingMessageNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentConversationIDSenderID_Invocations: [(conversationID: ConversationID, senderID: UserID)] = []
    var buildContentConversationIDSenderID_MockMethod: ((ConversationID, UserID) async -> UserNotification)?
    var buildContentConversationIDSenderID_MockValue: UserNotification?

    func buildContent(conversationID: ConversationID, senderID: UserID) async -> UserNotification {
        buildContentConversationIDSenderID_Invocations.append((conversationID: conversationID, senderID: senderID))

        if let mock = buildContentConversationIDSenderID_MockMethod {
            return await mock(conversationID, senderID)
        } else if let mock = buildContentConversationIDSenderID_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentConversationIDSenderID`")
        }
    }

}

public class MockConversationProtobufMessageProcessorProtocol: ConversationProtobufMessageProcessorProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - processProtobufMessage

    public var processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_Invocations: [(message: GenericMessage, conversation: ZMConversation, conversationID: ConversationID, senderID: UserID, senderClientID: String?, date: Date, eventMessage: String)] = []
    public var processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_MockError: Error?
    public var processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_MockMethod: ((GenericMessage, ZMConversation, ConversationID, UserID, String?, Date, String) async throws -> Void)?

    public func processProtobufMessage(_ message: GenericMessage, conversation: ZMConversation, conversationID: ConversationID, senderID: UserID, senderClientID: String?, date: Date, eventMessage: String) async throws {
        processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_Invocations.append((message: message, conversation: conversation, conversationID: conversationID, senderID: senderID, senderClientID: senderClientID, date: date, eventMessage: eventMessage))

        if let error = processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_MockError {
            throw error
        }

        guard let mock = processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_MockMethod else {
            fatalError("no mock for `processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage`")
        }

        try await mock(message, conversation, conversationID, senderID, senderClientID, date, eventMessage)
    }

}

public class MockConversationRepositoryProtocol: ConversationRepositoryProtocol, @unchecked Sendable {

    // MARK: - Life cycle

    public init() {}


    // MARK: - pullConversation

    public var pullConversationIdDomain_Invocations: [(id: UUID, domain: String)] = []
    public var pullConversationIdDomain_MockError: Error?
    public var pullConversationIdDomain_MockMethod: ((UUID, String) async throws -> Void)?

    public func pullConversation(id: UUID, domain: String) async throws {
        pullConversationIdDomain_Invocations.append((id: id, domain: domain))

        if let error = pullConversationIdDomain_MockError {
            throw error
        }

        guard let mock = pullConversationIdDomain_MockMethod else {
            fatalError("no mock for `pullConversationIdDomain`")
        }

        try await mock(id, domain)
    }

    // MARK: - fetchConversation

    public var fetchConversationIdDomain_Invocations: [(id: UUID, domain: String?)] = []
    public var fetchConversationIdDomain_MockMethod: ((UUID, String?) async -> ZMConversation?)?
    public var fetchConversationIdDomain_MockValue: ZMConversation??

    public func fetchConversation(id: UUID, domain: String?) async -> ZMConversation? {
        fetchConversationIdDomain_Invocations.append((id: id, domain: domain))

        if let mock = fetchConversationIdDomain_MockMethod {
            return await mock(id, domain)
        } else if let mock = fetchConversationIdDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchConversationIdDomain`")
        }
    }

    // MARK: - storeConversation

    public var storeConversationTimestamp_Invocations: [(conversation: WireDomain.Conversation, timestamp: Date)] = []
    public var storeConversationTimestamp_MockMethod: ((WireDomain.Conversation, Date) async -> Void)?

    public func storeConversation(_ conversation: WireDomain.Conversation, timestamp: Date) async {
        storeConversationTimestamp_Invocations.append((conversation: conversation, timestamp: timestamp))

        guard let mock = storeConversationTimestamp_MockMethod else {
            fatalError("no mock for `storeConversationTimestamp`")
        }

        await mock(conversation, timestamp)
    }

    // MARK: - fetchOrCreateConversation

    public var fetchOrCreateConversationIdDomain_Invocations: [(id: UUID, domain: String?)] = []
    public var fetchOrCreateConversationIdDomain_MockMethod: ((UUID, String?) async -> ZMConversation)?
    public var fetchOrCreateConversationIdDomain_MockValue: ZMConversation?

    public func fetchOrCreateConversation(id: UUID, domain: String?) async -> ZMConversation {
        fetchOrCreateConversationIdDomain_Invocations.append((id: id, domain: domain))

        if let mock = fetchOrCreateConversationIdDomain_MockMethod {
            return await mock(id, domain)
        } else if let mock = fetchOrCreateConversationIdDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateConversationIdDomain`")
        }
    }

    // MARK: - pullMLSOneToOneConversation

    public var pullMLSOneToOneConversationUserIDUserDomain_Invocations: [(userID: String, userDomain: String)] = []
    public var pullMLSOneToOneConversationUserIDUserDomain_MockError: Error?
    public var pullMLSOneToOneConversationUserIDUserDomain_MockMethod: ((String, String) async throws -> (String, MLSPublicKeys?))?
    public var pullMLSOneToOneConversationUserIDUserDomain_MockValue: (String, MLSPublicKeys?)?

    public func pullMLSOneToOneConversation(userID: String, userDomain: String) async throws -> (String, MLSPublicKeys?) {
        pullMLSOneToOneConversationUserIDUserDomain_Invocations.append((userID: userID, userDomain: userDomain))

        if let error = pullMLSOneToOneConversationUserIDUserDomain_MockError {
            throw error
        }

        if let mock = pullMLSOneToOneConversationUserIDUserDomain_MockMethod {
            return try await mock(userID, userDomain)
        } else if let mock = pullMLSOneToOneConversationUserIDUserDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `pullMLSOneToOneConversationUserIDUserDomain`")
        }
    }

    // MARK: - fetchMLSConversation

    public var fetchMLSConversationGroupID_Invocations: [String] = []
    public var fetchMLSConversationGroupID_MockMethod: ((String) async -> ZMConversation?)?
    public var fetchMLSConversationGroupID_MockValue: ZMConversation??

    public func fetchMLSConversation(groupID: String) async -> ZMConversation? {
        fetchMLSConversationGroupID_Invocations.append(groupID)

        if let mock = fetchMLSConversationGroupID_MockMethod {
            return await mock(groupID)
        } else if let mock = fetchMLSConversationGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchMLSConversationGroupID`")
        }
    }

    // MARK: - deleteConversation

    public var deleteConversationIdDomain_Invocations: [(id: UUID, domain: String?)] = []
    public var deleteConversationIdDomain_MockError: Error?
    public var deleteConversationIdDomain_MockMethod: ((UUID, String?) async throws -> Void)?

    public func deleteConversation(id: UUID, domain: String?) async throws {
        deleteConversationIdDomain_Invocations.append((id: id, domain: domain))

        if let error = deleteConversationIdDomain_MockError {
            throw error
        }

        guard let mock = deleteConversationIdDomain_MockMethod else {
            fatalError("no mock for `deleteConversationIdDomain`")
        }

        try await mock(id, domain)
    }

    // MARK: - removeParticipantFromAllGroupConversations

    public var removeParticipantFromAllGroupConversationsParticipantIDParticipantDomainRemovedAt_Invocations: [(participantID: UUID, participantDomain: String?, date: Date)] = []
    public var removeParticipantFromAllGroupConversationsParticipantIDParticipantDomainRemovedAt_MockError: Error?
    public var removeParticipantFromAllGroupConversationsParticipantIDParticipantDomainRemovedAt_MockMethod: ((UUID, String?, Date) async throws -> Void)?

    public func removeParticipantFromAllGroupConversations(participantID: UUID, participantDomain: String?, removedAt date: Date) async throws {
        removeParticipantFromAllGroupConversationsParticipantIDParticipantDomainRemovedAt_Invocations.append((participantID: participantID, participantDomain: participantDomain, date: date))

        if let error = removeParticipantFromAllGroupConversationsParticipantIDParticipantDomainRemovedAt_MockError {
            throw error
        }

        guard let mock = removeParticipantFromAllGroupConversationsParticipantIDParticipantDomainRemovedAt_MockMethod else {
            fatalError("no mock for `removeParticipantFromAllGroupConversationsParticipantIDParticipantDomainRemovedAt`")
        }

        try await mock(participantID, participantDomain, date)
    }

    // MARK: - addOrUpdateParticipant

    public var addOrUpdateParticipantParticipantIDParticipantDomainParticipantRoleConversationIDConversationDomain_Invocations: [(participantID: UUID, participantDomain: String?, participantRole: String, conversationID: UUID, conversationDomain: String?)] = []
    public var addOrUpdateParticipantParticipantIDParticipantDomainParticipantRoleConversationIDConversationDomain_MockMethod: ((UUID, String?, String, UUID, String?) async -> Void)?

    public func addOrUpdateParticipant(participantID: UUID, participantDomain: String?, participantRole: String, conversationID: UUID, conversationDomain: String?) async {
        addOrUpdateParticipantParticipantIDParticipantDomainParticipantRoleConversationIDConversationDomain_Invocations.append((participantID: participantID, participantDomain: participantDomain, participantRole: participantRole, conversationID: conversationID, conversationDomain: conversationDomain))

        guard let mock = addOrUpdateParticipantParticipantIDParticipantDomainParticipantRoleConversationIDConversationDomain_MockMethod else {
            fatalError("no mock for `addOrUpdateParticipantParticipantIDParticipantDomainParticipantRoleConversationIDConversationDomain`")
        }

        await mock(participantID, participantDomain, participantRole, conversationID, conversationDomain)
    }

    // MARK: - addParticipants

    public var addParticipantsSenderDateConversationIDConversationDomain_Invocations: [(participants: [(id: UUID, domain: String?, role: String?)], sender: (id: UUID, domain: String?), date: Date, conversationID: UUID, conversationDomain: String)] = []
    public var addParticipantsSenderDateConversationIDConversationDomain_MockError: Error?
    public var addParticipantsSenderDateConversationIDConversationDomain_MockMethod: (([(id: UUID, domain: String?, role: String?)], (id: UUID, domain: String?), Date, UUID, String) async throws -> Void)?

    public func addParticipants(_ participants: [(id: UUID, domain: String?, role: String?)], sender: (id: UUID, domain: String?), date: Date, conversationID: UUID, conversationDomain: String) async throws {
        addParticipantsSenderDateConversationIDConversationDomain_Invocations.append((participants: participants, sender: sender, date: date, conversationID: conversationID, conversationDomain: conversationDomain))

        if let error = addParticipantsSenderDateConversationIDConversationDomain_MockError {
            throw error
        }

        guard let mock = addParticipantsSenderDateConversationIDConversationDomain_MockMethod else {
            fatalError("no mock for `addParticipantsSenderDateConversationIDConversationDomain`")
        }

        try await mock(participants, sender, date, conversationID, conversationDomain)
    }

    // MARK: - removeMembers

    public var removeMembersFromInitiatedByAtReason_Invocations: [(userIDs: Set<UserID>, conversation: ConversationID, sender: UserID, date: Date, reason: ConversationMemberLeaveReason)] = []
    public var removeMembersFromInitiatedByAtReason_MockError: Error?
    public var removeMembersFromInitiatedByAtReason_MockMethod: ((Set<UserID>, ConversationID, UserID, Date, ConversationMemberLeaveReason) async throws -> Void)?

    public func removeMembers(_ userIDs: Set<UserID>, from conversation: ConversationID, initiatedBy sender: UserID, at date: Date, reason: ConversationMemberLeaveReason) async throws {
        removeMembersFromInitiatedByAtReason_Invocations.append((userIDs: userIDs, conversation: conversation, sender: sender, date: date, reason: reason))

        if let error = removeMembersFromInitiatedByAtReason_MockError {
            throw error
        }

        guard let mock = removeMembersFromInitiatedByAtReason_MockMethod else {
            fatalError("no mock for `removeMembersFromInitiatedByAtReason`")
        }

        try await mock(userIDs, conversation, sender, date, reason)
    }

    // MARK: - updateConversationName

    public var updateConversationNameNewNameConversationIDConversationDomainSenderIDSenderDomainDate_Invocations: [(newName: String, conversationID: UUID, conversationDomain: String?, senderID: UUID, senderDomain: String?, date: Date)] = []
    public var updateConversationNameNewNameConversationIDConversationDomainSenderIDSenderDomainDate_MockMethod: ((String, UUID, String?, UUID, String?, Date) async -> Void)?

    public func updateConversationName(newName: String, conversationID: UUID, conversationDomain: String?, senderID: UUID, senderDomain: String?, date: Date) async {
        updateConversationNameNewNameConversationIDConversationDomainSenderIDSenderDomainDate_Invocations.append((newName: newName, conversationID: conversationID, conversationDomain: conversationDomain, senderID: senderID, senderDomain: senderDomain, date: date))

        guard let mock = updateConversationNameNewNameConversationIDConversationDomainSenderIDSenderDomainDate_MockMethod else {
            fatalError("no mock for `updateConversationNameNewNameConversationIDConversationDomainSenderIDSenderDomainDate`")
        }

        await mock(newName, conversationID, conversationDomain, senderID, senderDomain, date)
    }

    // MARK: - fetchConversationGuestLink

    public var fetchConversationGuestLinkConversationID_Invocations: [String] = []
    public var fetchConversationGuestLinkConversationID_MockError: Error?
    public var fetchConversationGuestLinkConversationID_MockMethod: ((String) async throws -> String?)?
    public var fetchConversationGuestLinkConversationID_MockValue: String??

    public func fetchConversationGuestLink(conversationID: String) async throws -> String? {
        fetchConversationGuestLinkConversationID_Invocations.append(conversationID)

        if let error = fetchConversationGuestLinkConversationID_MockError {
            throw error
        }

        if let mock = fetchConversationGuestLinkConversationID_MockMethod {
            return try await mock(conversationID)
        } else if let mock = fetchConversationGuestLinkConversationID_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchConversationGuestLinkConversationID`")
        }
    }

    // MARK: - isSelfAnActiveMember

    public var isSelfAnActiveMemberIn_Invocations: [WireDataModel.MLSGroupID] = []
    public var isSelfAnActiveMemberIn_MockMethod: ((WireDataModel.MLSGroupID) async -> Bool)?
    public var isSelfAnActiveMemberIn_MockValue: Bool?

    public func isSelfAnActiveMember(in groupID: WireDataModel.MLSGroupID) async -> Bool {
        isSelfAnActiveMemberIn_Invocations.append(groupID)

        if let mock = isSelfAnActiveMemberIn_MockMethod {
            return await mock(groupID)
        } else if let mock = isSelfAnActiveMemberIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `isSelfAnActiveMemberIn`")
        }
    }

    // MARK: - clearPendingProposals

    public var clearPendingProposalsIn_Invocations: [WireDataModel.MLSGroupID] = []
    public var clearPendingProposalsIn_MockMethod: ((WireDataModel.MLSGroupID) async -> Void)?

    public func clearPendingProposals(in groupID: WireDataModel.MLSGroupID) async {
        clearPendingProposalsIn_Invocations.append(groupID)

        guard let mock = clearPendingProposalsIn_MockMethod else {
            fatalError("no mock for `clearPendingProposalsIn`")
        }

        await mock(groupID)
    }

}

class MockConversationTextMessageNotificationBuilderProtocol: ConversationTextMessageNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentTextConversationIDSenderID_Invocations: [(text: Text, conversationID: ConversationID, senderID: UserID)] = []
    var buildContentTextConversationIDSenderID_MockMethod: ((Text, ConversationID, UserID) async -> UserNotification?)?
    var buildContentTextConversationIDSenderID_MockValue: UserNotification??

    func buildContent(text: Text, conversationID: ConversationID, senderID: UserID) async -> UserNotification? {
        buildContentTextConversationIDSenderID_Invocations.append((text: text, conversationID: conversationID, senderID: senderID))

        if let mock = buildContentTextConversationIDSenderID_MockMethod {
            return await mock(text, conversationID, senderID)
        } else if let mock = buildContentTextConversationIDSenderID_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentTextConversationIDSenderID`")
        }
    }

}

class MockConversationVideoMessageNotificationBuilderProtocol: ConversationVideoMessageNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentConversationIDSenderID_Invocations: [(conversationID: ConversationID, senderID: UserID)] = []
    var buildContentConversationIDSenderID_MockMethod: ((ConversationID, UserID) async -> UserNotification)?
    var buildContentConversationIDSenderID_MockValue: UserNotification?

    func buildContent(conversationID: ConversationID, senderID: UserID) async -> UserNotification {
        buildContentConversationIDSenderID_Invocations.append((conversationID: conversationID, senderID: senderID))

        if let mock = buildContentConversationIDSenderID_MockMethod {
            return await mock(conversationID, senderID)
        } else if let mock = buildContentConversationIDSenderID_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentConversationIDSenderID`")
        }
    }

}

public class MockCreateChannelUseCaseProtocol: CreateChannelUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invokeTeamIDNameHistoryDepthCellsUsersAccessModeAccessRolesEnableReceipts_Invocations: [(teamID: UUID, name: String?, historyDepth: String?, cells: Bool?, users: Set<ZMUser>, accessMode: Set<WireNetwork.ConversationAccessMode>, accessRoles: Set<WireNetwork.ConversationAccessRole>, enableReceipts: Bool)] = []
    public var invokeTeamIDNameHistoryDepthCellsUsersAccessModeAccessRolesEnableReceipts_MockError: Error?
    public var invokeTeamIDNameHistoryDepthCellsUsersAccessModeAccessRolesEnableReceipts_MockMethod: ((UUID, String?, String?, Bool?, Set<ZMUser>, Set<WireNetwork.ConversationAccessMode>, Set<WireNetwork.ConversationAccessRole>, Bool) async throws -> ZMConversation)?
    public var invokeTeamIDNameHistoryDepthCellsUsersAccessModeAccessRolesEnableReceipts_MockValue: ZMConversation?

    public func invoke(teamID: UUID, name: String?, historyDepth: String?, cells: Bool?, users: Set<ZMUser>, accessMode: Set<WireNetwork.ConversationAccessMode>, accessRoles: Set<WireNetwork.ConversationAccessRole>, enableReceipts: Bool) async throws -> ZMConversation {
        invokeTeamIDNameHistoryDepthCellsUsersAccessModeAccessRolesEnableReceipts_Invocations.append((teamID: teamID, name: name, historyDepth: historyDepth, cells: cells, users: users, accessMode: accessMode, accessRoles: accessRoles, enableReceipts: enableReceipts))

        if let error = invokeTeamIDNameHistoryDepthCellsUsersAccessModeAccessRolesEnableReceipts_MockError {
            throw error
        }

        if let mock = invokeTeamIDNameHistoryDepthCellsUsersAccessModeAccessRolesEnableReceipts_MockMethod {
            return try await mock(teamID, name, historyDepth, cells, users, accessMode, accessRoles, enableReceipts)
        } else if let mock = invokeTeamIDNameHistoryDepthCellsUsersAccessModeAccessRolesEnableReceipts_MockValue {
            return mock
        } else {
            fatalError("no mock for `invokeTeamIDNameHistoryDepthCellsUsersAccessModeAccessRolesEnableReceipts`")
        }
    }

}

public class MockCreateGroupConversationUseCaseProtocol: CreateGroupConversationUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invokeTeamIDMessageProtocolNameUsersAccessModeAccessRolesEnableReceiptsCellsIsMLSEnabled_Invocations: [(teamID: UUID?, messageProtocol: WireNetwork.ConversationMessageProtocol, name: String?, users: Set<ZMUser>, accessMode: Set<WireNetwork.ConversationAccessMode>, accessRoles: Set<WireNetwork.ConversationAccessRole>, enableReceipts: Bool, cells: Bool?, isMLSEnabled: Bool)] = []
    public var invokeTeamIDMessageProtocolNameUsersAccessModeAccessRolesEnableReceiptsCellsIsMLSEnabled_MockError: Error?
    public var invokeTeamIDMessageProtocolNameUsersAccessModeAccessRolesEnableReceiptsCellsIsMLSEnabled_MockMethod: ((UUID?, WireNetwork.ConversationMessageProtocol, String?, Set<ZMUser>, Set<WireNetwork.ConversationAccessMode>, Set<WireNetwork.ConversationAccessRole>, Bool, Bool?, Bool) async throws -> ZMConversation)?
    public var invokeTeamIDMessageProtocolNameUsersAccessModeAccessRolesEnableReceiptsCellsIsMLSEnabled_MockValue: ZMConversation?

    public func invoke(teamID: UUID?, messageProtocol: WireNetwork.ConversationMessageProtocol, name: String?, users: Set<ZMUser>, accessMode: Set<WireNetwork.ConversationAccessMode>, accessRoles: Set<WireNetwork.ConversationAccessRole>, enableReceipts: Bool, cells: Bool?, isMLSEnabled: Bool) async throws -> ZMConversation {
        invokeTeamIDMessageProtocolNameUsersAccessModeAccessRolesEnableReceiptsCellsIsMLSEnabled_Invocations.append((teamID: teamID, messageProtocol: messageProtocol, name: name, users: users, accessMode: accessMode, accessRoles: accessRoles, enableReceipts: enableReceipts, cells: cells, isMLSEnabled: isMLSEnabled))

        if let error = invokeTeamIDMessageProtocolNameUsersAccessModeAccessRolesEnableReceiptsCellsIsMLSEnabled_MockError {
            throw error
        }

        if let mock = invokeTeamIDMessageProtocolNameUsersAccessModeAccessRolesEnableReceiptsCellsIsMLSEnabled_MockMethod {
            return try await mock(teamID, messageProtocol, name, users, accessMode, accessRoles, enableReceipts, cells, isMLSEnabled)
        } else if let mock = invokeTeamIDMessageProtocolNameUsersAccessModeAccessRolesEnableReceiptsCellsIsMLSEnabled_MockValue {
            return mock
        } else {
            fatalError("no mock for `invokeTeamIDMessageProtocolNameUsersAccessModeAccessRolesEnableReceiptsCellsIsMLSEnabled`")
        }
    }

}

public class MockDatabaseSaverProtocol: DatabaseSaverProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - save

    public var save_Invocations: [Void] = []
    public var save_MockError: Error?
    public var save_MockMethod: (() async throws -> Void)?

    public func save() async throws {
        save_Invocations.append(())

        if let error = save_MockError {
            throw error
        }

        guard let mock = save_MockMethod else {
            fatalError("no mock for `save`")
        }

        try await mock()
    }

}

public class MockFeatureConfigRepositoryProtocol: FeatureConfigRepositoryProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - pullFeatureConfigs

    public var pullFeatureConfigs_Invocations: [Void] = []
    public var pullFeatureConfigs_MockError: Error?
    public var pullFeatureConfigs_MockMethod: (() async throws -> Void)?

    public func pullFeatureConfigs() async throws {
        pullFeatureConfigs_Invocations.append(())

        if let error = pullFeatureConfigs_MockError {
            throw error
        }

        guard let mock = pullFeatureConfigs_MockMethod else {
            fatalError("no mock for `pullFeatureConfigs`")
        }

        try await mock()
    }

    // MARK: - observeFeatureStates

    public var observeFeatureStates_Invocations: [Void] = []
    public var observeFeatureStates_MockMethod: (() -> AnyPublisher<FeatureState, Never>)?
    public var observeFeatureStates_MockValue: AnyPublisher<FeatureState, Never>?

    public func observeFeatureStates() -> AnyPublisher<FeatureState, Never> {
        observeFeatureStates_Invocations.append(())

        if let mock = observeFeatureStates_MockMethod {
            return mock()
        } else if let mock = observeFeatureStates_MockValue {
            return mock
        } else {
            fatalError("no mock for `observeFeatureStates`")
        }
    }

    // MARK: - updateFeatureConfig

    public var updateFeatureConfig_Invocations: [FeatureConfig] = []
    public var updateFeatureConfig_MockMethod: ((FeatureConfig) async -> Void)?

    public func updateFeatureConfig(_ featureConfig: FeatureConfig) async {
        updateFeatureConfig_Invocations.append(featureConfig)

        guard let mock = updateFeatureConfig_MockMethod else {
            fatalError("no mock for `updateFeatureConfig`")
        }

        await mock(featureConfig)
    }

    // MARK: - fetchAllowedGlobalOperations

    public var fetchAllowedGlobalOperations_Invocations: [Void] = []
    public var fetchAllowedGlobalOperations_MockError: Error?
    public var fetchAllowedGlobalOperations_MockMethod: (() async throws -> LocalFeature<Feature.AllowedGlobalOperations.Config>)?
    public var fetchAllowedGlobalOperations_MockValue: LocalFeature<Feature.AllowedGlobalOperations.Config>?

    public func fetchAllowedGlobalOperations() async throws -> LocalFeature<Feature.AllowedGlobalOperations.Config> {
        fetchAllowedGlobalOperations_Invocations.append(())

        if let error = fetchAllowedGlobalOperations_MockError {
            throw error
        }

        if let mock = fetchAllowedGlobalOperations_MockMethod {
            return try await mock()
        } else if let mock = fetchAllowedGlobalOperations_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchAllowedGlobalOperations`")
        }
    }

    // MARK: - fetchMLSConfig

    public var fetchMLSConfig_Invocations: [Void] = []
    public var fetchMLSConfig_MockError: Error?
    public var fetchMLSConfig_MockMethod: (() async throws -> LocalFeature<Feature.MLS.Config>)?
    public var fetchMLSConfig_MockValue: LocalFeature<Feature.MLS.Config>?

    public func fetchMLSConfig() async throws -> LocalFeature<Feature.MLS.Config> {
        fetchMLSConfig_Invocations.append(())

        if let error = fetchMLSConfig_MockError {
            throw error
        }

        if let mock = fetchMLSConfig_MockMethod {
            return try await mock()
        } else if let mock = fetchMLSConfig_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchMLSConfig`")
        }
    }

    // MARK: - fetchMLSMigrationConfig

    public var fetchMLSMigrationConfig_Invocations: [Void] = []
    public var fetchMLSMigrationConfig_MockError: Error?
    public var fetchMLSMigrationConfig_MockMethod: (() async throws -> LocalFeature<Feature.MLSMigration.Config>)?
    public var fetchMLSMigrationConfig_MockValue: LocalFeature<Feature.MLSMigration.Config>?

    public func fetchMLSMigrationConfig() async throws -> LocalFeature<Feature.MLSMigration.Config> {
        fetchMLSMigrationConfig_Invocations.append(())

        if let error = fetchMLSMigrationConfig_MockError {
            throw error
        }

        if let mock = fetchMLSMigrationConfig_MockMethod {
            return try await mock()
        } else if let mock = fetchMLSMigrationConfig_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchMLSMigrationConfig`")
        }
    }

    // MARK: - fetchAppLock

    public var fetchAppLock_Invocations: [Void] = []
    public var fetchAppLock_MockError: Error?
    public var fetchAppLock_MockMethod: (() async throws -> LocalFeature<Feature.AppLock.Config>)?
    public var fetchAppLock_MockValue: LocalFeature<Feature.AppLock.Config>?

    public func fetchAppLock() async throws -> LocalFeature<Feature.AppLock.Config> {
        fetchAppLock_Invocations.append(())

        if let error = fetchAppLock_MockError {
            throw error
        }

        if let mock = fetchAppLock_MockMethod {
            return try await mock()
        } else if let mock = fetchAppLock_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchAppLock`")
        }
    }

    // MARK: - fetchCellsInternal

    public var fetchCellsInternal_Invocations: [Void] = []
    public var fetchCellsInternal_MockError: Error?
    public var fetchCellsInternal_MockMethod: (() async throws -> LocalFeature<Feature.CellsInternal.Config>)?
    public var fetchCellsInternal_MockValue: LocalFeature<Feature.CellsInternal.Config>?

    public func fetchCellsInternal() async throws -> LocalFeature<Feature.CellsInternal.Config> {
        fetchCellsInternal_Invocations.append(())

        if let error = fetchCellsInternal_MockError {
            throw error
        }

        if let mock = fetchCellsInternal_MockMethod {
            return try await mock()
        } else if let mock = fetchCellsInternal_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchCellsInternal`")
        }
    }

    // MARK: - isFeatureEnabled

    public var isFeatureEnabled_Invocations: [Feature.Name] = []
    public var isFeatureEnabled_MockMethod: ((Feature.Name) async -> Bool)?
    public var isFeatureEnabled_MockValue: Bool?

    public func isFeatureEnabled(_ feature: Feature.Name) async -> Bool {
        isFeatureEnabled_Invocations.append(feature)

        if let mock = isFeatureEnabled_MockMethod {
            return await mock(feature)
        } else if let mock = isFeatureEnabled_MockValue {
            return mock
        } else {
            fatalError("no mock for `isFeatureEnabled`")
        }
    }

}

class MockGenerateNotificationUseCaseProtocol: GenerateNotificationUseCaseProtocol {

    // MARK: - Life cycle



    // MARK: - invoke

    var invokeUpdateEvents_Invocations: [AsyncStream<[UpdateEvent]>] = []
    var invokeUpdateEvents_MockError: Error?
    var invokeUpdateEvents_MockMethod: ((AsyncStream<[UpdateEvent]>) async throws -> [UserNotification])?
    var invokeUpdateEvents_MockValue: [UserNotification]?

    func invoke(updateEvents: AsyncStream<[UpdateEvent]>) async throws -> [UserNotification] {
        invokeUpdateEvents_Invocations.append(updateEvents)

        if let error = invokeUpdateEvents_MockError {
            throw error
        }

        if let mock = invokeUpdateEvents_MockMethod {
            return try await mock(updateEvents)
        } else if let mock = invokeUpdateEvents_MockValue {
            return mock
        } else {
            fatalError("no mock for `invokeUpdateEvents`")
        }
    }

}

public class MockGeneratorProtocol: GeneratorProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - start

    public var start_Invocations: [Void] = []
    public var start_MockMethod: (() async -> Void)?

    public func start() async {
        start_Invocations.append(())

        guard let mock = start_MockMethod else {
            fatalError("no mock for `start`")
        }

        await mock()
    }

    // MARK: - stop

    public var stop_Invocations: [Void] = []
    public var stop_MockMethod: (() async -> Void)?

    public func stop() async {
        stop_Invocations.append(())

        guard let mock = stop_MockMethod else {
            fatalError("no mock for `stop`")
        }

        await mock()
    }

}

public class MockIncrementalGeneratorProtocol: IncrementalGeneratorProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - start

    public var start_Invocations: [Void] = []
    public var start_MockMethod: (() async -> Void)?

    public func start() async {
        start_Invocations.append(())

        guard let mock = start_MockMethod else {
            fatalError("no mock for `start`")
        }

        await mock()
    }

    // MARK: - stop

    public var stop_Invocations: [Void] = []
    public var stop_MockMethod: (() async -> Void)?

    public func stop() async {
        stop_Invocations.append(())

        guard let mock = stop_MockMethod else {
            fatalError("no mock for `stop`")
        }

        await mock()
    }

}

public class MockIncrementalSyncProtocol: IncrementalSyncProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - perform

    public var perform_Invocations: [Void] = []
    public var perform_MockError: Error?
    public var perform_MockMethod: (() async throws -> IncrementalSync.Token)?
    public var perform_MockValue: IncrementalSync.Token?

    public func perform() async throws -> IncrementalSync.Token {
        perform_Invocations.append(())

        if let error = perform_MockError {
            throw error
        }

        if let mock = perform_MockMethod {
            return try await mock()
        } else if let mock = perform_MockValue {
            return mock
        } else {
            fatalError("no mock for `perform`")
        }
    }

}

public class MockInitialSyncProtocol: InitialSyncProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - perform

    public var performSkipPullingLastUpdateEventID_Invocations: [Bool] = []
    public var performSkipPullingLastUpdateEventID_MockError: Error?
    public var performSkipPullingLastUpdateEventID_MockMethod: ((Bool) async throws -> Void)?

    public func perform(skipPullingLastUpdateEventID: Bool) async throws {
        performSkipPullingLastUpdateEventID_Invocations.append(skipPullingLastUpdateEventID)

        if let error = performSkipPullingLastUpdateEventID_MockError {
            throw error
        }

        guard let mock = performSkipPullingLastUpdateEventID_MockMethod else {
            fatalError("no mock for `performSkipPullingLastUpdateEventID`")
        }

        try await mock(skipPullingLastUpdateEventID)
    }

}

public class MockInitiateResetMLSConversationUseCaseProtocol: InitiateResetMLSConversationUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invokeGroupIDEpoch_Invocations: [(groupID: WireDataModel.MLSGroupID, epoch: UInt64)] = []
    public var invokeGroupIDEpoch_MockMethod: ((WireDataModel.MLSGroupID, UInt64) async -> Void)?

    public func invoke(groupID: WireDataModel.MLSGroupID, epoch: UInt64) async {
        invokeGroupIDEpoch_Invocations.append((groupID: groupID, epoch: epoch))

        guard let mock = invokeGroupIDEpoch_MockMethod else {
            fatalError("no mock for `invokeGroupIDEpoch`")
        }

        await mock(groupID, epoch)
    }

}

public class MockLiveGeneratorProtocol: LiveGeneratorProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - start

    public var start_Invocations: [Void] = []
    public var start_MockMethod: (() async -> Void)?

    public func start() async {
        start_Invocations.append(())

        guard let mock = start_MockMethod else {
            fatalError("no mock for `start`")
        }

        await mock()
    }

    // MARK: - stop

    public var stop_Invocations: [Void] = []
    public var stop_MockMethod: (() async -> Void)?

    public func stop() async {
        stop_Invocations.append(())

        guard let mock = stop_MockMethod else {
            fatalError("no mock for `stop`")
        }

        await mock()
    }

}

public class MockLiveSyncDelegate: LiveSyncDelegate {

    // MARK: - Life cycle

    public init() {}


    // MARK: - isUpToDate

    public var isUpToDateSync_Invocations: [IncrementalSyncV2] = []
    public var isUpToDateSync_MockMethod: ((IncrementalSyncV2) -> Void)?

    public func isUpToDate(sync: IncrementalSyncV2) {
        isUpToDateSync_Invocations.append(sync)

        guard let mock = isUpToDateSync_MockMethod else {
            fatalError("no mock for `isUpToDateSync`")
        }

        mock(sync)
    }

    // MARK: - didMissedEvents

    public var didMissedEventsSync_Invocations: [IncrementalSyncV2] = []
    public var didMissedEventsSync_MockMethod: ((IncrementalSyncV2) async -> Void)?

    public func didMissedEvents(sync: IncrementalSyncV2) async {
        didMissedEventsSync_Invocations.append(sync)

        guard let mock = didMissedEventsSync_MockMethod else {
            fatalError("no mock for `didMissedEventsSync`")
        }

        await mock(sync)
    }

    // MARK: - didFail

    public var didFailSyncError_Invocations: [(sync: IncrementalSyncV2, error: any Error)] = []
    public var didFailSyncError_MockMethod: ((IncrementalSyncV2, any Error) -> Void)?

    public func didFail(sync: IncrementalSyncV2, error: any Error) {
        didFailSyncError_Invocations.append((sync: sync, error: error))

        guard let mock = didFailSyncError_MockMethod else {
            fatalError("no mock for `didFailSyncError`")
        }

        mock(sync, error)
    }

    // MARK: - didStart

    public var didStartSync_Invocations: [IncrementalSyncV2] = []
    public var didStartSync_MockMethod: ((IncrementalSyncV2) -> Void)?

    public func didStart(sync: IncrementalSyncV2) {
        didStartSync_Invocations.append(sync)

        guard let mock = didStartSync_MockMethod else {
            fatalError("no mock for `didStartSync`")
        }

        mock(sync)
    }

}

public class MockLiveSyncProtocol: LiveSyncProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - perform

    public var perform_Invocations: [Void] = []
    public var perform_MockError: Error?
    public var perform_MockMethod: (() async throws -> IncrementalSync.Token)?
    public var perform_MockValue: IncrementalSync.Token?

    public func perform() async throws -> IncrementalSync.Token {
        perform_Invocations.append(())

        if let error = perform_MockError {
            throw error
        }

        if let mock = perform_MockMethod {
            return try await mock()
        } else if let mock = perform_MockValue {
            return mock
        } else {
            fatalError("no mock for `perform`")
        }
    }

}

public class MockMLSGroupRepairAgentProtocol: MLSGroupRepairAgentProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - repairConversations

    public var repairConversations_Invocations: [Void] = []
    public var repairConversations_MockMethod: (() async -> Void)?

    public func repairConversations() async {
        repairConversations_Invocations.append(())

        guard let mock = repairConversations_MockMethod else {
            fatalError("no mock for `repairConversations`")
        }

        await mock()
    }

}

class MockMLSMessageDecryptorProtocol: MLSMessageDecryptorProtocol {

    // MARK: - Life cycle



    // MARK: - decryptedMessageAddEventData

    var decryptedMessageAddEventDataFromContext_Invocations: [(eventData: ConversationMLSMessageAddEvent, context: CoreCryptoContextProtocol?)] = []
    var decryptedMessageAddEventDataFromContext_MockError: Error?
    var decryptedMessageAddEventDataFromContext_MockMethod: ((ConversationMLSMessageAddEvent, CoreCryptoContextProtocol?) async throws -> ConversationMLSMessageAddEvent)?
    var decryptedMessageAddEventDataFromContext_MockValue: ConversationMLSMessageAddEvent?

    func decryptedMessageAddEventData(from eventData: ConversationMLSMessageAddEvent, context: CoreCryptoContextProtocol?) async throws -> ConversationMLSMessageAddEvent {
        decryptedMessageAddEventDataFromContext_Invocations.append((eventData: eventData, context: context))

        if let error = decryptedMessageAddEventDataFromContext_MockError {
            throw error
        }

        if let mock = decryptedMessageAddEventDataFromContext_MockMethod {
            return try await mock(eventData, context)
        } else if let mock = decryptedMessageAddEventDataFromContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptedMessageAddEventDataFromContext`")
        }
    }

    // MARK: - decryptedWelcomeMessageEventData

    var decryptedWelcomeMessageEventDataFromContext_Invocations: [(eventData: ConversationMLSWelcomeEvent, context: CoreCryptoContextProtocol?)] = []
    var decryptedWelcomeMessageEventDataFromContext_MockError: Error?
    var decryptedWelcomeMessageEventDataFromContext_MockMethod: ((ConversationMLSWelcomeEvent, CoreCryptoContextProtocol?) async throws -> Void)?

    func decryptedWelcomeMessageEventData(from eventData: ConversationMLSWelcomeEvent, context: CoreCryptoContextProtocol?) async throws {
        decryptedWelcomeMessageEventDataFromContext_Invocations.append((eventData: eventData, context: context))

        if let error = decryptedWelcomeMessageEventDataFromContext_MockError {
            throw error
        }

        guard let mock = decryptedWelcomeMessageEventDataFromContext_MockMethod else {
            fatalError("no mock for `decryptedWelcomeMessageEventDataFromContext`")
        }

        try await mock(eventData, context)
    }

}

public class MockMainAppPushChannelCoordinatorProtocol: MainAppPushChannelCoordinatorProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - signalToExtensionsToYieldPushChannel

    public var signalToExtensionsToYieldPushChannel_Invocations: [Void] = []
    public var signalToExtensionsToYieldPushChannel_MockMethod: (() async -> Void)?

    public func signalToExtensionsToYieldPushChannel() async {
        signalToExtensionsToYieldPushChannel_Invocations.append(())

        guard let mock = signalToExtensionsToYieldPushChannel_MockMethod else {
            fatalError("no mock for `signalToExtensionsToYieldPushChannel`")
        }

        await mock()
    }

}

public class MockMessageLocalStoreProtocol: MessageLocalStoreProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - addSystemMessage

    public var addSystemMessageMessageTypeConversationIDConversationDomain_Invocations: [(messageType: SystemMessageType, conversationID: UUID, conversationDomain: String?)] = []
    public var addSystemMessageMessageTypeConversationIDConversationDomain_MockMethod: ((SystemMessageType, UUID, String?) async -> Void)?

    public func addSystemMessage(messageType: SystemMessageType, conversationID: UUID, conversationDomain: String?) async {
        addSystemMessageMessageTypeConversationIDConversationDomain_Invocations.append((messageType: messageType, conversationID: conversationID, conversationDomain: conversationDomain))

        guard let mock = addSystemMessageMessageTypeConversationIDConversationDomain_MockMethod else {
            fatalError("no mock for `addSystemMessageMessageTypeConversationIDConversationDomain`")
        }

        await mock(messageType, conversationID, conversationDomain)
    }

    // MARK: - addPotentialGapSystemMessage

    public var addPotentialGapSystemMessage_Invocations: [Void] = []
    public var addPotentialGapSystemMessage_MockError: Error?
    public var addPotentialGapSystemMessage_MockMethod: (() async throws -> Void)?

    public func addPotentialGapSystemMessage() async throws {
        addPotentialGapSystemMessage_Invocations.append(())

        if let error = addPotentialGapSystemMessage_MockError {
            throw error
        }

        guard let mock = addPotentialGapSystemMessage_MockMethod else {
            fatalError("no mock for `addPotentialGapSystemMessage`")
        }

        try await mock()
    }

    // MARK: - fetchOrCreateClientMessage

    public var fetchOrCreateClientMessageIdConversationSenderDate_Invocations: [(id: String, conversation: ZMConversation, sender: (id: UUID, domain: String, clientID: String?), date: Date)] = []
    public var fetchOrCreateClientMessageIdConversationSenderDate_MockError: Error?
    public var fetchOrCreateClientMessageIdConversationSenderDate_MockMethod: ((String, ZMConversation, (id: UUID, domain: String, clientID: String?), Date) async throws -> (ZMClientMessage, isNew: Bool))?
    public var fetchOrCreateClientMessageIdConversationSenderDate_MockValue: (ZMClientMessage, isNew: Bool)?

    public func fetchOrCreateClientMessage(id: String, conversation: ZMConversation, sender: (id: UUID, domain: String, clientID: String?), date: Date) async throws -> (ZMClientMessage, isNew: Bool) {
        fetchOrCreateClientMessageIdConversationSenderDate_Invocations.append((id: id, conversation: conversation, sender: sender, date: date))

        if let error = fetchOrCreateClientMessageIdConversationSenderDate_MockError {
            throw error
        }

        if let mock = fetchOrCreateClientMessageIdConversationSenderDate_MockMethod {
            return try await mock(id, conversation, sender, date)
        } else if let mock = fetchOrCreateClientMessageIdConversationSenderDate_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateClientMessageIdConversationSenderDate`")
        }
    }

    // MARK: - fetchOrCreateAssetClientMessage

    public var fetchOrCreateAssetClientMessageIdConversationSenderDate_Invocations: [(id: String, conversation: ZMConversation, sender: (id: UUID, domain: String, clientID: String?), date: Date)] = []
    public var fetchOrCreateAssetClientMessageIdConversationSenderDate_MockError: Error?
    public var fetchOrCreateAssetClientMessageIdConversationSenderDate_MockMethod: ((String, ZMConversation, (id: UUID, domain: String, clientID: String?), Date) async throws -> (ZMAssetClientMessage, isNew: Bool))?
    public var fetchOrCreateAssetClientMessageIdConversationSenderDate_MockValue: (ZMAssetClientMessage, isNew: Bool)?

    public func fetchOrCreateAssetClientMessage(id: String, conversation: ZMConversation, sender: (id: UUID, domain: String, clientID: String?), date: Date) async throws -> (ZMAssetClientMessage, isNew: Bool) {
        fetchOrCreateAssetClientMessageIdConversationSenderDate_Invocations.append((id: id, conversation: conversation, sender: sender, date: date))

        if let error = fetchOrCreateAssetClientMessageIdConversationSenderDate_MockError {
            throw error
        }

        if let mock = fetchOrCreateAssetClientMessageIdConversationSenderDate_MockMethod {
            return try await mock(id, conversation, sender, date)
        } else if let mock = fetchOrCreateAssetClientMessageIdConversationSenderDate_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateAssetClientMessageIdConversationSenderDate`")
        }
    }

    // MARK: - addClientMessage

    public var addClientMessageIsNewMessageGenericMessageConversationSenderIDSenderDomain_Invocations: [(clientMessage: ZMClientMessage, isNewMessage: Bool, genericMessage: GenericMessage, conversation: ZMConversation, senderID: UUID, senderDomain: String)] = []
    public var addClientMessageIsNewMessageGenericMessageConversationSenderIDSenderDomain_MockMethod: ((ZMClientMessage, Bool, GenericMessage, ZMConversation, UUID, String) async -> Void)?

    public func addClientMessage(_ clientMessage: ZMClientMessage, isNewMessage: Bool, genericMessage: GenericMessage, conversation: ZMConversation, senderID: UUID, senderDomain: String) async {
        addClientMessageIsNewMessageGenericMessageConversationSenderIDSenderDomain_Invocations.append((clientMessage: clientMessage, isNewMessage: isNewMessage, genericMessage: genericMessage, conversation: conversation, senderID: senderID, senderDomain: senderDomain))

        guard let mock = addClientMessageIsNewMessageGenericMessageConversationSenderIDSenderDomain_MockMethod else {
            fatalError("no mock for `addClientMessageIsNewMessageGenericMessageConversationSenderIDSenderDomain`")
        }

        await mock(clientMessage, isNewMessage, genericMessage, conversation, senderID, senderDomain)
    }

    // MARK: - addAssetClientMessage

    public var addAssetClientMessageIsNewMessageGenericMessageConversationSenderIDSenderDomain_Invocations: [(assetClientMessage: ZMAssetClientMessage, isNewMessage: Bool, genericMessage: GenericMessage, conversation: ZMConversation, senderID: UUID, senderDomain: String)] = []
    public var addAssetClientMessageIsNewMessageGenericMessageConversationSenderIDSenderDomain_MockMethod: ((ZMAssetClientMessage, Bool, GenericMessage, ZMConversation, UUID, String) async -> Void)?

    public func addAssetClientMessage(_ assetClientMessage: ZMAssetClientMessage, isNewMessage: Bool, genericMessage: GenericMessage, conversation: ZMConversation, senderID: UUID, senderDomain: String) async {
        addAssetClientMessageIsNewMessageGenericMessageConversationSenderIDSenderDomain_Invocations.append((assetClientMessage: assetClientMessage, isNewMessage: isNewMessage, genericMessage: genericMessage, conversation: conversation, senderID: senderID, senderDomain: senderDomain))

        guard let mock = addAssetClientMessageIsNewMessageGenericMessageConversationSenderIDSenderDomain_MockMethod else {
            fatalError("no mock for `addAssetClientMessageIsNewMessageGenericMessageConversationSenderIDSenderDomain`")
        }

        await mock(assetClientMessage, isNewMessage, genericMessage, conversation, senderID, senderDomain)
    }

    // MARK: - addUnknownMessage

    public var addUnknownMessageMessageIDConversationIDConversationDomainSenderIDSenderDomainPayloadDate_Invocations: [(messageID: UUID, conversationID: UUID, conversationDomain: String?, senderID: UUID, senderDomain: String, payload: Data, date: Date)] = []
    public var addUnknownMessageMessageIDConversationIDConversationDomainSenderIDSenderDomainPayloadDate_MockMethod: ((UUID, UUID, String?, UUID, String, Data, Date) async -> Void)?

    public func addUnknownMessage(messageID: UUID, conversationID: UUID, conversationDomain: String?, senderID: UUID, senderDomain: String, payload: Data, date: Date) async {
        addUnknownMessageMessageIDConversationIDConversationDomainSenderIDSenderDomainPayloadDate_Invocations.append((messageID: messageID, conversationID: conversationID, conversationDomain: conversationDomain, senderID: senderID, senderDomain: senderDomain, payload: payload, date: date))

        guard let mock = addUnknownMessageMessageIDConversationIDConversationDomainSenderIDSenderDomainPayloadDate_MockMethod else {
            fatalError("no mock for `addUnknownMessageMessageIDConversationIDConversationDomainSenderIDSenderDomainPayloadDate`")
        }

        await mock(messageID, conversationID, conversationDomain, senderID, senderDomain, payload, date)
    }

    // MARK: - canAddMessage

    public var canAddMessageConversationSenderID_Invocations: [(conversation: ZMConversation, senderID: UUID)] = []
    public var canAddMessageConversationSenderID_MockMethod: ((ZMConversation, UUID) async -> Bool)?
    public var canAddMessageConversationSenderID_MockValue: Bool?

    public func canAddMessage(conversation: ZMConversation, senderID: UUID) async -> Bool {
        canAddMessageConversationSenderID_Invocations.append((conversation: conversation, senderID: senderID))

        if let mock = canAddMessageConversationSenderID_MockMethod {
            return await mock(conversation, senderID)
        } else if let mock = canAddMessageConversationSenderID_MockValue {
            return mock
        } else {
            fatalError("no mock for `canAddMessageConversationSenderID`")
        }
    }

    // MARK: - deleteMessageForSelf

    public var deleteMessageForSelfIn_Invocations: [(hiddenMessage: MessageHide, conversation: ZMConversation)] = []
    public var deleteMessageForSelfIn_MockMethod: ((MessageHide, ZMConversation) async -> Void)?

    public func deleteMessageForSelf(_ hiddenMessage: MessageHide, in conversation: ZMConversation) async {
        deleteMessageForSelfIn_Invocations.append((hiddenMessage: hiddenMessage, conversation: conversation))

        guard let mock = deleteMessageForSelfIn_MockMethod else {
            fatalError("no mock for `deleteMessageForSelfIn`")
        }

        await mock(hiddenMessage, conversation)
    }

    // MARK: - deleteMessageForEveryone

    public var deleteMessageForEveryoneInSenderID_Invocations: [(deletedMessage: MessageDelete, conversation: ZMConversation, senderID: UUID)] = []
    public var deleteMessageForEveryoneInSenderID_MockMethod: ((MessageDelete, ZMConversation, UUID) async -> Void)?

    public func deleteMessageForEveryone(_ deletedMessage: MessageDelete, in conversation: ZMConversation, senderID: UUID) async {
        deleteMessageForEveryoneInSenderID_Invocations.append((deletedMessage: deletedMessage, conversation: conversation, senderID: senderID))

        guard let mock = deleteMessageForEveryoneInSenderID_MockMethod else {
            fatalError("no mock for `deleteMessageForEveryoneInSenderID`")
        }

        await mock(deletedMessage, conversation, senderID)
    }

    // MARK: - addMessageReaction

    public var addMessageReactionInSenderIDDate_Invocations: [(messageReaction: GenericMessageProtocol.Reaction, conversation: ZMConversation, senderID: UUID, date: Date)] = []
    public var addMessageReactionInSenderIDDate_MockMethod: ((GenericMessageProtocol.Reaction, ZMConversation, UUID, Date) async -> Void)?

    public func addMessageReaction(_ messageReaction: GenericMessageProtocol.Reaction, in conversation: ZMConversation, senderID: UUID, date: Date) async {
        addMessageReactionInSenderIDDate_Invocations.append((messageReaction: messageReaction, conversation: conversation, senderID: senderID, date: date))

        guard let mock = addMessageReactionInSenderIDDate_MockMethod else {
            fatalError("no mock for `addMessageReactionInSenderIDDate`")
        }

        await mock(messageReaction, conversation, senderID, date)
    }

    // MARK: - addMessageConfirmation

    public var addMessageConfirmationInSenderIDSenderDomainDate_Invocations: [(confirmation: GenericMessageProtocol.Confirmation, conversation: ZMConversation, senderID: UUID, senderDomain: String, date: Date)] = []
    public var addMessageConfirmationInSenderIDSenderDomainDate_MockMethod: ((GenericMessageProtocol.Confirmation, ZMConversation, UUID, String, Date) async -> Void)?

    public func addMessageConfirmation(_ confirmation: GenericMessageProtocol.Confirmation, in conversation: ZMConversation, senderID: UUID, senderDomain: String, date: Date) async {
        addMessageConfirmationInSenderIDSenderDomainDate_Invocations.append((confirmation: confirmation, conversation: conversation, senderID: senderID, senderDomain: senderDomain, date: date))

        guard let mock = addMessageConfirmationInSenderIDSenderDomainDate_MockMethod else {
            fatalError("no mock for `addMessageConfirmationInSenderIDSenderDomainDate`")
        }

        await mock(confirmation, conversation, senderID, senderDomain, date)
    }

    // MARK: - updateButtonStates

    public var updateButtonStatesButtonIDReferenceMessageIDInSenderID_Invocations: [(buttonID: String?, referenceMessageID: String, conversation: ZMConversation, senderID: UUID)] = []
    public var updateButtonStatesButtonIDReferenceMessageIDInSenderID_MockMethod: ((String?, String, ZMConversation, UUID) async -> Void)?

    public func updateButtonStates(buttonID: String?, referenceMessageID: String, in conversation: ZMConversation, senderID: UUID) async {
        updateButtonStatesButtonIDReferenceMessageIDInSenderID_Invocations.append((buttonID: buttonID, referenceMessageID: referenceMessageID, conversation: conversation, senderID: senderID))

        guard let mock = updateButtonStatesButtonIDReferenceMessageIDInSenderID_MockMethod else {
            fatalError("no mock for `updateButtonStatesButtonIDReferenceMessageIDInSenderID`")
        }

        await mock(buttonID, referenceMessageID, conversation, senderID)
    }

    // MARK: - editMessage

    public var editMessageInSenderIDGenericMessageDate_Invocations: [(messageEdit: MessageEdit, conversation: ZMConversation, senderID: UUID, genericMessage: GenericMessage, date: Date)] = []
    public var editMessageInSenderIDGenericMessageDate_MockMethod: ((MessageEdit, ZMConversation, UUID, GenericMessage, Date) async -> Void)?

    public func editMessage(_ messageEdit: MessageEdit, in conversation: ZMConversation, senderID: UUID, genericMessage: GenericMessage, date: Date) async {
        editMessageInSenderIDGenericMessageDate_Invocations.append((messageEdit: messageEdit, conversation: conversation, senderID: senderID, genericMessage: genericMessage, date: date))

        guard let mock = editMessageInSenderIDGenericMessageDate_MockMethod else {
            fatalError("no mock for `editMessageInSenderIDGenericMessageDate`")
        }

        await mock(messageEdit, conversation, senderID, genericMessage, date)
    }

    // MARK: - fetchMessage

    public var fetchMessageIdConversationIDConversationDomain_Invocations: [(id: UUID?, conversationID: UUID, conversationDomain: String?)] = []
    public var fetchMessageIdConversationIDConversationDomain_MockMethod: ((UUID?, UUID, String?) async -> ZMOTRMessage?)?
    public var fetchMessageIdConversationIDConversationDomain_MockValue: ZMOTRMessage??

    public func fetchMessage(id: UUID?, conversationID: UUID, conversationDomain: String?) async -> ZMOTRMessage? {
        fetchMessageIdConversationIDConversationDomain_Invocations.append((id: id, conversationID: conversationID, conversationDomain: conversationDomain))

        if let mock = fetchMessageIdConversationIDConversationDomain_MockMethod {
            return await mock(id, conversationID, conversationDomain)
        } else if let mock = fetchMessageIdConversationIDConversationDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchMessageIdConversationIDConversationDomain`")
        }
    }

    // MARK: - isMessageMentioningSelf

    public var isMessageMentioningSelfText_Invocations: [Text] = []
    public var isMessageMentioningSelfText_MockMethod: ((Text) async -> Bool)?
    public var isMessageMentioningSelfText_MockValue: Bool?

    public func isMessageMentioningSelf(text: Text) async -> Bool {
        isMessageMentioningSelfText_Invocations.append(text)

        if let mock = isMessageMentioningSelfText_MockMethod {
            return await mock(text)
        } else if let mock = isMessageMentioningSelfText_MockValue {
            return mock
        } else {
            fatalError("no mock for `isMessageMentioningSelfText`")
        }
    }

    // MARK: - isMessageQuotingSelf

    public var isMessageQuotingSelfQuotedMessage_Invocations: [ZMOTRMessage?] = []
    public var isMessageQuotingSelfQuotedMessage_MockMethod: ((ZMOTRMessage?) async -> Bool)?
    public var isMessageQuotingSelfQuotedMessage_MockValue: Bool?

    public func isMessageQuotingSelf(quotedMessage: ZMOTRMessage?) async -> Bool {
        isMessageQuotingSelfQuotedMessage_Invocations.append(quotedMessage)

        if let mock = isMessageQuotingSelfQuotedMessage_MockMethod {
            return await mock(quotedMessage)
        } else if let mock = isMessageQuotingSelfQuotedMessage_MockValue {
            return mock
        } else {
            fatalError("no mock for `isMessageQuotingSelfQuotedMessage`")
        }
    }

}

public class MockMessageRepositoryProtocol: MessageRepositoryProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - addSystemMessage

    public var addSystemMessageMessageTypeConversationIDConversationDomain_Invocations: [(messageType: SystemMessageType, conversationID: UUID, conversationDomain: String?)] = []
    public var addSystemMessageMessageTypeConversationIDConversationDomain_MockMethod: ((SystemMessageType, UUID, String?) async -> Void)?

    public func addSystemMessage(messageType: SystemMessageType, conversationID: UUID, conversationDomain: String?) async {
        addSystemMessageMessageTypeConversationIDConversationDomain_Invocations.append((messageType: messageType, conversationID: conversationID, conversationDomain: conversationDomain))

        guard let mock = addSystemMessageMessageTypeConversationIDConversationDomain_MockMethod else {
            fatalError("no mock for `addSystemMessageMessageTypeConversationIDConversationDomain`")
        }

        await mock(messageType, conversationID, conversationDomain)
    }

}

public class MockOneOnOneResolverProtocol: OneOnOneResolverProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - resolveOneOnOneConversation

    public var resolveOneOnOneConversationWith_Invocations: [WireDataModel.QualifiedID] = []
    public var resolveOneOnOneConversationWith_MockError: Error?
    public var resolveOneOnOneConversationWith_MockMethod: ((WireDataModel.QualifiedID) async throws -> OneOnOneConversationResolution)?
    public var resolveOneOnOneConversationWith_MockValue: OneOnOneConversationResolution?

    public func resolveOneOnOneConversation(with userID: WireDataModel.QualifiedID) async throws -> OneOnOneConversationResolution {
        resolveOneOnOneConversationWith_Invocations.append(userID)

        if let error = resolveOneOnOneConversationWith_MockError {
            throw error
        }

        if let mock = resolveOneOnOneConversationWith_MockMethod {
            return try await mock(userID)
        } else if let mock = resolveOneOnOneConversationWith_MockValue {
            return mock
        } else {
            fatalError("no mock for `resolveOneOnOneConversationWith`")
        }
    }

    // MARK: - resolveAllOneOnOneConversations

    public var resolveAllOneOnOneConversations_Invocations: [Void] = []
    public var resolveAllOneOnOneConversations_MockError: Error?
    public var resolveAllOneOnOneConversations_MockMethod: (() async throws -> Void)?

    public func resolveAllOneOnOneConversations() async throws {
        resolveAllOneOnOneConversations_Invocations.append(())

        if let error = resolveAllOneOnOneConversations_MockError {
            throw error
        }

        guard let mock = resolveAllOneOnOneConversations_MockMethod else {
            fatalError("no mock for `resolveAllOneOnOneConversations`")
        }

        try await mock()
    }

}

public class MockProcessNotificationUseCaseProtocol: ProcessNotificationUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invokeRequest_Invocations: [UNNotificationRequest] = []
    public var invokeRequest_MockError: Error?
    public var invokeRequest_MockMethod: ((UNNotificationRequest) throws -> NotificationPayload)?
    public var invokeRequest_MockValue: NotificationPayload?

    public func invoke(request: UNNotificationRequest) throws -> NotificationPayload {
        invokeRequest_Invocations.append(request)

        if let error = invokeRequest_MockError {
            throw error
        }

        if let mock = invokeRequest_MockMethod {
            return try mock(request)
        } else if let mock = invokeRequest_MockValue {
            return mock
        } else {
            fatalError("no mock for `invokeRequest`")
        }
    }

}

class MockProteusMessageDecryptorProtocol: ProteusMessageDecryptorProtocol {

    // MARK: - Life cycle



    // MARK: - decryptedEventData

    var decryptedEventDataFromContext_Invocations: [(eventData: ConversationProteusMessageAddEvent, context: CoreCryptoContextProtocol?)] = []
    var decryptedEventDataFromContext_MockError: Error?
    var decryptedEventDataFromContext_MockMethod: ((ConversationProteusMessageAddEvent, CoreCryptoContextProtocol?) async throws -> ConversationProteusMessageAddEvent)?
    var decryptedEventDataFromContext_MockValue: ConversationProteusMessageAddEvent?

    func decryptedEventData(from eventData: ConversationProteusMessageAddEvent, context: CoreCryptoContextProtocol?) async throws -> ConversationProteusMessageAddEvent {
        decryptedEventDataFromContext_Invocations.append((eventData: eventData, context: context))

        if let error = decryptedEventDataFromContext_MockError {
            throw error
        }

        if let mock = decryptedEventDataFromContext_MockMethod {
            return try await mock(eventData, context)
        } else if let mock = decryptedEventDataFromContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptedEventDataFromContext`")
        }
    }

}

public class MockPullAllConversationsSyncProtocol: PullAllConversationsSyncProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - pull

    public var pull_Invocations: [Void] = []
    public var pull_MockError: Error?
    public var pull_MockMethod: (() async throws -> Void)?

    public func pull() async throws {
        pull_Invocations.append(())

        if let error = pull_MockError {
            throw error
        }

        guard let mock = pull_MockMethod else {
            fatalError("no mock for `pull`")
        }

        try await mock()
    }

}

class MockPullAllFeatureConfigsSyncProtocol: PullAllFeatureConfigsSyncProtocol {

    // MARK: - Life cycle



    // MARK: - pull

    var pull_Invocations: [Void] = []
    var pull_MockError: Error?
    var pull_MockMethod: (() async throws -> Void)?

    func pull() async throws {
        pull_Invocations.append(())

        if let error = pull_MockError {
            throw error
        }

        guard let mock = pull_MockMethod else {
            fatalError("no mock for `pull`")
        }

        try await mock()
    }

}

class MockPullConversationLabelsSyncProtocol: PullConversationLabelsSyncProtocol {

    // MARK: - Life cycle



    // MARK: - pull

    var pull_Invocations: [Void] = []
    var pull_MockError: Error?
    var pull_MockMethod: (() async throws -> Void)?

    func pull() async throws {
        pull_Invocations.append(())

        if let error = pull_MockError {
            throw error
        }

        guard let mock = pull_MockMethod else {
            fatalError("no mock for `pull`")
        }

        try await mock()
    }

}

class MockPullEventsUseCaseProtocol: PullEventsUseCaseProtocol {

    // MARK: - Life cycle



    // MARK: - invoke

    var invoke_Invocations: [Void] = []
    var invoke_MockError: Error?
    var invoke_MockMethod: (() async throws -> AsyncStream<[UpdateEvent]>)?
    var invoke_MockValue: AsyncStream<[UpdateEvent]>?

    func invoke() async throws -> AsyncStream<[UpdateEvent]> {
        invoke_Invocations.append(())

        if let error = invoke_MockError {
            throw error
        }

        if let mock = invoke_MockMethod {
            return try await mock()
        } else if let mock = invoke_MockValue {
            return mock
        } else {
            fatalError("no mock for `invoke`")
        }
    }

}

class MockPullKnownUsersSyncProtocol: PullKnownUsersSyncProtocol {

    // MARK: - Life cycle



    // MARK: - pull

    var pull_Invocations: [Void] = []
    var pull_MockError: Error?
    var pull_MockMethod: (() async throws -> Void)?

    func pull() async throws {
        pull_Invocations.append(())

        if let error = pull_MockError {
            throw error
        }

        guard let mock = pull_MockMethod else {
            fatalError("no mock for `pull`")
        }

        try await mock()
    }

}

public class MockPullLastUpdateEventIDSyncProtocol: PullLastUpdateEventIDSyncProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - pull

    public var pull_Invocations: [Void] = []
    public var pull_MockError: Error?
    public var pull_MockMethod: (() async throws -> Void)?

    public func pull() async throws {
        pull_Invocations.append(())

        if let error = pull_MockError {
            throw error
        }

        guard let mock = pull_MockMethod else {
            fatalError("no mock for `pull`")
        }

        try await mock()
    }

}

public class MockPullMLSOneOnOneSyncProtocol: PullMLSOneOnOneSyncProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - pull

    public var pullUserIDUserDomain_Invocations: [(userID: UUID, userDomain: String)] = []
    public var pullUserIDUserDomain_MockError: Error?
    public var pullUserIDUserDomain_MockMethod: ((UUID, String) async throws -> (MLSGroupID, MLSPublicKeys?))?
    public var pullUserIDUserDomain_MockValue: (MLSGroupID, MLSPublicKeys?)?

    public func pull(userID: UUID, userDomain: String) async throws -> (MLSGroupID, MLSPublicKeys?) {
        pullUserIDUserDomain_Invocations.append((userID: userID, userDomain: userDomain))

        if let error = pullUserIDUserDomain_MockError {
            throw error
        }

        if let mock = pullUserIDUserDomain_MockMethod {
            return try await mock(userID, userDomain)
        } else if let mock = pullUserIDUserDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `pullUserIDUserDomain`")
        }
    }

}

public class MockPullMLSStatusSyncProtocol: PullMLSStatusSyncProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - pull

    public var pull_Invocations: [Void] = []
    public var pull_MockError: Error?
    public var pull_MockMethod: (() async throws -> Void)?

    public func pull() async throws {
        pull_Invocations.append(())

        if let error = pull_MockError {
            throw error
        }

        guard let mock = pull_MockMethod else {
            fatalError("no mock for `pull`")
        }

        try await mock()
    }

}

public class MockPullPendingUpdateEventsSyncProtocol: PullPendingUpdateEventsSyncProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - pull

    public var pull_Invocations: [Void] = []
    public var pull_MockError: Error?
    public var pull_MockMethod: (() async throws -> AsyncStream<[UpdateEvent]>)?
    public var pull_MockValue: AsyncStream<[UpdateEvent]>?

    @discardableResult
    public func pull() async throws -> AsyncStream<[UpdateEvent]> {
        pull_Invocations.append(())

        if let error = pull_MockError {
            throw error
        }

        if let mock = pull_MockMethod {
            return try await mock()
        } else if let mock = pull_MockValue {
            return mock
        } else {
            fatalError("no mock for `pull`")
        }
    }

}

public class MockPullPendingUpdateEventsSyncV2Protocol: PullPendingUpdateEventsSyncV2Protocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - pull

    public var pull_Invocations: [Void] = []
    public var pull_MockError: Error?
    public var pull_MockMethod: (() async throws -> Void)?

    public func pull() async throws {
        pull_Invocations.append(())

        if let error = pull_MockError {
            throw error
        }

        guard let mock = pull_MockMethod else {
            fatalError("no mock for `pull`")
        }

        try await mock()
    }

}

public class MockPullResourcesSyncProtocol: PullResourcesSyncProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - pull

    public var pull_Invocations: [Void] = []
    public var pull_MockError: Error?
    public var pull_MockMethod: (() async throws -> Void)?

    public func pull() async throws {
        pull_Invocations.append(())

        if let error = pull_MockError {
            throw error
        }

        guard let mock = pull_MockMethod else {
            fatalError("no mock for `pull`")
        }

        try await mock()
    }

}

class MockPullSelfLegalholdInfoSyncProtocol: PullSelfLegalholdInfoSyncProtocol {

    // MARK: - Life cycle



    // MARK: - pull

    var pullSelfTeamID_Invocations: [UUID] = []
    var pullSelfTeamID_MockError: Error?
    var pullSelfTeamID_MockMethod: ((UUID) async throws -> Void)?

    func pull(selfTeamID: UUID) async throws {
        pullSelfTeamID_Invocations.append(selfTeamID)

        if let error = pullSelfTeamID_MockError {
            throw error
        }

        guard let mock = pullSelfTeamID_MockMethod else {
            fatalError("no mock for `pullSelfTeamID`")
        }

        try await mock(selfTeamID)
    }

}

class MockPullSelfTeamMembersSyncProtocol: PullSelfTeamMembersSyncProtocol {

    // MARK: - Life cycle



    // MARK: - pull

    var pullSelfTeamID_Invocations: [UUID] = []
    var pullSelfTeamID_MockError: Error?
    var pullSelfTeamID_MockMethod: ((UUID) async throws -> Void)?

    func pull(selfTeamID: UUID) async throws {
        pullSelfTeamID_Invocations.append(selfTeamID)

        if let error = pullSelfTeamID_MockError {
            throw error
        }

        guard let mock = pullSelfTeamID_MockMethod else {
            fatalError("no mock for `pullSelfTeamID`")
        }

        try await mock(selfTeamID)
    }

}

class MockPullSelfTeamRolesSyncProtocol: PullSelfTeamRolesSyncProtocol {

    // MARK: - Life cycle



    // MARK: - pull

    var pullSelfTeamID_Invocations: [UUID] = []
    var pullSelfTeamID_MockError: Error?
    var pullSelfTeamID_MockMethod: ((UUID) async throws -> Void)?

    func pull(selfTeamID: UUID) async throws {
        pullSelfTeamID_Invocations.append(selfTeamID)

        if let error = pullSelfTeamID_MockError {
            throw error
        }

        guard let mock = pullSelfTeamID_MockMethod else {
            fatalError("no mock for `pullSelfTeamID`")
        }

        try await mock(selfTeamID)
    }

}

class MockPullSelfTeamSyncProtocol: PullSelfTeamSyncProtocol {

    // MARK: - Life cycle



    // MARK: - pull

    var pullSelfTeamID_Invocations: [UUID] = []
    var pullSelfTeamID_MockError: Error?
    var pullSelfTeamID_MockMethod: ((UUID) async throws -> Void)?

    func pull(selfTeamID: UUID) async throws {
        pullSelfTeamID_Invocations.append(selfTeamID)

        if let error = pullSelfTeamID_MockError {
            throw error
        }

        guard let mock = pullSelfTeamID_MockMethod else {
            fatalError("no mock for `pullSelfTeamID`")
        }

        try await mock(selfTeamID)
    }

}

public class MockPullSelfUserClientsSyncProtocol: PullSelfUserClientsSyncProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - pull

    public var pull_Invocations: [Void] = []
    public var pull_MockError: Error?
    public var pull_MockMethod: (() async throws -> Void)?

    public func pull() async throws {
        pull_Invocations.append(())

        if let error = pull_MockError {
            throw error
        }

        guard let mock = pull_MockMethod else {
            fatalError("no mock for `pull`")
        }

        try await mock()
    }

}

class MockPullSelfUserSettingsSyncProtocol: PullSelfUserSettingsSyncProtocol {

    // MARK: - Life cycle



    // MARK: - pull

    var pull_Invocations: [Void] = []
    var pull_MockError: Error?
    var pull_MockMethod: (() async throws -> Void)?

    func pull() async throws {
        pull_Invocations.append(())

        if let error = pull_MockError {
            throw error
        }

        guard let mock = pull_MockMethod else {
            fatalError("no mock for `pull`")
        }

        try await mock()
    }

}

class MockPullSelfUserSyncProtocol: PullSelfUserSyncProtocol {

    // MARK: - Life cycle



    // MARK: - pull

    var pull_Invocations: [Void] = []
    var pull_MockError: Error?
    var pull_MockMethod: (() async throws -> (id: UUID, domain: String?, teamID: UUID?))?
    var pull_MockValue: (id: UUID, domain: String?, teamID: UUID?)?

    @discardableResult
    func pull() async throws -> (id: UUID, domain: String?, teamID: UUID?) {
        pull_Invocations.append(())

        if let error = pull_MockError {
            throw error
        }

        if let mock = pull_MockMethod {
            return try await mock()
        } else if let mock = pull_MockValue {
            return mock
        } else {
            fatalError("no mock for `pull`")
        }
    }

}

public class MockPullServerTimeSyncProtocol: PullServerTimeSyncProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - pull

    public var pull_Invocations: [Void] = []
    public var pull_MockError: Error?
    public var pull_MockMethod: (() async throws -> Void)?

    public func pull() async throws {
        pull_Invocations.append(())

        if let error = pull_MockError {
            throw error
        }

        guard let mock = pull_MockMethod else {
            fatalError("no mock for `pull`")
        }

        try await mock()
    }

}

class MockPullUserConnectionsSyncProtocol: PullUserConnectionsSyncProtocol {

    // MARK: - Life cycle



    // MARK: - pull

    var pull_Invocations: [Void] = []
    var pull_MockError: Error?
    var pull_MockMethod: (() async throws -> Void)?

    func pull() async throws {
        pull_Invocations.append(())

        if let error = pull_MockError {
            throw error
        }

        guard let mock = pull_MockMethod else {
            fatalError("no mock for `pull`")
        }

        try await mock()
    }

}

public class MockPushChannelStateProtocol: PushChannelStateProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - markAsOpen

    public var markAsOpen_Invocations: [Void] = []
    public var markAsOpen_MockError: Error?
    public var markAsOpen_MockMethod: (() async throws -> Void)?

    public func markAsOpen() async throws {
        markAsOpen_Invocations.append(())

        if let error = markAsOpen_MockError {
            throw error
        }

        guard let mock = markAsOpen_MockMethod else {
            fatalError("no mock for `markAsOpen`")
        }

        try await mock()
    }

    // MARK: - markAsClosed

    public var markAsClosed_Invocations: [Void] = []
    public var markAsClosed_MockMethod: (() async -> Void)?

    public func markAsClosed() async {
        markAsClosed_Invocations.append(())

        guard let mock = markAsClosed_MockMethod else {
            fatalError("no mock for `markAsClosed`")
        }

        await mock()
    }

}

public class MockPushSupportedProtocolsSyncProtocol: PushSupportedProtocolsSyncProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - push

    public var pushSupportedProtocols_Invocations: [Set<WireNetwork.MessageProtocol>] = []
    public var pushSupportedProtocols_MockError: Error?
    public var pushSupportedProtocols_MockMethod: ((Set<WireNetwork.MessageProtocol>) async throws -> Void)?

    public func push(supportedProtocols: Set<WireNetwork.MessageProtocol>) async throws {
        pushSupportedProtocols_Invocations.append(supportedProtocols)

        if let error = pushSupportedProtocols_MockError {
            throw error
        }

        guard let mock = pushSupportedProtocols_MockMethod else {
            fatalError("no mock for `pushSupportedProtocols`")
        }

        try await mock(supportedProtocols)
    }

}

public class MockPushSupportedProtocolsUseCaseProtocol: PushSupportedProtocolsUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invoke_Invocations: [Void] = []
    public var invoke_MockError: Error?
    public var invoke_MockMethod: (() async throws -> Void)?

    public func invoke() async throws {
        invoke_Invocations.append(())

        if let error = invoke_MockError {
            throw error
        }

        guard let mock = invoke_MockMethod else {
            fatalError("no mock for `invoke`")
        }

        try await mock()
    }

}

public class MockRepairRemovalKeysUseCaseProtocol: RepairRemovalKeysUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invoke_Invocations: [Void] = []
    public var invoke_MockError: Error?
    public var invoke_MockMethod: (() async throws -> RepairRemovalKeysResult)?
    public var invoke_MockValue: RepairRemovalKeysResult?

    @discardableResult
    public func invoke() async throws -> RepairRemovalKeysResult {
        invoke_Invocations.append(())

        if let error = invoke_MockError {
            throw error
        }

        if let mock = invoke_MockMethod {
            return try await mock()
        } else if let mock = invoke_MockValue {
            return mock
        } else {
            fatalError("no mock for `invoke`")
        }
    }

}

public class MockResetMLSConversationLockRepositoryProtocol: ResetMLSConversationLockRepositoryProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - setInitiatedReset

    public var setInitiatedResetConversationID_Invocations: [WireDataModel.QualifiedID] = []
    public var setInitiatedResetConversationID_MockMethod: ((WireDataModel.QualifiedID) -> Void)?

    public func setInitiatedReset(conversationID: WireDataModel.QualifiedID) {
        setInitiatedResetConversationID_Invocations.append(conversationID)

        guard let mock = setInitiatedResetConversationID_MockMethod else {
            fatalError("no mock for `setInitiatedResetConversationID`")
        }

        mock(conversationID)
    }

    // MARK: - wasResetInitiated

    public var wasResetInitiatedConversationID_Invocations: [WireDataModel.QualifiedID] = []
    public var wasResetInitiatedConversationID_MockMethod: ((WireDataModel.QualifiedID) -> Bool)?
    public var wasResetInitiatedConversationID_MockValue: Bool?

    public func wasResetInitiated(conversationID: WireDataModel.QualifiedID) -> Bool {
        wasResetInitiatedConversationID_Invocations.append(conversationID)

        if let mock = wasResetInitiatedConversationID_MockMethod {
            return mock(conversationID)
        } else if let mock = wasResetInitiatedConversationID_MockValue {
            return mock
        } else {
            fatalError("no mock for `wasResetInitiatedConversationID`")
        }
    }

    // MARK: - removeResetInitiated

    public var removeResetInitiatedConversationID_Invocations: [WireDataModel.QualifiedID] = []
    public var removeResetInitiatedConversationID_MockMethod: ((WireDataModel.QualifiedID) -> Void)?

    public func removeResetInitiated(conversationID: WireDataModel.QualifiedID) {
        removeResetInitiatedConversationID_Invocations.append(conversationID)

        guard let mock = removeResetInitiatedConversationID_MockMethod else {
            fatalError("no mock for `removeResetInitiatedConversationID`")
        }

        mock(conversationID)
    }

}

public class MockSelfUserProviderProtocol: SelfUserProviderProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - fetchSelfUser

    public var fetchSelfUser_Invocations: [Void] = []
    public var fetchSelfUser_MockMethod: (() -> ZMUser)?
    public var fetchSelfUser_MockValue: ZMUser?

    public func fetchSelfUser() -> ZMUser {
        fetchSelfUser_Invocations.append(())

        if let mock = fetchSelfUser_MockMethod {
            return mock()
        } else if let mock = fetchSelfUser_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfUser`")
        }
    }

}

public class MockSyncCellsStateUseCaseProtocol: SyncCellsStateUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invokeConversationObjectID_Invocations: [NSManagedObjectID] = []
    public var invokeConversationObjectID_MockError: Error?
    public var invokeConversationObjectID_MockMethod: ((NSManagedObjectID) async throws -> CellsState)?
    public var invokeConversationObjectID_MockValue: CellsState?

    public func invoke(conversationObjectID: NSManagedObjectID) async throws -> CellsState {
        invokeConversationObjectID_Invocations.append(conversationObjectID)

        if let error = invokeConversationObjectID_MockError {
            throw error
        }

        if let mock = invokeConversationObjectID_MockMethod {
            return try await mock(conversationObjectID)
        } else if let mock = invokeConversationObjectID_MockValue {
            return mock
        } else {
            fatalError("no mock for `invokeConversationObjectID`")
        }
    }

}

class MockSyncEventsUseCaseProtocol: SyncEventsUseCaseProtocol {

    // MARK: - Life cycle



    // MARK: - invoke

    var invoke_Invocations: [Void] = []
    var invoke_MockError: Error?
    var invoke_MockMethod: (() async throws -> Void)?

    func invoke() async throws {
        invoke_Invocations.append(())

        if let error = invoke_MockError {
            throw error
        }

        guard let mock = invoke_MockMethod else {
            fatalError("no mock for `invoke`")
        }

        try await mock()
    }

}

public class MockSyncMigratorProtocol: SyncMigratorProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - migrateFromIncrementalSyncV1

    public var migrateFromIncrementalSyncV1_Invocations: [Void] = []
    public var migrateFromIncrementalSyncV1_MockError: Error?
    public var migrateFromIncrementalSyncV1_MockMethod: (() async throws -> Void)?

    public func migrateFromIncrementalSyncV1() async throws {
        migrateFromIncrementalSyncV1_Invocations.append(())

        if let error = migrateFromIncrementalSyncV1_MockError {
            throw error
        }

        guard let mock = migrateFromIncrementalSyncV1_MockMethod else {
            fatalError("no mock for `migrateFromIncrementalSyncV1`")
        }

        try await mock()
    }

}

public class MockTeamLocalStoreProtocol: TeamLocalStoreProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - fetchMember

    public var fetchMemberId_Invocations: [UUID] = []
    public var fetchMemberId_MockMethod: ((UUID) async -> Member?)?
    public var fetchMemberId_MockValue: Member??

    public func fetchMember(id: UUID) async -> Member? {
        fetchMemberId_Invocations.append(id)

        if let mock = fetchMemberId_MockMethod {
            return await mock(id)
        } else if let mock = fetchMemberId_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchMemberId`")
        }
    }

    // MARK: - selfUserID

    public var selfUserID_Invocations: [Void] = []
    public var selfUserID_MockMethod: (() async -> UUID)?
    public var selfUserID_MockValue: UUID?

    public func selfUserID() async -> UUID {
        selfUserID_Invocations.append(())

        if let mock = selfUserID_MockMethod {
            return await mock()
        } else if let mock = selfUserID_MockValue {
            return mock
        } else {
            fatalError("no mock for `selfUserID`")
        }
    }

    // MARK: - selfTeamID

    public var selfTeamID_Invocations: [Void] = []
    public var selfTeamID_MockMethod: (() async -> UUID?)?
    public var selfTeamID_MockValue: UUID??

    public func selfTeamID() async -> UUID? {
        selfTeamID_Invocations.append(())

        if let mock = selfTeamID_MockMethod {
            return await mock()
        } else if let mock = selfTeamID_MockValue {
            return mock
        } else {
            fatalError("no mock for `selfTeamID`")
        }
    }

    // MARK: - userMembership

    public var userMembershipUser_Invocations: [ZMUser] = []
    public var userMembershipUser_MockMethod: ((ZMUser) async -> Member?)?
    public var userMembershipUser_MockValue: Member??

    public func userMembership(user: ZMUser) async -> Member? {
        userMembershipUser_Invocations.append(user)

        if let mock = userMembershipUser_MockMethod {
            return await mock(user)
        } else if let mock = userMembershipUser_MockValue {
            return mock
        } else {
            fatalError("no mock for `userMembershipUser`")
        }
    }

    // MARK: - userDomain

    public var userDomainUser_Invocations: [ZMUser] = []
    public var userDomainUser_MockMethod: ((ZMUser) async -> String?)?
    public var userDomainUser_MockValue: String??

    public func userDomain(user: ZMUser) async -> String? {
        userDomainUser_Invocations.append(user)

        if let mock = userDomainUser_MockMethod {
            return await mock(user)
        } else if let mock = userDomainUser_MockValue {
            return mock
        } else {
            fatalError("no mock for `userDomainUser`")
        }
    }

    // MARK: - deleteMember

    public var deleteMember_Invocations: [Member] = []
    public var deleteMember_MockMethod: ((Member) async -> Void)?

    public func deleteMember(_ member: Member) async {
        deleteMember_Invocations.append(member)

        guard let mock = deleteMember_MockMethod else {
            fatalError("no mock for `deleteMember`")
        }

        await mock(member)
    }

    // MARK: - storeMember

    public var storeMemberNeedsBackendUpdateMember_Invocations: [(needsBackendUpdate: Bool, member: Member)] = []
    public var storeMemberNeedsBackendUpdateMember_MockMethod: ((Bool, Member) async -> Void)?

    public func storeMember(needsBackendUpdate: Bool, member: Member) async {
        storeMemberNeedsBackendUpdateMember_Invocations.append((needsBackendUpdate: needsBackendUpdate, member: member))

        guard let mock = storeMemberNeedsBackendUpdateMember_MockMethod else {
            fatalError("no mock for `storeMemberNeedsBackendUpdateMember`")
        }

        await mock(needsBackendUpdate, member)
    }

    // MARK: - storeTeam

    public var storeTeamIdNameCreatorIDLogoIDLogoKey_Invocations: [(id: UUID, name: String, creatorID: UUID, logoID: String?, logoKey: String?)] = []
    public var storeTeamIdNameCreatorIDLogoIDLogoKey_MockMethod: ((UUID, String, UUID, String?, String?) async -> Void)?

    public func storeTeam(id: UUID, name: String, creatorID: UUID, logoID: String?, logoKey: String?) async {
        storeTeamIdNameCreatorIDLogoIDLogoKey_Invocations.append((id: id, name: name, creatorID: creatorID, logoID: logoID, logoKey: logoKey))

        guard let mock = storeTeamIdNameCreatorIDLogoIDLogoKey_MockMethod else {
            fatalError("no mock for `storeTeamIdNameCreatorIDLogoIDLogoKey`")
        }

        await mock(id, name, creatorID, logoID, logoKey)
    }

    // MARK: - storeTeamRoles

    public var storeTeamRolesSelfTeamIDTeamRolesInfo_Invocations: [(selfTeamID: UUID, teamRolesInfo: [TeamRoleInfo])] = []
    public var storeTeamRolesSelfTeamIDTeamRolesInfo_MockError: Error?
    public var storeTeamRolesSelfTeamIDTeamRolesInfo_MockMethod: ((UUID, [TeamRoleInfo]) async throws -> Void)?

    public func storeTeamRoles(selfTeamID: UUID, teamRolesInfo: [TeamRoleInfo]) async throws {
        storeTeamRolesSelfTeamIDTeamRolesInfo_Invocations.append((selfTeamID: selfTeamID, teamRolesInfo: teamRolesInfo))

        if let error = storeTeamRolesSelfTeamIDTeamRolesInfo_MockError {
            throw error
        }

        guard let mock = storeTeamRolesSelfTeamIDTeamRolesInfo_MockMethod else {
            fatalError("no mock for `storeTeamRolesSelfTeamIDTeamRolesInfo`")
        }

        try await mock(selfTeamID, teamRolesInfo)
    }

    // MARK: - storeTeamMembers

    public var storeTeamMembersSelfTeamIDTeamMembersInfo_Invocations: [(selfTeamID: UUID, teamMembersInfo: [TeamMemberInfo])] = []
    public var storeTeamMembersSelfTeamIDTeamMembersInfo_MockError: Error?
    public var storeTeamMembersSelfTeamIDTeamMembersInfo_MockMethod: ((UUID, [TeamMemberInfo]) async throws -> Void)?

    public func storeTeamMembers(selfTeamID: UUID, teamMembersInfo: [TeamMemberInfo]) async throws {
        storeTeamMembersSelfTeamIDTeamMembersInfo_Invocations.append((selfTeamID: selfTeamID, teamMembersInfo: teamMembersInfo))

        if let error = storeTeamMembersSelfTeamIDTeamMembersInfo_MockError {
            throw error
        }

        guard let mock = storeTeamMembersSelfTeamIDTeamMembersInfo_MockMethod else {
            fatalError("no mock for `storeTeamMembersSelfTeamIDTeamMembersInfo`")
        }

        try await mock(selfTeamID, teamMembersInfo)
    }

    // MARK: - selfUserInfo

    public var selfUserInfo_Invocations: [Void] = []
    public var selfUserInfo_MockMethod: (() async -> (id: UUID, clientId: String?))?
    public var selfUserInfo_MockValue: (id: UUID, clientId: String?)?

    public func selfUserInfo() async -> (id: UUID, clientId: String?) {
        selfUserInfo_Invocations.append(())

        if let mock = selfUserInfo_MockMethod {
            return await mock()
        } else if let mock = selfUserInfo_MockValue {
            return mock
        } else {
            fatalError("no mock for `selfUserInfo`")
        }
    }

    // MARK: - createOrUpdateTeam

    public var createOrUpdateTeamIdentifierNameCreatorIconIconKey_Invocations: [(identifier: UUID, name: String, creator: UUID, icon: String, iconKey: String?)] = []
    public var createOrUpdateTeamIdentifierNameCreatorIconIconKey_MockMethod: ((UUID, String, UUID, String, String?) async -> Void)?

    public func createOrUpdateTeam(identifier: UUID, name: String, creator: UUID, icon: String, iconKey: String?) async {
        createOrUpdateTeamIdentifierNameCreatorIconIconKey_Invocations.append((identifier: identifier, name: name, creator: creator, icon: icon, iconKey: iconKey))

        guard let mock = createOrUpdateTeamIdentifierNameCreatorIconIconKey_MockMethod else {
            fatalError("no mock for `createOrUpdateTeamIdentifierNameCreatorIconIconKey`")
        }

        await mock(identifier, name, creator, icon, iconKey)
    }

}

public class MockTeamRepositoryProtocol: TeamRepositoryProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - pullSelfTeam

    public var pullSelfTeam_Invocations: [Void] = []
    public var pullSelfTeam_MockError: Error?
    public var pullSelfTeam_MockMethod: (() async throws -> Void)?

    public func pullSelfTeam() async throws {
        pullSelfTeam_Invocations.append(())

        if let error = pullSelfTeam_MockError {
            throw error
        }

        guard let mock = pullSelfTeam_MockMethod else {
            fatalError("no mock for `pullSelfTeam`")
        }

        try await mock()
    }

    // MARK: - pullSelfTeamRoles

    public var pullSelfTeamRoles_Invocations: [Void] = []
    public var pullSelfTeamRoles_MockError: Error?
    public var pullSelfTeamRoles_MockMethod: (() async throws -> Void)?

    public func pullSelfTeamRoles() async throws {
        pullSelfTeamRoles_Invocations.append(())

        if let error = pullSelfTeamRoles_MockError {
            throw error
        }

        guard let mock = pullSelfTeamRoles_MockMethod else {
            fatalError("no mock for `pullSelfTeamRoles`")
        }

        try await mock()
    }

    // MARK: - pullSelfTeamMembers

    public var pullSelfTeamMembers_Invocations: [Void] = []
    public var pullSelfTeamMembers_MockError: Error?
    public var pullSelfTeamMembers_MockMethod: (() async throws -> Void)?

    public func pullSelfTeamMembers() async throws {
        pullSelfTeamMembers_Invocations.append(())

        if let error = pullSelfTeamMembers_MockError {
            throw error
        }

        guard let mock = pullSelfTeamMembers_MockMethod else {
            fatalError("no mock for `pullSelfTeamMembers`")
        }

        try await mock()
    }

    // MARK: - fetchSelfLegalholdInfo

    public var fetchSelfLegalholdInfo_Invocations: [Void] = []
    public var fetchSelfLegalholdInfo_MockError: Error?
    public var fetchSelfLegalholdInfo_MockMethod: (() async throws -> TeamMemberLegalholdInfo)?
    public var fetchSelfLegalholdInfo_MockValue: TeamMemberLegalholdInfo?

    public func fetchSelfLegalholdInfo() async throws -> TeamMemberLegalholdInfo {
        fetchSelfLegalholdInfo_Invocations.append(())

        if let error = fetchSelfLegalholdInfo_MockError {
            throw error
        }

        if let mock = fetchSelfLegalholdInfo_MockMethod {
            return try await mock()
        } else if let mock = fetchSelfLegalholdInfo_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfLegalholdInfo`")
        }
    }

    // MARK: - createOrUpdateTeam

    public var createOrUpdateTeamIdentifierNameCreatorIconIconKey_Invocations: [(identifier: UUID, name: String, creator: UUID, icon: String, iconKey: String?)] = []
    public var createOrUpdateTeamIdentifierNameCreatorIconIconKey_MockMethod: ((UUID, String, UUID, String, String?) async -> Void)?

    public func createOrUpdateTeam(identifier: UUID, name: String, creator: UUID, icon: String, iconKey: String?) async {
        createOrUpdateTeamIdentifierNameCreatorIconIconKey_Invocations.append((identifier: identifier, name: name, creator: creator, icon: icon, iconKey: iconKey))

        guard let mock = createOrUpdateTeamIdentifierNameCreatorIconIconKey_MockMethod else {
            fatalError("no mock for `createOrUpdateTeamIdentifierNameCreatorIconIconKey`")
        }

        await mock(identifier, name, creator, icon, iconKey)
    }

    // MARK: - deleteMembership

    public var deleteMembershipUserIDDomainDate_Invocations: [(userID: UUID, domain: String?, date: Date)] = []
    public var deleteMembershipUserIDDomainDate_MockError: Error?
    public var deleteMembershipUserIDDomainDate_MockMethod: ((UUID, String?, Date) async throws -> Void)?

    public func deleteMembership(userID: UUID, domain: String?, date: Date) async throws {
        deleteMembershipUserIDDomainDate_Invocations.append((userID: userID, domain: domain, date: date))

        if let error = deleteMembershipUserIDDomainDate_MockError {
            throw error
        }

        guard let mock = deleteMembershipUserIDDomainDate_MockMethod else {
            fatalError("no mock for `deleteMembershipUserIDDomainDate`")
        }

        try await mock(userID, domain, date)
    }

    // MARK: - storeTeamMemberNeedsBackendUpdate

    public var storeTeamMemberNeedsBackendUpdateMembershipID_Invocations: [UUID] = []
    public var storeTeamMemberNeedsBackendUpdateMembershipID_MockError: Error?
    public var storeTeamMemberNeedsBackendUpdateMembershipID_MockMethod: ((UUID) async throws -> Void)?

    public func storeTeamMemberNeedsBackendUpdate(membershipID: UUID) async throws {
        storeTeamMemberNeedsBackendUpdateMembershipID_Invocations.append(membershipID)

        if let error = storeTeamMemberNeedsBackendUpdateMembershipID_MockError {
            throw error
        }

        guard let mock = storeTeamMemberNeedsBackendUpdateMembershipID_MockMethod else {
            fatalError("no mock for `storeTeamMemberNeedsBackendUpdateMembershipID`")
        }

        try await mock(membershipID)
    }

    // MARK: - pullSelfLegalholdInfo

    public var pullSelfLegalholdInfo_Invocations: [Void] = []
    public var pullSelfLegalholdInfo_MockError: Error?
    public var pullSelfLegalholdInfo_MockMethod: (() async throws -> Void)?

    public func pullSelfLegalholdInfo() async throws {
        pullSelfLegalholdInfo_Invocations.append(())

        if let error = pullSelfLegalholdInfo_MockError {
            throw error
        }

        guard let mock = pullSelfLegalholdInfo_MockMethod else {
            fatalError("no mock for `pullSelfLegalholdInfo`")
        }

        try await mock()
    }

}

public class MockUpdateEventDecryptorProtocol: UpdateEventDecryptorProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - decryptEvents

    public var decryptEventsInContext_Invocations: [(eventEnvelope: UpdateEventEnvelope, context: CoreCryptoContextProtocol?)] = []
    public var decryptEventsInContext_MockMethod: ((UpdateEventEnvelope, CoreCryptoContextProtocol?) async -> EventDecryptorResult)?
    public var decryptEventsInContext_MockValue: EventDecryptorResult?

    public func decryptEvents(in eventEnvelope: UpdateEventEnvelope, context: CoreCryptoContextProtocol?) async -> EventDecryptorResult {
        decryptEventsInContext_Invocations.append((eventEnvelope: eventEnvelope, context: context))

        if let mock = decryptEventsInContext_MockMethod {
            return await mock(eventEnvelope, context)
        } else if let mock = decryptEventsInContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptEventsInContext`")
        }
    }

}

public class MockUpdateEventProcessorProtocol: UpdateEventProcessorProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - processEvent

    public var processEvent_Invocations: [UpdateEvent] = []
    public var processEvent_MockError: Error?
    public var processEvent_MockMethod: ((UpdateEvent) async throws -> Void)?

    public func processEvent(_ event: UpdateEvent) async throws {
        processEvent_Invocations.append(event)

        if let error = processEvent_MockError {
            throw error
        }

        guard let mock = processEvent_MockMethod else {
            fatalError("no mock for `processEvent`")
        }

        try await mock(event)
    }

}

public class MockUpdateEventsLocalStoreProtocol: UpdateEventsLocalStoreProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - lastEventID

    public var lastEventID_Invocations: [Void] = []
    public var lastEventID_MockMethod: (() -> UUID?)?
    public var lastEventID_MockValue: UUID??

    public func lastEventID() -> UUID? {
        lastEventID_Invocations.append(())

        if let mock = lastEventID_MockMethod {
            return mock()
        } else if let mock = lastEventID_MockValue {
            return mock
        } else {
            fatalError("no mock for `lastEventID`")
        }
    }

    // MARK: - storeLastEventID

    public var storeLastEventIDId_Invocations: [UUID] = []
    public var storeLastEventIDId_MockMethod: ((UUID) -> Void)?

    public func storeLastEventID(id: UUID) {
        storeLastEventIDId_Invocations.append(id)

        guard let mock = storeLastEventIDId_MockMethod else {
            fatalError("no mock for `storeLastEventIDId`")
        }

        mock(id)
    }

    // MARK: - resetLastEventID

    public var resetLastEventID_Invocations: [Void] = []
    public var resetLastEventID_MockMethod: (() -> Void)?

    public func resetLastEventID() {
        resetLastEventID_Invocations.append(())

        guard let mock = resetLastEventID_MockMethod else {
            fatalError("no mock for `resetLastEventID`")
        }

        mock()
    }

    // MARK: - indexOfLastEventEnvelope

    public var indexOfLastEventEnvelope_Invocations: [Void] = []
    public var indexOfLastEventEnvelope_MockError: Error?
    public var indexOfLastEventEnvelope_MockMethod: (() async throws -> Int64)?
    public var indexOfLastEventEnvelope_MockValue: Int64?

    public func indexOfLastEventEnvelope() async throws -> Int64 {
        indexOfLastEventEnvelope_Invocations.append(())

        if let error = indexOfLastEventEnvelope_MockError {
            throw error
        }

        if let mock = indexOfLastEventEnvelope_MockMethod {
            return try await mock()
        } else if let mock = indexOfLastEventEnvelope_MockValue {
            return mock
        } else {
            fatalError("no mock for `indexOfLastEventEnvelope`")
        }
    }

    // MARK: - persistEventEnvelope

    public var persistEventEnvelopeIndex_Invocations: [(eventEnvelope: UpdateEventEnvelope, index: Int64)] = []
    public var persistEventEnvelopeIndex_MockError: Error?
    public var persistEventEnvelopeIndex_MockMethod: ((UpdateEventEnvelope, Int64) async throws -> Void)?

    public func persistEventEnvelope(_ eventEnvelope: UpdateEventEnvelope, index: Int64) async throws {
        persistEventEnvelopeIndex_Invocations.append((eventEnvelope: eventEnvelope, index: index))

        if let error = persistEventEnvelopeIndex_MockError {
            throw error
        }

        guard let mock = persistEventEnvelopeIndex_MockMethod else {
            fatalError("no mock for `persistEventEnvelopeIndex`")
        }

        try await mock(eventEnvelope, index)
    }

    // MARK: - persistEventEnvelopes

    public var persistEventEnvelopesIndex_Invocations: [(eventEnvelopes: [UpdateEventEnvelope], index: Int64)] = []
    public var persistEventEnvelopesIndex_MockError: Error?
    public var persistEventEnvelopesIndex_MockMethod: (([UpdateEventEnvelope], Int64) async throws -> Void)?

    public func persistEventEnvelopes(_ eventEnvelopes: [UpdateEventEnvelope], index: Int64) async throws {
        persistEventEnvelopesIndex_Invocations.append((eventEnvelopes: eventEnvelopes, index: index))

        if let error = persistEventEnvelopesIndex_MockError {
            throw error
        }

        guard let mock = persistEventEnvelopesIndex_MockMethod else {
            fatalError("no mock for `persistEventEnvelopesIndex`")
        }

        try await mock(eventEnvelopes, index)
    }

    // MARK: - fetchStoredEventEnvelopes

    public var fetchStoredEventEnvelopesLimit_Invocations: [UInt] = []
    public var fetchStoredEventEnvelopesLimit_MockError: Error?
    public var fetchStoredEventEnvelopesLimit_MockMethod: ((UInt) async throws -> [(envelope: UpdateEventEnvelope, objectID: NSManagedObjectID)])?
    public var fetchStoredEventEnvelopesLimit_MockValue: [(envelope: UpdateEventEnvelope, objectID: NSManagedObjectID)]?

    public func fetchStoredEventEnvelopes(limit: UInt) async throws -> [(envelope: UpdateEventEnvelope, objectID: NSManagedObjectID)] {
        fetchStoredEventEnvelopesLimit_Invocations.append(limit)

        if let error = fetchStoredEventEnvelopesLimit_MockError {
            throw error
        }

        if let mock = fetchStoredEventEnvelopesLimit_MockMethod {
            return try await mock(limit)
        } else if let mock = fetchStoredEventEnvelopesLimit_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchStoredEventEnvelopesLimit`")
        }
    }

    // MARK: - deleteNextPendingEvents

    public var deleteNextPendingEventsWith_Invocations: [[NSManagedObjectID]] = []
    public var deleteNextPendingEventsWith_MockError: Error?
    public var deleteNextPendingEventsWith_MockMethod: (([NSManagedObjectID]) async throws -> Void)?

    public func deleteNextPendingEvents(with objectIDs: [NSManagedObjectID]) async throws {
        deleteNextPendingEventsWith_Invocations.append(objectIDs)

        if let error = deleteNextPendingEventsWith_MockError {
            throw error
        }

        guard let mock = deleteNextPendingEventsWith_MockMethod else {
            fatalError("no mock for `deleteNextPendingEventsWith`")
        }

        try await mock(objectIDs)
    }

    // MARK: - deleteEventEnvelopes

    public var deleteEventEnvelopesAt_Invocations: [[Int64]] = []
    public var deleteEventEnvelopesAt_MockError: Error?
    public var deleteEventEnvelopesAt_MockMethod: (([Int64]) async throws -> Void)?

    public func deleteEventEnvelopes(at indexes: [Int64]) async throws {
        deleteEventEnvelopesAt_Invocations.append(indexes)

        if let error = deleteEventEnvelopesAt_MockError {
            throw error
        }

        guard let mock = deleteEventEnvelopesAt_MockMethod else {
            fatalError("no mock for `deleteEventEnvelopesAt`")
        }

        try await mock(indexes)
    }

    // MARK: - deleteEventEnvelope

    public var deleteEventEnvelopeAtIndex_Invocations: [Int64] = []
    public var deleteEventEnvelopeAtIndex_MockError: Error?
    public var deleteEventEnvelopeAtIndex_MockMethod: ((Int64) async throws -> Void)?

    public func deleteEventEnvelope(atIndex index: Int64) async throws {
        deleteEventEnvelopeAtIndex_Invocations.append(index)

        if let error = deleteEventEnvelopeAtIndex_MockError {
            throw error
        }

        guard let mock = deleteEventEnvelopeAtIndex_MockMethod else {
            fatalError("no mock for `deleteEventEnvelopeAtIndex`")
        }

        try await mock(index)
    }

    // MARK: - calculateLastUnreadMessages

    public var calculateLastUnreadMessages_Invocations: [Void] = []
    public var calculateLastUnreadMessages_MockMethod: (() async -> Void)?

    public func calculateLastUnreadMessages() async {
        calculateLastUnreadMessages_Invocations.append(())

        guard let mock = calculateLastUnreadMessages_MockMethod else {
            fatalError("no mock for `calculateLastUnreadMessages`")
        }

        await mock()
    }

    // MARK: - storeServerTimeDelta

    public var storeServerTimeDelta_Invocations: [TimeInterval] = []
    public var storeServerTimeDelta_MockMethod: ((TimeInterval) async -> Void)?

    public func storeServerTimeDelta(_ serverTimeDelta: TimeInterval) async {
        storeServerTimeDelta_Invocations.append(serverTimeDelta)

        guard let mock = storeServerTimeDelta_MockMethod else {
            fatalError("no mock for `storeServerTimeDelta`")
        }

        await mock(serverTimeDelta)
    }

}

public class MockUserClientsLocalStoreProtocol: UserClientsLocalStoreProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - fetchOrCreateClient

    public var fetchOrCreateClientId_Invocations: [String] = []
    public var fetchOrCreateClientId_MockMethod: ((String) async -> (client: WireDataModel.UserClient, isNew: Bool))?
    public var fetchOrCreateClientId_MockValue: (client: WireDataModel.UserClient, isNew: Bool)?

    public func fetchOrCreateClient(id: String) async -> (client: WireDataModel.UserClient, isNew: Bool) {
        fetchOrCreateClientId_Invocations.append(id)

        if let mock = fetchOrCreateClientId_MockMethod {
            return await mock(id)
        } else if let mock = fetchOrCreateClientId_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateClientId`")
        }
    }

    // MARK: - deletedSelfClients

    public var deletedSelfClientsNewClients_Invocations: [[String]] = []
    public var deletedSelfClientsNewClients_MockMethod: (([String]) async -> [String])?
    public var deletedSelfClientsNewClients_MockValue: [String]?

    public func deletedSelfClients(newClients: [String]) async -> [String] {
        deletedSelfClientsNewClients_Invocations.append(newClients)

        if let mock = deletedSelfClientsNewClients_MockMethod {
            return await mock(newClients)
        } else if let mock = deletedSelfClientsNewClients_MockValue {
            return mock
        } else {
            fatalError("no mock for `deletedSelfClientsNewClients`")
        }
    }

    // MARK: - deleteClient

    public var deleteClientId_Invocations: [String] = []
    public var deleteClientId_MockMethod: ((String) async -> Void)?

    public func deleteClient(id: String) async {
        deleteClientId_Invocations.append(id)

        guard let mock = deleteClientId_MockMethod else {
            fatalError("no mock for `deleteClientId`")
        }

        await mock(id)
    }

    // MARK: - invalidateSelfClient

    public var invalidateSelfClient_Invocations: [Void] = []
    public var invalidateSelfClient_MockMethod: (() async -> Void)?

    public func invalidateSelfClient() async {
        invalidateSelfClient_Invocations.append(())

        guard let mock = invalidateSelfClient_MockMethod else {
            fatalError("no mock for `invalidateSelfClient`")
        }

        await mock()
    }

    // MARK: - updateClient

    public var updateClientIdIsNewClientUserClientInfo_Invocations: [(id: String, isNewClient: Bool, userClientInfo: UserClientInfo)] = []
    public var updateClientIdIsNewClientUserClientInfo_MockMethod: ((String, Bool, UserClientInfo) async -> Void)?

    public func updateClient(id: String, isNewClient: Bool, userClientInfo: UserClientInfo) async {
        updateClientIdIsNewClientUserClientInfo_Invocations.append((id: id, isNewClient: isNewClient, userClientInfo: userClientInfo))

        guard let mock = updateClientIdIsNewClientUserClientInfo_MockMethod else {
            fatalError("no mock for `updateClientIdIsNewClientUserClientInfo`")
        }

        await mock(id, isNewClient, userClientInfo)
    }

    // MARK: - allSelfUserClientsAreActiveMLSClients

    public var allSelfUserClientsAreActiveMLSClients_Invocations: [Void] = []
    public var allSelfUserClientsAreActiveMLSClients_MockMethod: (() async -> Bool)?
    public var allSelfUserClientsAreActiveMLSClients_MockValue: Bool?

    public func allSelfUserClientsAreActiveMLSClients() async -> Bool {
        allSelfUserClientsAreActiveMLSClients_Invocations.append(())

        if let mock = allSelfUserClientsAreActiveMLSClients_MockMethod {
            return await mock()
        } else if let mock = allSelfUserClientsAreActiveMLSClients_MockValue {
            return mock
        } else {
            fatalError("no mock for `allSelfUserClientsAreActiveMLSClients`")
        }
    }

    // MARK: - storeClient

    public var storeClientDiscoveryDateClient_Invocations: [(discoveryDate: Date, client: WireDataModel.UserClient)] = []
    public var storeClientDiscoveryDateClient_MockMethod: ((Date, WireDataModel.UserClient) async -> Void)?

    public func storeClient(discoveryDate: Date, client: WireDataModel.UserClient) async {
        storeClientDiscoveryDateClient_Invocations.append((discoveryDate: discoveryDate, client: client))

        guard let mock = storeClientDiscoveryDateClient_MockMethod else {
            fatalError("no mock for `storeClientDiscoveryDateClient`")
        }

        await mock(discoveryDate, client)
    }

    // MARK: - addNewClientToIgnored

    public var addNewClientToIgnoredSelfClientNewClient_Invocations: [(selfClient: WireDataModel.UserClient, newClient: WireDataModel.UserClient)] = []
    public var addNewClientToIgnoredSelfClientNewClient_MockMethod: ((WireDataModel.UserClient, WireDataModel.UserClient) async -> Void)?

    public func addNewClientToIgnored(selfClient: WireDataModel.UserClient, newClient: WireDataModel.UserClient) async {
        addNewClientToIgnoredSelfClientNewClient_Invocations.append((selfClient: selfClient, newClient: newClient))

        guard let mock = addNewClientToIgnoredSelfClientNewClient_MockMethod else {
            fatalError("no mock for `addNewClientToIgnoredSelfClientNewClient`")
        }

        await mock(selfClient, newClient)
    }

    // MARK: - proteusSessionID

    public var proteusSessionIDFor_Invocations: [WireDataModel.UserClient] = []
    public var proteusSessionIDFor_MockMethod: ((WireDataModel.UserClient) async -> ProteusSessionID?)?
    public var proteusSessionIDFor_MockValue: ProteusSessionID??

    public func proteusSessionID(for client: WireDataModel.UserClient) async -> ProteusSessionID? {
        proteusSessionIDFor_Invocations.append(client)

        if let mock = proteusSessionIDFor_MockMethod {
            return await mock(client)
        } else if let mock = proteusSessionIDFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusSessionIDFor`")
        }
    }

    // MARK: - clientSessionCreated

    public var clientSessionCreatedSelfClientNewClient_Invocations: [(selfClient: WireDataModel.UserClient, newClient: WireDataModel.UserClient)] = []
    public var clientSessionCreatedSelfClientNewClient_MockMethod: ((WireDataModel.UserClient, WireDataModel.UserClient) async -> Void)?

    public func clientSessionCreated(selfClient: WireDataModel.UserClient, newClient: WireDataModel.UserClient) async {
        clientSessionCreatedSelfClientNewClient_Invocations.append((selfClient: selfClient, newClient: newClient))

        guard let mock = clientSessionCreatedSelfClientNewClient_MockMethod else {
            fatalError("no mock for `clientSessionCreatedSelfClientNewClient`")
        }

        await mock(selfClient, newClient)
    }

    // MARK: - fetchSelfClient

    public var fetchSelfClient_Invocations: [Void] = []
    public var fetchSelfClient_MockMethod: (() async -> WireDataModel.UserClient?)?
    public var fetchSelfClient_MockValue: WireDataModel.UserClient??

    public func fetchSelfClient() async -> WireDataModel.UserClient? {
        fetchSelfClient_Invocations.append(())

        if let mock = fetchSelfClient_MockMethod {
            return await mock()
        } else if let mock = fetchSelfClient_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfClient`")
        }
    }

    // MARK: - fetchClient

    public var fetchClientIdForUserCreateIfNeeded_Invocations: [(id: String, user: ZMUser, createIfNeeded: Bool)] = []
    public var fetchClientIdForUserCreateIfNeeded_MockMethod: ((String, ZMUser, Bool) async -> WireDataModel.UserClient?)?
    public var fetchClientIdForUserCreateIfNeeded_MockValue: WireDataModel.UserClient??

    public func fetchClient(id: String, forUser user: ZMUser, createIfNeeded: Bool) async -> WireDataModel.UserClient? {
        fetchClientIdForUserCreateIfNeeded_Invocations.append((id: id, user: user, createIfNeeded: createIfNeeded))

        if let mock = fetchClientIdForUserCreateIfNeeded_MockMethod {
            return await mock(id, user, createIfNeeded)
        } else if let mock = fetchClientIdForUserCreateIfNeeded_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchClientIdForUserCreateIfNeeded`")
        }
    }

    // MARK: - fetchSelfClientID

    public var fetchSelfClientID_Invocations: [Void] = []
    public var fetchSelfClientID_MockMethod: (() async -> String?)?
    public var fetchSelfClientID_MockValue: String??

    public func fetchSelfClientID() async -> String? {
        fetchSelfClientID_Invocations.append(())

        if let mock = fetchSelfClientID_MockMethod {
            return await mock()
        } else if let mock = fetchSelfClientID_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfClientID`")
        }
    }

    // MARK: - hasRegisteredConsumableNotificationsCapable

    public var hasRegisteredConsumableNotificationsCapable_Invocations: [Void] = []
    public var hasRegisteredConsumableNotificationsCapable_MockMethod: (() async -> Bool)?
    public var hasRegisteredConsumableNotificationsCapable_MockValue: Bool?

    public func hasRegisteredConsumableNotificationsCapable() async -> Bool {
        hasRegisteredConsumableNotificationsCapable_Invocations.append(())

        if let mock = hasRegisteredConsumableNotificationsCapable_MockMethod {
            return await mock()
        } else if let mock = hasRegisteredConsumableNotificationsCapable_MockValue {
            return mock
        } else {
            fatalError("no mock for `hasRegisteredConsumableNotificationsCapable`")
        }
    }

}

public class MockUserClientsRepositoryProtocol: UserClientsRepositoryProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - fetchSelfClient

    public var fetchSelfClient_Invocations: [Void] = []
    public var fetchSelfClient_MockMethod: (() async -> WireDataModel.UserClient?)?
    public var fetchSelfClient_MockValue: WireDataModel.UserClient??

    public func fetchSelfClient() async -> WireDataModel.UserClient? {
        fetchSelfClient_Invocations.append(())

        if let mock = fetchSelfClient_MockMethod {
            return await mock()
        } else if let mock = fetchSelfClient_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfClient`")
        }
    }

    // MARK: - pullSelfClients

    public var pullSelfClients_Invocations: [Void] = []
    public var pullSelfClients_MockError: Error?
    public var pullSelfClients_MockMethod: (() async throws -> Void)?

    public func pullSelfClients() async throws {
        pullSelfClients_Invocations.append(())

        if let error = pullSelfClients_MockError {
            throw error
        }

        guard let mock = pullSelfClients_MockMethod else {
            fatalError("no mock for `pullSelfClients`")
        }

        try await mock()
    }

    // MARK: - fetchOrCreateClient

    public var fetchOrCreateClientId_Invocations: [String] = []
    public var fetchOrCreateClientId_MockMethod: ((String) async -> (client: WireDataModel.UserClient, isNew: Bool))?
    public var fetchOrCreateClientId_MockValue: (client: WireDataModel.UserClient, isNew: Bool)?

    public func fetchOrCreateClient(id: String) async -> (client: WireDataModel.UserClient, isNew: Bool) {
        fetchOrCreateClientId_Invocations.append(id)

        if let mock = fetchOrCreateClientId_MockMethod {
            return await mock(id)
        } else if let mock = fetchOrCreateClientId_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateClientId`")
        }
    }

    // MARK: - updateClient

    public var updateClientIdFromIsNewClient_Invocations: [(id: String, remoteClient: WireNetwork.SelfUserClient, isNewClient: Bool)] = []
    public var updateClientIdFromIsNewClient_MockMethod: ((String, WireNetwork.SelfUserClient, Bool) async -> Void)?

    public func updateClient(id: String, from remoteClient: WireNetwork.SelfUserClient, isNewClient: Bool) async {
        updateClientIdFromIsNewClient_Invocations.append((id: id, remoteClient: remoteClient, isNewClient: isNewClient))

        guard let mock = updateClientIdFromIsNewClient_MockMethod else {
            fatalError("no mock for `updateClientIdFromIsNewClient`")
        }

        await mock(id, remoteClient, isNewClient)
    }

    // MARK: - deleteClient

    public var deleteClientId_Invocations: [String] = []
    public var deleteClientId_MockMethod: ((String) async -> Void)?

    public func deleteClient(id: String) async {
        deleteClientId_Invocations.append(id)

        guard let mock = deleteClientId_MockMethod else {
            fatalError("no mock for `deleteClientId`")
        }

        await mock(id)
    }

    // MARK: - invalidateSelfClient

    public var invalidateSelfClient_Invocations: [Void] = []
    public var invalidateSelfClient_MockMethod: (() async -> Void)?

    public func invalidateSelfClient() async {
        invalidateSelfClient_Invocations.append(())

        guard let mock = invalidateSelfClient_MockMethod else {
            fatalError("no mock for `invalidateSelfClient`")
        }

        await mock()
    }

    // MARK: - allSelfUserClientsAreActiveMLSClients

    public var allSelfUserClientsAreActiveMLSClients_Invocations: [Void] = []
    public var allSelfUserClientsAreActiveMLSClients_MockMethod: (() async -> Bool)?
    public var allSelfUserClientsAreActiveMLSClients_MockValue: Bool?

    public func allSelfUserClientsAreActiveMLSClients() async -> Bool {
        allSelfUserClientsAreActiveMLSClients_Invocations.append(())

        if let mock = allSelfUserClientsAreActiveMLSClients_MockMethod {
            return await mock()
        } else if let mock = allSelfUserClientsAreActiveMLSClients_MockValue {
            return mock
        } else {
            fatalError("no mock for `allSelfUserClientsAreActiveMLSClients`")
        }
    }

    // MARK: - fetchClient

    public var fetchClientIdForUserCreateIfNeeded_Invocations: [(id: String, user: ZMUser, createIfNeeded: Bool)] = []
    public var fetchClientIdForUserCreateIfNeeded_MockMethod: ((String, ZMUser, Bool) async -> WireDataModel.UserClient?)?
    public var fetchClientIdForUserCreateIfNeeded_MockValue: WireDataModel.UserClient??

    public func fetchClient(id: String, forUser user: ZMUser, createIfNeeded: Bool) async -> WireDataModel.UserClient? {
        fetchClientIdForUserCreateIfNeeded_Invocations.append((id: id, user: user, createIfNeeded: createIfNeeded))

        if let mock = fetchClientIdForUserCreateIfNeeded_MockMethod {
            return await mock(id, user, createIfNeeded)
        } else if let mock = fetchClientIdForUserCreateIfNeeded_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchClientIdForUserCreateIfNeeded`")
        }
    }

}

class MockUserEventNotificationBuilderProtocol: UserEventNotificationBuilderProtocol {

    // MARK: - Life cycle



    // MARK: - buildContent

    var buildContentEvent_Invocations: [UserEvent] = []
    var buildContentEvent_MockMethod: ((UserEvent) async -> UserNotification?)?
    var buildContentEvent_MockValue: UserNotification??

    func buildContent(event: UserEvent) async -> UserNotification? {
        buildContentEvent_Invocations.append(event)

        if let mock = buildContentEvent_MockMethod {
            return await mock(event)
        } else if let mock = buildContentEvent_MockValue {
            return mock
        } else {
            fatalError("no mock for `buildContentEvent`")
        }
    }

}

public class MockUserLocalStoreProtocol: UserLocalStoreProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - fetchSelfUser

    public var fetchSelfUser_Invocations: [Void] = []
    public var fetchSelfUser_MockMethod: (() async -> ZMUser)?
    public var fetchSelfUser_MockValue: ZMUser?

    public func fetchSelfUser() async -> ZMUser {
        fetchSelfUser_Invocations.append(())

        if let mock = fetchSelfUser_MockMethod {
            return await mock()
        } else if let mock = fetchSelfUser_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfUser`")
        }
    }

    // MARK: - fetchUser

    public var fetchUserIdDomain_Invocations: [(id: UUID, domain: String?)] = []
    public var fetchUserIdDomain_MockError: Error?
    public var fetchUserIdDomain_MockMethod: ((UUID, String?) async throws -> ZMUser)?
    public var fetchUserIdDomain_MockValue: ZMUser?

    public func fetchUser(id: UUID, domain: String?) async throws -> ZMUser {
        fetchUserIdDomain_Invocations.append((id: id, domain: domain))

        if let error = fetchUserIdDomain_MockError {
            throw error
        }

        if let mock = fetchUserIdDomain_MockMethod {
            return try await mock(id, domain)
        } else if let mock = fetchUserIdDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchUserIdDomain`")
        }
    }

    // MARK: - fetchOrCreateUser

    public var fetchOrCreateUserIdDomain_Invocations: [(id: UUID, domain: String?)] = []
    public var fetchOrCreateUserIdDomain_MockMethod: ((UUID, String?) async -> ZMUser)?
    public var fetchOrCreateUserIdDomain_MockValue: ZMUser?

    public func fetchOrCreateUser(id: UUID, domain: String?) async -> ZMUser {
        fetchOrCreateUserIdDomain_Invocations.append((id: id, domain: domain))

        if let mock = fetchOrCreateUserIdDomain_MockMethod {
            return await mock(id, domain)
        } else if let mock = fetchOrCreateUserIdDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateUserIdDomain`")
        }
    }

    // MARK: - fetchOrCreateUsers

    public var fetchOrCreateUsersUserIDs_Invocations: [[(id: UUID, domain: String?)]] = []
    public var fetchOrCreateUsersUserIDs_MockMethod: (([(id: UUID, domain: String?)]) async -> Set<ZMUser>)?
    public var fetchOrCreateUsersUserIDs_MockValue: Set<ZMUser>?

    public func fetchOrCreateUsers(userIDs: [(id: UUID, domain: String?)]) async -> Set<ZMUser> {
        fetchOrCreateUsersUserIDs_Invocations.append(userIDs)

        if let mock = fetchOrCreateUsersUserIDs_MockMethod {
            return await mock(userIDs)
        } else if let mock = fetchOrCreateUsersUserIDs_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateUsersUserIDs`")
        }
    }

    // MARK: - deletePushToken

    public var deletePushToken_Invocations: [Void] = []
    public var deletePushToken_MockMethod: (() -> Void)?

    public func deletePushToken() {
        deletePushToken_Invocations.append(())

        guard let mock = deletePushToken_MockMethod else {
            fatalError("no mock for `deletePushToken`")
        }

        mock()
    }

    // MARK: - removeUserFromAllConversations

    public var removeUserFromAllConversationsIdDomainDate_Invocations: [(id: UUID, domain: String?, date: Date)] = []
    public var removeUserFromAllConversationsIdDomainDate_MockMethod: ((UUID, String?, Date) async -> Void)?

    public func removeUserFromAllConversations(id: UUID, domain: String?, date: Date) async {
        removeUserFromAllConversationsIdDomainDate_Invocations.append((id: id, domain: domain, date: date))

        guard let mock = removeUserFromAllConversationsIdDomainDate_MockMethod else {
            fatalError("no mock for `removeUserFromAllConversationsIdDomainDate`")
        }

        await mock(id, domain, date)
    }

    // MARK: - addSelfLegalHoldRequest

    public var addSelfLegalHoldRequestUserIDClientIDLastPrekey_Invocations: [(userID: UUID, clientID: String, lastPrekey: WireDataModel.LegalHoldRequest.Prekey)] = []
    public var addSelfLegalHoldRequestUserIDClientIDLastPrekey_MockMethod: ((UUID, String, WireDataModel.LegalHoldRequest.Prekey) async -> Void)?

    public func addSelfLegalHoldRequest(userID: UUID, clientID: String, lastPrekey: WireDataModel.LegalHoldRequest.Prekey) async {
        addSelfLegalHoldRequestUserIDClientIDLastPrekey_Invocations.append((userID: userID, clientID: clientID, lastPrekey: lastPrekey))

        guard let mock = addSelfLegalHoldRequestUserIDClientIDLastPrekey_MockMethod else {
            fatalError("no mock for `addSelfLegalHoldRequestUserIDClientIDLastPrekey`")
        }

        await mock(userID, clientID, lastPrekey)
    }

    // MARK: - cancelSelfUserLegalholdRequest

    public var cancelSelfUserLegalholdRequest_Invocations: [Void] = []
    public var cancelSelfUserLegalholdRequest_MockMethod: (() async -> Void)?

    public func cancelSelfUserLegalholdRequest() async {
        cancelSelfUserLegalholdRequest_Invocations.append(())

        guard let mock = cancelSelfUserLegalholdRequest_MockMethod else {
            fatalError("no mock for `cancelSelfUserLegalholdRequest`")
        }

        await mock()
    }

    // MARK: - updateSelfUserReadReceipts

    public var updateSelfUserReadReceiptsIsReadReceiptsEnabledIsReadReceiptsEnabledChangedRemotely_Invocations: [(isReadReceiptsEnabled: Bool, isReadReceiptsEnabledChangedRemotely: Bool)] = []
    public var updateSelfUserReadReceiptsIsReadReceiptsEnabledIsReadReceiptsEnabledChangedRemotely_MockMethod: ((Bool, Bool) async -> Void)?

    public func updateSelfUserReadReceipts(isReadReceiptsEnabled: Bool, isReadReceiptsEnabledChangedRemotely: Bool) async {
        updateSelfUserReadReceiptsIsReadReceiptsEnabledIsReadReceiptsEnabledChangedRemotely_Invocations.append((isReadReceiptsEnabled: isReadReceiptsEnabled, isReadReceiptsEnabledChangedRemotely: isReadReceiptsEnabledChangedRemotely))

        guard let mock = updateSelfUserReadReceiptsIsReadReceiptsEnabledIsReadReceiptsEnabledChangedRemotely_MockMethod else {
            fatalError("no mock for `updateSelfUserReadReceiptsIsReadReceiptsEnabledIsReadReceiptsEnabledChangedRemotely`")
        }

        await mock(isReadReceiptsEnabled, isReadReceiptsEnabledChangedRemotely)
    }

    // MARK: - updateSelfUserSupportedProtocols

    public var updateSelfUserSupportedProtocolsSupportedProtocols_Invocations: [Set<WireDataModel.MessageProtocol>] = []
    public var updateSelfUserSupportedProtocolsSupportedProtocols_MockMethod: ((Set<WireDataModel.MessageProtocol>) async -> Void)?

    public func updateSelfUserSupportedProtocols(supportedProtocols: Set<WireDataModel.MessageProtocol>) async {
        updateSelfUserSupportedProtocolsSupportedProtocols_Invocations.append(supportedProtocols)

        guard let mock = updateSelfUserSupportedProtocolsSupportedProtocols_MockMethod else {
            fatalError("no mock for `updateSelfUserSupportedProtocolsSupportedProtocols`")
        }

        await mock(supportedProtocols)
    }

    // MARK: - fetchUsersQualifiedIDs

    public var fetchUsersQualifiedIDs_Invocations: [Void] = []
    public var fetchUsersQualifiedIDs_MockError: Error?
    public var fetchUsersQualifiedIDs_MockMethod: (() async throws -> [WireDataModel.QualifiedID])?
    public var fetchUsersQualifiedIDs_MockValue: [WireDataModel.QualifiedID]?

    public func fetchUsersQualifiedIDs() async throws -> [WireDataModel.QualifiedID] {
        fetchUsersQualifiedIDs_Invocations.append(())

        if let error = fetchUsersQualifiedIDs_MockError {
            throw error
        }

        if let mock = fetchUsersQualifiedIDs_MockMethod {
            return try await mock()
        } else if let mock = fetchUsersQualifiedIDs_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchUsersQualifiedIDs`")
        }
    }

    // MARK: - isSelfUser

    public var isSelfUserIdDomain_Invocations: [(id: UUID, domain: String?)] = []
    public var isSelfUserIdDomain_MockError: Error?
    public var isSelfUserIdDomain_MockMethod: ((UUID, String?) async throws -> (user: ZMUser, isSelfUser: Bool))?
    public var isSelfUserIdDomain_MockValue: (user: ZMUser, isSelfUser: Bool)?

    public func isSelfUser(id: UUID, domain: String?) async throws -> (user: ZMUser, isSelfUser: Bool) {
        isSelfUserIdDomain_Invocations.append((id: id, domain: domain))

        if let error = isSelfUserIdDomain_MockError {
            throw error
        }

        if let mock = isSelfUserIdDomain_MockMethod {
            return try await mock(id, domain)
        } else if let mock = isSelfUserIdDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `isSelfUserIdDomain`")
        }
    }

    // MARK: - postAccountDeletedNotification

    public var postAccountDeletedNotification_Invocations: [Void] = []
    public var postAccountDeletedNotification_MockMethod: (() -> Void)?

    public func postAccountDeletedNotification() {
        postAccountDeletedNotification_Invocations.append(())

        guard let mock = postAccountDeletedNotification_MockMethod else {
            fatalError("no mock for `postAccountDeletedNotification`")
        }

        mock()
    }

    // MARK: - markAccountAsDeleted

    public var markAccountAsDeletedFor_Invocations: [ZMUser] = []
    public var markAccountAsDeletedFor_MockMethod: ((ZMUser) async -> Void)?

    public func markAccountAsDeleted(for user: ZMUser) async {
        markAccountAsDeletedFor_Invocations.append(user)

        guard let mock = markAccountAsDeletedFor_MockMethod else {
            fatalError("no mock for `markAccountAsDeletedFor`")
        }

        await mock(user)
    }

    // MARK: - updateSelfUserTrackingID

    public var updateSelfUserTrackingIDTrackingIDConversation_Invocations: [(trackingID: UUID, conversation: ZMConversation)] = []
    public var updateSelfUserTrackingIDTrackingIDConversation_MockMethod: ((UUID, ZMConversation) async -> Void)?

    public func updateSelfUserTrackingID(trackingID: UUID, conversation: ZMConversation) async {
        updateSelfUserTrackingIDTrackingIDConversation_Invocations.append((trackingID: trackingID, conversation: conversation))

        guard let mock = updateSelfUserTrackingIDTrackingIDConversation_MockMethod else {
            fatalError("no mock for `updateSelfUserTrackingIDTrackingIDConversation`")
        }

        await mock(trackingID, conversation)
    }

    // MARK: - persistUser

    public var persistUserUserInfo_Invocations: [NewUserInfo] = []
    public var persistUserUserInfo_MockMethod: ((NewUserInfo) async -> Void)?

    public func persistUser(userInfo: NewUserInfo) async {
        persistUserUserInfo_Invocations.append(userInfo)

        guard let mock = persistUserUserInfo_MockMethod else {
            fatalError("no mock for `persistUserUserInfo`")
        }

        await mock(userInfo)
    }

    // MARK: - updateUser

    public var updateUserUserUpdateInfo_Invocations: [UserUpdateInfo] = []
    public var updateUserUserUpdateInfo_MockMethod: ((UserUpdateInfo) async -> Void)?

    public func updateUser(userUpdateInfo: UserUpdateInfo) async {
        updateUserUserUpdateInfo_Invocations.append(userUpdateInfo)

        guard let mock = updateUserUserUpdateInfo_MockMethod else {
            fatalError("no mock for `updateUserUserUpdateInfo`")
        }

        await mock(userUpdateInfo)
    }

    // MARK: - fetchAllUserIDsWithOneOnOneConversation

    public var fetchAllUserIDsWithOneOnOneConversation_Invocations: [Void] = []
    public var fetchAllUserIDsWithOneOnOneConversation_MockError: Error?
    public var fetchAllUserIDsWithOneOnOneConversation_MockMethod: (() async throws -> [WireDataModel.QualifiedID])?
    public var fetchAllUserIDsWithOneOnOneConversation_MockValue: [WireDataModel.QualifiedID]?

    public func fetchAllUserIDsWithOneOnOneConversation() async throws -> [WireDataModel.QualifiedID] {
        fetchAllUserIDsWithOneOnOneConversation_Invocations.append(())

        if let error = fetchAllUserIDsWithOneOnOneConversation_MockError {
            throw error
        }

        if let mock = fetchAllUserIDsWithOneOnOneConversation_MockMethod {
            return try await mock()
        } else if let mock = fetchAllUserIDsWithOneOnOneConversation_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchAllUserIDsWithOneOnOneConversation`")
        }
    }

    // MARK: - fetchSelfUserSupportedProtocols

    public var fetchSelfUserSupportedProtocols_Invocations: [Void] = []
    public var fetchSelfUserSupportedProtocols_MockMethod: (() async -> Set<WireDataModel.MessageProtocol>)?
    public var fetchSelfUserSupportedProtocols_MockValue: Set<WireDataModel.MessageProtocol>?

    public func fetchSelfUserSupportedProtocols() async -> Set<WireDataModel.MessageProtocol> {
        fetchSelfUserSupportedProtocols_Invocations.append(())

        if let mock = fetchSelfUserSupportedProtocols_MockMethod {
            return await mock()
        } else if let mock = fetchSelfUserSupportedProtocols_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfUserSupportedProtocols`")
        }
    }

    // MARK: - selfUserInfo

    public var selfUserInfo_Invocations: [Void] = []
    public var selfUserInfo_MockMethod: (() async -> (id: UUID, clientId: String?))?
    public var selfUserInfo_MockValue: (id: UUID, clientId: String?)?

    public func selfUserInfo() async -> (id: UUID, clientId: String?) {
        selfUserInfo_Invocations.append(())

        if let mock = selfUserInfo_MockMethod {
            return await mock()
        } else if let mock = selfUserInfo_MockValue {
            return mock
        } else {
            fatalError("no mock for `selfUserInfo`")
        }
    }

    // MARK: - name

    public var nameFor_Invocations: [ZMUser] = []
    public var nameFor_MockMethod: ((ZMUser) async -> String?)?
    public var nameFor_MockValue: String??

    public func name(for user: ZMUser) async -> String? {
        nameFor_Invocations.append(user)

        if let mock = nameFor_MockMethod {
            return await mock(user)
        } else if let mock = nameFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `nameFor`")
        }
    }

    // MARK: - teamName

    public var teamNameFor_Invocations: [ZMUser] = []
    public var teamNameFor_MockMethod: ((ZMUser) async -> String?)?
    public var teamNameFor_MockValue: String??

    public func teamName(for user: ZMUser) async -> String? {
        teamNameFor_Invocations.append(user)

        if let mock = teamNameFor_MockMethod {
            return await mock(user)
        } else if let mock = teamNameFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `teamNameFor`")
        }
    }

    // MARK: - id

    public var idFor_Invocations: [ZMUser] = []
    public var idFor_MockMethod: ((ZMUser) async -> UUID)?
    public var idFor_MockValue: UUID?

    public func id(for user: ZMUser) async -> UUID {
        idFor_Invocations.append(user)

        if let mock = idFor_MockMethod {
            return await mock(user)
        } else if let mock = idFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `idFor`")
        }
    }

    // MARK: - fetchSelfUserAvailability

    public var fetchSelfUserAvailability_Invocations: [Void] = []
    public var fetchSelfUserAvailability_MockMethod: (() async -> Availability)?
    public var fetchSelfUserAvailability_MockValue: Availability?

    public func fetchSelfUserAvailability() async -> Availability {
        fetchSelfUserAvailability_Invocations.append(())

        if let mock = fetchSelfUserAvailability_MockMethod {
            return await mock()
        } else if let mock = fetchSelfUserAvailability_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfUserAvailability`")
        }
    }

    // MARK: - updateUser

    public var updateUserWithAvailability_Invocations: [(userID: WireDataModel.QualifiedID, availability: Availability)] = []
    public var updateUserWithAvailability_MockMethod: ((WireDataModel.QualifiedID, Availability) async -> Void)?

    public func updateUser(with userID: WireDataModel.QualifiedID, availability: Availability) async {
        updateUserWithAvailability_Invocations.append((userID: userID, availability: availability))

        guard let mock = updateUserWithAvailability_MockMethod else {
            fatalError("no mock for `updateUserWithAvailability`")
        }

        await mock(userID, availability)
    }

}

public class MockUserRepositoryProtocol: UserRepositoryProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - pullSelfUser

    public var pullSelfUser_Invocations: [Void] = []
    public var pullSelfUser_MockError: Error?
    public var pullSelfUser_MockMethod: (() async throws -> Void)?

    public func pullSelfUser() async throws {
        pullSelfUser_Invocations.append(())

        if let error = pullSelfUser_MockError {
            throw error
        }

        guard let mock = pullSelfUser_MockMethod else {
            fatalError("no mock for `pullSelfUser`")
        }

        try await mock()
    }

    // MARK: - fetchSelfUser

    public var fetchSelfUser_Invocations: [Void] = []
    public var fetchSelfUser_MockMethod: (() async -> ZMUser)?
    public var fetchSelfUser_MockValue: ZMUser?

    public func fetchSelfUser() async -> ZMUser {
        fetchSelfUser_Invocations.append(())

        if let mock = fetchSelfUser_MockMethod {
            return await mock()
        } else if let mock = fetchSelfUser_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfUser`")
        }
    }

    // MARK: - fetchUser

    public var fetchUserIdDomain_Invocations: [(id: UUID, domain: String?)] = []
    public var fetchUserIdDomain_MockError: Error?
    public var fetchUserIdDomain_MockMethod: ((UUID, String?) async throws -> ZMUser)?
    public var fetchUserIdDomain_MockValue: ZMUser?

    public func fetchUser(id: UUID, domain: String?) async throws -> ZMUser {
        fetchUserIdDomain_Invocations.append((id: id, domain: domain))

        if let error = fetchUserIdDomain_MockError {
            throw error
        }

        if let mock = fetchUserIdDomain_MockMethod {
            return try await mock(id, domain)
        } else if let mock = fetchUserIdDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchUserIdDomain`")
        }
    }

    // MARK: - pullKnownUsers

    public var pullKnownUsers_Invocations: [Void] = []
    public var pullKnownUsers_MockError: Error?
    public var pullKnownUsers_MockMethod: (() async throws -> Void)?

    public func pullKnownUsers() async throws {
        pullKnownUsers_Invocations.append(())

        if let error = pullKnownUsers_MockError {
            throw error
        }

        guard let mock = pullKnownUsers_MockMethod else {
            fatalError("no mock for `pullKnownUsers`")
        }

        try await mock()
    }

    // MARK: - pullUsers

    public var pullUsersUserIDs_Invocations: [[WireDataModel.QualifiedID]] = []
    public var pullUsersUserIDs_MockError: Error?
    public var pullUsersUserIDs_MockMethod: (([WireDataModel.QualifiedID]) async throws -> Void)?

    public func pullUsers(userIDs: [WireDataModel.QualifiedID]) async throws {
        pullUsersUserIDs_Invocations.append(userIDs)

        if let error = pullUsersUserIDs_MockError {
            throw error
        }

        guard let mock = pullUsersUserIDs_MockMethod else {
            fatalError("no mock for `pullUsersUserIDs`")
        }

        try await mock(userIDs)
    }

    // MARK: - updateUser

    public var updateUserFrom_Invocations: [UserUpdateEvent] = []
    public var updateUserFrom_MockMethod: ((UserUpdateEvent) async -> Void)?

    public func updateUser(from event: UserUpdateEvent) async {
        updateUserFrom_Invocations.append(event)

        guard let mock = updateUserFrom_MockMethod else {
            fatalError("no mock for `updateUserFrom`")
        }

        await mock(event)
    }

    // MARK: - fetchOrCreateUser

    public var fetchOrCreateUserIdDomain_Invocations: [(id: UUID, domain: String?)] = []
    public var fetchOrCreateUserIdDomain_MockMethod: ((UUID, String?) async -> ZMUser)?
    public var fetchOrCreateUserIdDomain_MockValue: ZMUser?

    public func fetchOrCreateUser(id: UUID, domain: String?) async -> ZMUser {
        fetchOrCreateUserIdDomain_Invocations.append((id: id, domain: domain))

        if let mock = fetchOrCreateUserIdDomain_MockMethod {
            return await mock(id, domain)
        } else if let mock = fetchOrCreateUserIdDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateUserIdDomain`")
        }
    }

    // MARK: - removePushToken

    public var removePushToken_Invocations: [Void] = []
    public var removePushToken_MockMethod: (() -> Void)?

    public func removePushToken() {
        removePushToken_Invocations.append(())

        guard let mock = removePushToken_MockMethod else {
            fatalError("no mock for `removePushToken`")
        }

        mock()
    }

    // MARK: - addLegalHoldRequest

    public var addLegalHoldRequestUserIDClientIDLastPrekey_Invocations: [(userID: UUID, clientID: String, lastPrekey: Prekey)] = []
    public var addLegalHoldRequestUserIDClientIDLastPrekey_MockMethod: ((UUID, String, Prekey) async -> Void)?

    public func addLegalHoldRequest(userID: UUID, clientID: String, lastPrekey: Prekey) async {
        addLegalHoldRequestUserIDClientIDLastPrekey_Invocations.append((userID: userID, clientID: clientID, lastPrekey: lastPrekey))

        guard let mock = addLegalHoldRequestUserIDClientIDLastPrekey_MockMethod else {
            fatalError("no mock for `addLegalHoldRequestUserIDClientIDLastPrekey`")
        }

        await mock(userID, clientID, lastPrekey)
    }

    // MARK: - disableUserLegalHold

    public var disableUserLegalHold_Invocations: [Void] = []
    public var disableUserLegalHold_MockMethod: (() async -> Void)?

    public func disableUserLegalHold() async {
        disableUserLegalHold_Invocations.append(())

        guard let mock = disableUserLegalHold_MockMethod else {
            fatalError("no mock for `disableUserLegalHold`")
        }

        await mock()
    }

    // MARK: - updateUserProperty

    public var updateUserProperty_Invocations: [WireNetwork.UserProperty] = []
    public var updateUserProperty_MockError: Error?
    public var updateUserProperty_MockMethod: ((WireNetwork.UserProperty) async throws -> Void)?

    public func updateUserProperty(_ userProperty: WireNetwork.UserProperty) async throws {
        updateUserProperty_Invocations.append(userProperty)

        if let error = updateUserProperty_MockError {
            throw error
        }

        guard let mock = updateUserProperty_MockMethod else {
            fatalError("no mock for `updateUserProperty`")
        }

        try await mock(userProperty)
    }

    // MARK: - deleteUserProperty

    public var deleteUserPropertyWithKey_Invocations: [UserProperty.Key] = []
    public var deleteUserPropertyWithKey_MockMethod: ((UserProperty.Key) async -> Void)?

    public func deleteUserProperty(withKey key: UserProperty.Key) async {
        deleteUserPropertyWithKey_Invocations.append(key)

        guard let mock = deleteUserPropertyWithKey_MockMethod else {
            fatalError("no mock for `deleteUserPropertyWithKey`")
        }

        await mock(key)
    }

    // MARK: - deleteUserAccount

    public var deleteUserAccountIdDomainAt_Invocations: [(id: UUID, domain: String?, date: Date)] = []
    public var deleteUserAccountIdDomainAt_MockError: Error?
    public var deleteUserAccountIdDomainAt_MockMethod: ((UUID, String?, Date) async throws -> Void)?

    public func deleteUserAccount(id: UUID, domain: String?, at date: Date) async throws {
        deleteUserAccountIdDomainAt_Invocations.append((id: id, domain: domain, date: date))

        if let error = deleteUserAccountIdDomainAt_MockError {
            throw error
        }

        guard let mock = deleteUserAccountIdDomainAt_MockMethod else {
            fatalError("no mock for `deleteUserAccountIdDomainAt`")
        }

        try await mock(id, domain, date)
    }

    // MARK: - isSelfUser

    public var isSelfUserIdDomain_Invocations: [(id: UUID, domain: String?)] = []
    public var isSelfUserIdDomain_MockError: Error?
    public var isSelfUserIdDomain_MockMethod: ((UUID, String?) async throws -> Bool)?
    public var isSelfUserIdDomain_MockValue: Bool?

    public func isSelfUser(id: UUID, domain: String?) async throws -> Bool {
        isSelfUserIdDomain_Invocations.append((id: id, domain: domain))

        if let error = isSelfUserIdDomain_MockError {
            throw error
        }

        if let mock = isSelfUserIdDomain_MockMethod {
            return try await mock(id, domain)
        } else if let mock = isSelfUserIdDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `isSelfUserIdDomain`")
        }
    }

    // MARK: - fetchAllUserIDsWithOneOnOneConversation

    public var fetchAllUserIDsWithOneOnOneConversation_Invocations: [Void] = []
    public var fetchAllUserIDsWithOneOnOneConversation_MockError: Error?
    public var fetchAllUserIDsWithOneOnOneConversation_MockMethod: (() async throws -> [WireDataModel.QualifiedID])?
    public var fetchAllUserIDsWithOneOnOneConversation_MockValue: [WireDataModel.QualifiedID]?

    public func fetchAllUserIDsWithOneOnOneConversation() async throws -> [WireDataModel.QualifiedID] {
        fetchAllUserIDsWithOneOnOneConversation_Invocations.append(())

        if let error = fetchAllUserIDsWithOneOnOneConversation_MockError {
            throw error
        }

        if let mock = fetchAllUserIDsWithOneOnOneConversation_MockMethod {
            return try await mock()
        } else if let mock = fetchAllUserIDsWithOneOnOneConversation_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchAllUserIDsWithOneOnOneConversation`")
        }
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
