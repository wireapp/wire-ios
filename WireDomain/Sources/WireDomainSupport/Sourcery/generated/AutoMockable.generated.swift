// Generated using Sourcery 2.2.6 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

// swiftlint:disable line_length
// swiftlint:disable variable_name

import GenericMessageProtocol
import WireNetwork
import WireDataModel
import WireDomainPackage
import WireCoreCrypto



@testable import WireDomain
























public class BackendConfigLocalStoreProtocolMock: BackendConfigLocalStoreProtocol {

    public init() {}

    public var isMLSEnabled: Bool {
        get { return underlyingIsMLSEnabled }
        set(value) { underlyingIsMLSEnabled = value }
    }
    public var underlyingIsMLSEnabled: (Bool)!


    //MARK: - storeIsMLSEnabledStatus

    public var storeIsMLSEnabledStatusNewValueBoolVoidCallsCount = 0
    public var storeIsMLSEnabledStatusNewValueBoolVoidCalled: Bool {
        return storeIsMLSEnabledStatusNewValueBoolVoidCallsCount > 0
    }
    public var storeIsMLSEnabledStatusNewValueBoolVoidReceivedNewValue: (Bool)?
    public var storeIsMLSEnabledStatusNewValueBoolVoidReceivedInvocations: [(Bool)] = []
    public var storeIsMLSEnabledStatusNewValueBoolVoidClosure: ((Bool) -> Void)?

    public func storeIsMLSEnabledStatus(newValue: Bool) {
        storeIsMLSEnabledStatusNewValueBoolVoidCallsCount += 1
        storeIsMLSEnabledStatusNewValueBoolVoidReceivedNewValue = newValue
        storeIsMLSEnabledStatusNewValueBoolVoidReceivedInvocations.append(newValue)
        storeIsMLSEnabledStatusNewValueBoolVoidClosure?(newValue)
    }


}
class BackendConfigRepositoryProtocolMock: BackendConfigRepositoryProtocol {




    //MARK: - pullMLSBackendStatus

    var pullMLSBackendStatusVoidCallsCount = 0
    var pullMLSBackendStatusVoidCalled: Bool {
        return pullMLSBackendStatusVoidCallsCount > 0
    }
    var pullMLSBackendStatusVoidClosure: (() async -> Void)?

    func pullMLSBackendStatus() async {
        pullMLSBackendStatusVoidCallsCount += 1
        await pullMLSBackendStatusVoidClosure?()
    }


}
public class CalculateSupportedProtocolsUseCaseProtocolMock: CalculateSupportedProtocolsUseCaseProtocol {

    public init() {}



    //MARK: - invoke

    public var invokeSetWireNetworkMessageProtocolCallsCount = 0
    public var invokeSetWireNetworkMessageProtocolCalled: Bool {
        return invokeSetWireNetworkMessageProtocolCallsCount > 0
    }
    public var invokeSetWireNetworkMessageProtocolReturnValue: Set<WireNetwork.MessageProtocol>!
    public var invokeSetWireNetworkMessageProtocolClosure: (() async -> Set<WireNetwork.MessageProtocol>)?

    public func invoke() async -> Set<WireNetwork.MessageProtocol> {
        invokeSetWireNetworkMessageProtocolCallsCount += 1
        if let invokeSetWireNetworkMessageProtocolClosure = invokeSetWireNetworkMessageProtocolClosure {
            return await invokeSetWireNetworkMessageProtocolClosure()
        } else {
            return invokeSetWireNetworkMessageProtocolReturnValue
        }
    }


}
public class ConnectionsLocalStoreProtocolMock: ConnectionsLocalStoreProtocol {

    public init() {}



    //MARK: - storeConnection

    public var storeConnectionConnectionInfoConnectionInfoVoidThrowableError: (any Error)?
    public var storeConnectionConnectionInfoConnectionInfoVoidCallsCount = 0
    public var storeConnectionConnectionInfoConnectionInfoVoidCalled: Bool {
        return storeConnectionConnectionInfoConnectionInfoVoidCallsCount > 0
    }
    public var storeConnectionConnectionInfoConnectionInfoVoidReceivedConnectionInfo: (ConnectionInfo)?
    public var storeConnectionConnectionInfoConnectionInfoVoidReceivedInvocations: [(ConnectionInfo)] = []
    public var storeConnectionConnectionInfoConnectionInfoVoidClosure: ((ConnectionInfo) async throws -> Void)?

    public func storeConnection(_ connectionInfo: ConnectionInfo) async throws {
        storeConnectionConnectionInfoConnectionInfoVoidCallsCount += 1
        storeConnectionConnectionInfoConnectionInfoVoidReceivedConnectionInfo = connectionInfo
        storeConnectionConnectionInfoConnectionInfoVoidReceivedInvocations.append(connectionInfo)
        if let error = storeConnectionConnectionInfoConnectionInfoVoidThrowableError {
            throw error
        }
        try await storeConnectionConnectionInfoConnectionInfoVoidClosure?(connectionInfo)
    }


}
public class ConnectionsRepositoryProtocolMock: ConnectionsRepositoryProtocol {

    public init() {}



    //MARK: - pullConnections

    public var pullConnectionsVoidThrowableError: (any Error)?
    public var pullConnectionsVoidCallsCount = 0
    public var pullConnectionsVoidCalled: Bool {
        return pullConnectionsVoidCallsCount > 0
    }
    public var pullConnectionsVoidClosure: (() async throws -> Void)?

    public func pullConnections() async throws {
        pullConnectionsVoidCallsCount += 1
        if let error = pullConnectionsVoidThrowableError {
            throw error
        }
        try await pullConnectionsVoidClosure?()
    }

    //MARK: - updateConnection

    public var updateConnectionConnectionConnectionVoidThrowableError: (any Error)?
    public var updateConnectionConnectionConnectionVoidCallsCount = 0
    public var updateConnectionConnectionConnectionVoidCalled: Bool {
        return updateConnectionConnectionConnectionVoidCallsCount > 0
    }
    public var updateConnectionConnectionConnectionVoidReceivedConnection: (Connection)?
    public var updateConnectionConnectionConnectionVoidReceivedInvocations: [(Connection)] = []
    public var updateConnectionConnectionConnectionVoidClosure: ((Connection) async throws -> Void)?

    public func updateConnection(_ connection: Connection) async throws {
        updateConnectionConnectionConnectionVoidCallsCount += 1
        updateConnectionConnectionConnectionVoidReceivedConnection = connection
        updateConnectionConnectionConnectionVoidReceivedInvocations.append(connection)
        if let error = updateConnectionConnectionConnectionVoidThrowableError {
            throw error
        }
        try await updateConnectionConnectionConnectionVoidClosure?(connection)
    }


}
class ConversationAudioMessageNotificationBuilderProtocolMock: ConversationAudioMessageNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount = 0
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCalled: Bool {
        return buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount > 0
    }
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments: (conversationID: ConversationID, senderID: UserID)?
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations: [(conversationID: ConversationID, senderID: UserID)] = []
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue: UserNotification!
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure: ((ConversationID, UserID) async -> UserNotification)?

    func buildContent(conversationID: ConversationID, senderID: UserID) async -> UserNotification {
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount += 1
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments = (conversationID: conversationID, senderID: senderID)
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations.append((conversationID: conversationID, senderID: senderID))
        if let buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure = buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure {
            return await buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure(conversationID, senderID)
        } else {
            return buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue
        }
    }


}
class ConversationCallingEventNotificationBuilderProtocolMock: ConversationCallingEventNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentCallingCallingAtTimeDateConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount = 0
    var buildContentCallingCallingAtTimeDateConversationIDConversationIDSenderIDUserIDUserNotificationCalled: Bool {
        return buildContentCallingCallingAtTimeDateConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount > 0
    }
    var buildContentCallingCallingAtTimeDateConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments: (calling: Calling, time: Date?, conversationID: ConversationID, senderID: UserID)?
    var buildContentCallingCallingAtTimeDateConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations: [(calling: Calling, time: Date?, conversationID: ConversationID, senderID: UserID)] = []
    var buildContentCallingCallingAtTimeDateConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue: UserNotification?
    var buildContentCallingCallingAtTimeDateConversationIDConversationIDSenderIDUserIDUserNotificationClosure: ((Calling, Date?, ConversationID, UserID) async -> UserNotification?)?

    func buildContent(calling: Calling, at time: Date?, conversationID: ConversationID, senderID: UserID) async -> UserNotification? {
        buildContentCallingCallingAtTimeDateConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount += 1
        buildContentCallingCallingAtTimeDateConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments = (calling: calling, time: time, conversationID: conversationID, senderID: senderID)
        buildContentCallingCallingAtTimeDateConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations.append((calling: calling, time: time, conversationID: conversationID, senderID: senderID))
        if let buildContentCallingCallingAtTimeDateConversationIDConversationIDSenderIDUserIDUserNotificationClosure = buildContentCallingCallingAtTimeDateConversationIDConversationIDSenderIDUserIDUserNotificationClosure {
            return await buildContentCallingCallingAtTimeDateConversationIDConversationIDSenderIDUserIDUserNotificationClosure(calling, time, conversationID, senderID)
        } else {
            return buildContentCallingCallingAtTimeDateConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue
        }
    }


}
class ConversationCreateEventNotificationBuilderProtocolMock: ConversationCreateEventNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentEventConversationCreateEventUserNotificationCallsCount = 0
    var buildContentEventConversationCreateEventUserNotificationCalled: Bool {
        return buildContentEventConversationCreateEventUserNotificationCallsCount > 0
    }
    var buildContentEventConversationCreateEventUserNotificationReceivedEvent: (ConversationCreateEvent)?
    var buildContentEventConversationCreateEventUserNotificationReceivedInvocations: [(ConversationCreateEvent)] = []
    var buildContentEventConversationCreateEventUserNotificationReturnValue: UserNotification?
    var buildContentEventConversationCreateEventUserNotificationClosure: ((ConversationCreateEvent) async -> UserNotification?)?

    func buildContent(event: ConversationCreateEvent) async -> UserNotification? {
        buildContentEventConversationCreateEventUserNotificationCallsCount += 1
        buildContentEventConversationCreateEventUserNotificationReceivedEvent = event
        buildContentEventConversationCreateEventUserNotificationReceivedInvocations.append(event)
        if let buildContentEventConversationCreateEventUserNotificationClosure = buildContentEventConversationCreateEventUserNotificationClosure {
            return await buildContentEventConversationCreateEventUserNotificationClosure(event)
        } else {
            return buildContentEventConversationCreateEventUserNotificationReturnValue
        }
    }


}
class ConversationDeleteEventNotificationBuilderProtocolMock: ConversationDeleteEventNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentEventConversationDeleteEventUserNotificationCallsCount = 0
    var buildContentEventConversationDeleteEventUserNotificationCalled: Bool {
        return buildContentEventConversationDeleteEventUserNotificationCallsCount > 0
    }
    var buildContentEventConversationDeleteEventUserNotificationReceivedEvent: (ConversationDeleteEvent)?
    var buildContentEventConversationDeleteEventUserNotificationReceivedInvocations: [(ConversationDeleteEvent)] = []
    var buildContentEventConversationDeleteEventUserNotificationReturnValue: UserNotification?
    var buildContentEventConversationDeleteEventUserNotificationClosure: ((ConversationDeleteEvent) async -> UserNotification?)?

    func buildContent(event: ConversationDeleteEvent) async -> UserNotification? {
        buildContentEventConversationDeleteEventUserNotificationCallsCount += 1
        buildContentEventConversationDeleteEventUserNotificationReceivedEvent = event
        buildContentEventConversationDeleteEventUserNotificationReceivedInvocations.append(event)
        if let buildContentEventConversationDeleteEventUserNotificationClosure = buildContentEventConversationDeleteEventUserNotificationClosure {
            return await buildContentEventConversationDeleteEventUserNotificationClosure(event)
        } else {
            return buildContentEventConversationDeleteEventUserNotificationReturnValue
        }
    }


}
class ConversationEphemeralMessageNotificationBuilderProtocolMock: ConversationEphemeralMessageNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentEphemeralEphemeralConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount = 0
    var buildContentEphemeralEphemeralConversationIDConversationIDSenderIDUserIDUserNotificationCalled: Bool {
        return buildContentEphemeralEphemeralConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount > 0
    }
    var buildContentEphemeralEphemeralConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments: (ephemeral: Ephemeral, conversationID: ConversationID, senderID: UserID)?
    var buildContentEphemeralEphemeralConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations: [(ephemeral: Ephemeral, conversationID: ConversationID, senderID: UserID)] = []
    var buildContentEphemeralEphemeralConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue: UserNotification?
    var buildContentEphemeralEphemeralConversationIDConversationIDSenderIDUserIDUserNotificationClosure: ((Ephemeral, ConversationID, UserID) async -> UserNotification?)?

    func buildContent(ephemeral: Ephemeral, conversationID: ConversationID, senderID: UserID) async -> UserNotification? {
        buildContentEphemeralEphemeralConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount += 1
        buildContentEphemeralEphemeralConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments = (ephemeral: ephemeral, conversationID: conversationID, senderID: senderID)
        buildContentEphemeralEphemeralConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations.append((ephemeral: ephemeral, conversationID: conversationID, senderID: senderID))
        if let buildContentEphemeralEphemeralConversationIDConversationIDSenderIDUserIDUserNotificationClosure = buildContentEphemeralEphemeralConversationIDConversationIDSenderIDUserIDUserNotificationClosure {
            return await buildContentEphemeralEphemeralConversationIDConversationIDSenderIDUserIDUserNotificationClosure(ephemeral, conversationID, senderID)
        } else {
            return buildContentEphemeralEphemeralConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue
        }
    }


}
class ConversationEventNotificationBuilderProtocolMock: ConversationEventNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentEventConversationEventUserNotificationThrowableError: (any Error)?
    var buildContentEventConversationEventUserNotificationCallsCount = 0
    var buildContentEventConversationEventUserNotificationCalled: Bool {
        return buildContentEventConversationEventUserNotificationCallsCount > 0
    }
    var buildContentEventConversationEventUserNotificationReceivedEvent: (ConversationEvent)?
    var buildContentEventConversationEventUserNotificationReceivedInvocations: [(ConversationEvent)] = []
    var buildContentEventConversationEventUserNotificationReturnValue: UserNotification?
    var buildContentEventConversationEventUserNotificationClosure: ((ConversationEvent) async throws -> UserNotification?)?

    func buildContent(event: ConversationEvent) async throws -> UserNotification? {
        buildContentEventConversationEventUserNotificationCallsCount += 1
        buildContentEventConversationEventUserNotificationReceivedEvent = event
        buildContentEventConversationEventUserNotificationReceivedInvocations.append(event)
        if let error = buildContentEventConversationEventUserNotificationThrowableError {
            throw error
        }
        if let buildContentEventConversationEventUserNotificationClosure = buildContentEventConversationEventUserNotificationClosure {
            return try await buildContentEventConversationEventUserNotificationClosure(event)
        } else {
            return buildContentEventConversationEventUserNotificationReturnValue
        }
    }


}
class ConversationEventProcessorProtocolMock: ConversationEventProcessorProtocol {




    //MARK: - processEvent

    var processEventEventConversationEventVoidThrowableError: (any Error)?
    var processEventEventConversationEventVoidCallsCount = 0
    var processEventEventConversationEventVoidCalled: Bool {
        return processEventEventConversationEventVoidCallsCount > 0
    }
    var processEventEventConversationEventVoidReceivedEvent: (ConversationEvent)?
    var processEventEventConversationEventVoidReceivedInvocations: [(ConversationEvent)] = []
    var processEventEventConversationEventVoidClosure: ((ConversationEvent) async throws -> Void)?

    func processEvent(_ event: ConversationEvent) async throws {
        processEventEventConversationEventVoidCallsCount += 1
        processEventEventConversationEventVoidReceivedEvent = event
        processEventEventConversationEventVoidReceivedInvocations.append(event)
        if let error = processEventEventConversationEventVoidThrowableError {
            throw error
        }
        try await processEventEventConversationEventVoidClosure?(event)
    }


}
class ConversationFileUploadMessageNotificationBuilderProtocolMock: ConversationFileUploadMessageNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount = 0
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCalled: Bool {
        return buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount > 0
    }
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments: (conversationID: ConversationID, senderID: UserID)?
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations: [(conversationID: ConversationID, senderID: UserID)] = []
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue: UserNotification!
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure: ((ConversationID, UserID) async -> UserNotification)?

    func buildContent(conversationID: ConversationID, senderID: UserID) async -> UserNotification {
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount += 1
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments = (conversationID: conversationID, senderID: senderID)
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations.append((conversationID: conversationID, senderID: senderID))
        if let buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure = buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure {
            return await buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure(conversationID, senderID)
        } else {
            return buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue
        }
    }


}
class ConversationHiddenMessageNotificationBuilderProtocolMock: ConversationHiddenMessageNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount = 0
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCalled: Bool {
        return buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount > 0
    }
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments: (conversationID: ConversationID, senderID: UserID)?
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations: [(conversationID: ConversationID, senderID: UserID)] = []
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue: UserNotification!
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure: ((ConversationID, UserID) async -> UserNotification)?

    func buildContent(conversationID: ConversationID, senderID: UserID) async -> UserNotification {
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount += 1
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments = (conversationID: conversationID, senderID: senderID)
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations.append((conversationID: conversationID, senderID: senderID))
        if let buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure = buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure {
            return await buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure(conversationID, senderID)
        } else {
            return buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue
        }
    }


}
class ConversationImageMessageNotificationBuilderProtocolMock: ConversationImageMessageNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount = 0
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCalled: Bool {
        return buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount > 0
    }
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments: (conversationID: ConversationID, senderID: UserID)?
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations: [(conversationID: ConversationID, senderID: UserID)] = []
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue: UserNotification!
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure: ((ConversationID, UserID) async -> UserNotification)?

    func buildContent(conversationID: ConversationID, senderID: UserID) async -> UserNotification {
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount += 1
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments = (conversationID: conversationID, senderID: senderID)
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations.append((conversationID: conversationID, senderID: senderID))
        if let buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure = buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure {
            return await buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure(conversationID, senderID)
        } else {
            return buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue
        }
    }


}
public class ConversationLabelsLocalStoreProtocolMock: ConversationLabelsLocalStoreProtocol {

    public init() {}



    //MARK: - setLabels

    public var setLabelsLabelsConversationLabelInfoVoidThrowableError: (any Error)?
    public var setLabelsLabelsConversationLabelInfoVoidCallsCount = 0
    public var setLabelsLabelsConversationLabelInfoVoidCalled: Bool {
        return setLabelsLabelsConversationLabelInfoVoidCallsCount > 0
    }
    public var setLabelsLabelsConversationLabelInfoVoidReceivedLabels: ([ConversationLabelInfo])?
    public var setLabelsLabelsConversationLabelInfoVoidReceivedInvocations: [([ConversationLabelInfo])] = []
    public var setLabelsLabelsConversationLabelInfoVoidClosure: (([ConversationLabelInfo]) async throws -> Void)?

    public func setLabels(_ labels: [ConversationLabelInfo]) async throws {
        setLabelsLabelsConversationLabelInfoVoidCallsCount += 1
        setLabelsLabelsConversationLabelInfoVoidReceivedLabels = labels
        setLabelsLabelsConversationLabelInfoVoidReceivedInvocations.append(labels)
        if let error = setLabelsLabelsConversationLabelInfoVoidThrowableError {
            throw error
        }
        try await setLabelsLabelsConversationLabelInfoVoidClosure?(labels)
    }


}
public class ConversationLabelsRepositoryProtocolMock: ConversationLabelsRepositoryProtocol {

    public init() {}



    //MARK: - pullConversationLabels

    public var pullConversationLabelsVoidThrowableError: (any Error)?
    public var pullConversationLabelsVoidCallsCount = 0
    public var pullConversationLabelsVoidCalled: Bool {
        return pullConversationLabelsVoidCallsCount > 0
    }
    public var pullConversationLabelsVoidClosure: (() async throws -> Void)?

    public func pullConversationLabels() async throws {
        pullConversationLabelsVoidCallsCount += 1
        if let error = pullConversationLabelsVoidThrowableError {
            throw error
        }
        try await pullConversationLabelsVoidClosure?()
    }

    //MARK: - updateConversationLabels

    public var updateConversationLabelsConversationLabelsConversationLabelVoidThrowableError: (any Error)?
    public var updateConversationLabelsConversationLabelsConversationLabelVoidCallsCount = 0
    public var updateConversationLabelsConversationLabelsConversationLabelVoidCalled: Bool {
        return updateConversationLabelsConversationLabelsConversationLabelVoidCallsCount > 0
    }
    public var updateConversationLabelsConversationLabelsConversationLabelVoidReceivedConversationLabels: ([ConversationLabel])?
    public var updateConversationLabelsConversationLabelsConversationLabelVoidReceivedInvocations: [([ConversationLabel])] = []
    public var updateConversationLabelsConversationLabelsConversationLabelVoidClosure: (([ConversationLabel]) async throws -> Void)?

    public func updateConversationLabels(_ conversationLabels: [ConversationLabel]) async throws {
        updateConversationLabelsConversationLabelsConversationLabelVoidCallsCount += 1
        updateConversationLabelsConversationLabelsConversationLabelVoidReceivedConversationLabels = conversationLabels
        updateConversationLabelsConversationLabelsConversationLabelVoidReceivedInvocations.append(conversationLabels)
        if let error = updateConversationLabelsConversationLabelsConversationLabelVoidThrowableError {
            throw error
        }
        try await updateConversationLabelsConversationLabelsConversationLabelVoidClosure?(conversationLabels)
    }


}
public class ConversationLocalStoreProtocolMock: ConversationLocalStoreProtocol {

    public init() {}



    //MARK: - fetchOrCreateConversation

    public var fetchOrCreateConversationIdUUIDDomainStringZMConversationCallsCount = 0
    public var fetchOrCreateConversationIdUUIDDomainStringZMConversationCalled: Bool {
        return fetchOrCreateConversationIdUUIDDomainStringZMConversationCallsCount > 0
    }
    public var fetchOrCreateConversationIdUUIDDomainStringZMConversationReceivedArguments: (id: UUID, domain: String?)?
    public var fetchOrCreateConversationIdUUIDDomainStringZMConversationReceivedInvocations: [(id: UUID, domain: String?)] = []
    public var fetchOrCreateConversationIdUUIDDomainStringZMConversationReturnValue: ZMConversation!
    public var fetchOrCreateConversationIdUUIDDomainStringZMConversationClosure: ((UUID, String?) async -> ZMConversation)?

    public func fetchOrCreateConversation(id: UUID, domain: String?) async -> ZMConversation {
        fetchOrCreateConversationIdUUIDDomainStringZMConversationCallsCount += 1
        fetchOrCreateConversationIdUUIDDomainStringZMConversationReceivedArguments = (id: id, domain: domain)
        fetchOrCreateConversationIdUUIDDomainStringZMConversationReceivedInvocations.append((id: id, domain: domain))
        if let fetchOrCreateConversationIdUUIDDomainStringZMConversationClosure = fetchOrCreateConversationIdUUIDDomainStringZMConversationClosure {
            return await fetchOrCreateConversationIdUUIDDomainStringZMConversationClosure(id, domain)
        } else {
            return fetchOrCreateConversationIdUUIDDomainStringZMConversationReturnValue
        }
    }

    //MARK: - storeConversation

    public var storeConversationConversationWireDomainConversationTimestampDateIsFederationEnabledBoolIsMLSEnabledBoolVoidCallsCount = 0
    public var storeConversationConversationWireDomainConversationTimestampDateIsFederationEnabledBoolIsMLSEnabledBoolVoidCalled: Bool {
        return storeConversationConversationWireDomainConversationTimestampDateIsFederationEnabledBoolIsMLSEnabledBoolVoidCallsCount > 0
    }
    public var storeConversationConversationWireDomainConversationTimestampDateIsFederationEnabledBoolIsMLSEnabledBoolVoidReceivedArguments: (conversation: WireDomain.Conversation, timestamp: Date, isFederationEnabled: Bool, isMLSEnabled: Bool)?
    public var storeConversationConversationWireDomainConversationTimestampDateIsFederationEnabledBoolIsMLSEnabledBoolVoidReceivedInvocations: [(conversation: WireDomain.Conversation, timestamp: Date, isFederationEnabled: Bool, isMLSEnabled: Bool)] = []
    public var storeConversationConversationWireDomainConversationTimestampDateIsFederationEnabledBoolIsMLSEnabledBoolVoidClosure: ((WireDomain.Conversation, Date, Bool, Bool) async -> Void)?

    public func storeConversation(_ conversation: WireDomain.Conversation, timestamp: Date, isFederationEnabled: Bool, isMLSEnabled: Bool) async {
        storeConversationConversationWireDomainConversationTimestampDateIsFederationEnabledBoolIsMLSEnabledBoolVoidCallsCount += 1
        storeConversationConversationWireDomainConversationTimestampDateIsFederationEnabledBoolIsMLSEnabledBoolVoidReceivedArguments = (conversation: conversation, timestamp: timestamp, isFederationEnabled: isFederationEnabled, isMLSEnabled: isMLSEnabled)
        storeConversationConversationWireDomainConversationTimestampDateIsFederationEnabledBoolIsMLSEnabledBoolVoidReceivedInvocations.append((conversation: conversation, timestamp: timestamp, isFederationEnabled: isFederationEnabled, isMLSEnabled: isMLSEnabled))
        await storeConversationConversationWireDomainConversationTimestampDateIsFederationEnabledBoolIsMLSEnabledBoolVoidClosure?(conversation, timestamp, isFederationEnabled, isMLSEnabled)
    }

    //MARK: - storeConversation

    public var storeConversationNeedsBackendUpdateBoolConversationIDUUIDConversationDomainStringVoidCallsCount = 0
    public var storeConversationNeedsBackendUpdateBoolConversationIDUUIDConversationDomainStringVoidCalled: Bool {
        return storeConversationNeedsBackendUpdateBoolConversationIDUUIDConversationDomainStringVoidCallsCount > 0
    }
    public var storeConversationNeedsBackendUpdateBoolConversationIDUUIDConversationDomainStringVoidReceivedArguments: (needsBackendUpdate: Bool, conversationID: UUID, conversationDomain: String)?
    public var storeConversationNeedsBackendUpdateBoolConversationIDUUIDConversationDomainStringVoidReceivedInvocations: [(needsBackendUpdate: Bool, conversationID: UUID, conversationDomain: String)] = []
    public var storeConversationNeedsBackendUpdateBoolConversationIDUUIDConversationDomainStringVoidClosure: ((Bool, UUID, String) async -> Void)?

    public func storeConversation(needsBackendUpdate: Bool, conversationID: UUID, conversationDomain: String) async {
        storeConversationNeedsBackendUpdateBoolConversationIDUUIDConversationDomainStringVoidCallsCount += 1
        storeConversationNeedsBackendUpdateBoolConversationIDUUIDConversationDomainStringVoidReceivedArguments = (needsBackendUpdate: needsBackendUpdate, conversationID: conversationID, conversationDomain: conversationDomain)
        storeConversationNeedsBackendUpdateBoolConversationIDUUIDConversationDomainStringVoidReceivedInvocations.append((needsBackendUpdate: needsBackendUpdate, conversationID: conversationID, conversationDomain: conversationDomain))
        await storeConversationNeedsBackendUpdateBoolConversationIDUUIDConversationDomainStringVoidClosure?(needsBackendUpdate, conversationID, conversationDomain)
    }

    //MARK: - storeFailedConversation

    public var storeFailedConversationConversationIDUUIDConversationDomainStringVoidCallsCount = 0
    public var storeFailedConversationConversationIDUUIDConversationDomainStringVoidCalled: Bool {
        return storeFailedConversationConversationIDUUIDConversationDomainStringVoidCallsCount > 0
    }
    public var storeFailedConversationConversationIDUUIDConversationDomainStringVoidReceivedArguments: (conversationID: UUID, conversationDomain: String)?
    public var storeFailedConversationConversationIDUUIDConversationDomainStringVoidReceivedInvocations: [(conversationID: UUID, conversationDomain: String)] = []
    public var storeFailedConversationConversationIDUUIDConversationDomainStringVoidClosure: ((UUID, String) async -> Void)?

    public func storeFailedConversation(conversationID: UUID, conversationDomain: String) async {
        storeFailedConversationConversationIDUUIDConversationDomainStringVoidCallsCount += 1
        storeFailedConversationConversationIDUUIDConversationDomainStringVoidReceivedArguments = (conversationID: conversationID, conversationDomain: conversationDomain)
        storeFailedConversationConversationIDUUIDConversationDomainStringVoidReceivedInvocations.append((conversationID: conversationID, conversationDomain: conversationDomain))
        await storeFailedConversationConversationIDUUIDConversationDomainStringVoidClosure?(conversationID, conversationDomain)
    }

    //MARK: - createMLSConversation

    public var createMLSConversationConversationIDUUIDConversationDomainStringMlsGroupIDMLSGroupIDVoidCallsCount = 0
    public var createMLSConversationConversationIDUUIDConversationDomainStringMlsGroupIDMLSGroupIDVoidCalled: Bool {
        return createMLSConversationConversationIDUUIDConversationDomainStringMlsGroupIDMLSGroupIDVoidCallsCount > 0
    }
    public var createMLSConversationConversationIDUUIDConversationDomainStringMlsGroupIDMLSGroupIDVoidReceivedArguments: (conversationID: UUID, conversationDomain: String?, mlsGroupID: MLSGroupID)?
    public var createMLSConversationConversationIDUUIDConversationDomainStringMlsGroupIDMLSGroupIDVoidReceivedInvocations: [(conversationID: UUID, conversationDomain: String?, mlsGroupID: MLSGroupID)] = []
    public var createMLSConversationConversationIDUUIDConversationDomainStringMlsGroupIDMLSGroupIDVoidClosure: ((UUID, String?, MLSGroupID) async -> Void)?

    public func createMLSConversation(conversationID: UUID, conversationDomain: String?, mlsGroupID: MLSGroupID) async {
        createMLSConversationConversationIDUUIDConversationDomainStringMlsGroupIDMLSGroupIDVoidCallsCount += 1
        createMLSConversationConversationIDUUIDConversationDomainStringMlsGroupIDMLSGroupIDVoidReceivedArguments = (conversationID: conversationID, conversationDomain: conversationDomain, mlsGroupID: mlsGroupID)
        createMLSConversationConversationIDUUIDConversationDomainStringMlsGroupIDMLSGroupIDVoidReceivedInvocations.append((conversationID: conversationID, conversationDomain: conversationDomain, mlsGroupID: mlsGroupID))
        await createMLSConversationConversationIDUUIDConversationDomainStringMlsGroupIDMLSGroupIDVoidClosure?(conversationID, conversationDomain, mlsGroupID)
    }

    //MARK: - fetchMLSConversation

    public var fetchMLSConversationGroupIDWireDataModelMLSGroupIDZMConversationCallsCount = 0
    public var fetchMLSConversationGroupIDWireDataModelMLSGroupIDZMConversationCalled: Bool {
        return fetchMLSConversationGroupIDWireDataModelMLSGroupIDZMConversationCallsCount > 0
    }
    public var fetchMLSConversationGroupIDWireDataModelMLSGroupIDZMConversationReceivedGroupID: (WireDataModel.MLSGroupID)?
    public var fetchMLSConversationGroupIDWireDataModelMLSGroupIDZMConversationReceivedInvocations: [(WireDataModel.MLSGroupID)] = []
    public var fetchMLSConversationGroupIDWireDataModelMLSGroupIDZMConversationReturnValue: ZMConversation?
    public var fetchMLSConversationGroupIDWireDataModelMLSGroupIDZMConversationClosure: ((WireDataModel.MLSGroupID) async -> ZMConversation?)?

    public func fetchMLSConversation(groupID: WireDataModel.MLSGroupID) async -> ZMConversation? {
        fetchMLSConversationGroupIDWireDataModelMLSGroupIDZMConversationCallsCount += 1
        fetchMLSConversationGroupIDWireDataModelMLSGroupIDZMConversationReceivedGroupID = groupID
        fetchMLSConversationGroupIDWireDataModelMLSGroupIDZMConversationReceivedInvocations.append(groupID)
        if let fetchMLSConversationGroupIDWireDataModelMLSGroupIDZMConversationClosure = fetchMLSConversationGroupIDWireDataModelMLSGroupIDZMConversationClosure {
            return await fetchMLSConversationGroupIDWireDataModelMLSGroupIDZMConversationClosure(groupID)
        } else {
            return fetchMLSConversationGroupIDWireDataModelMLSGroupIDZMConversationReturnValue
        }
    }

    //MARK: - fetchConversation

    public var fetchConversationIdUUIDDomainStringZMConversationCallsCount = 0
    public var fetchConversationIdUUIDDomainStringZMConversationCalled: Bool {
        return fetchConversationIdUUIDDomainStringZMConversationCallsCount > 0
    }
    public var fetchConversationIdUUIDDomainStringZMConversationReceivedArguments: (id: UUID, domain: String?)?
    public var fetchConversationIdUUIDDomainStringZMConversationReceivedInvocations: [(id: UUID, domain: String?)] = []
    public var fetchConversationIdUUIDDomainStringZMConversationReturnValue: ZMConversation?
    public var fetchConversationIdUUIDDomainStringZMConversationClosure: ((UUID, String?) async -> ZMConversation?)?

    public func fetchConversation(id: UUID, domain: String?) async -> ZMConversation? {
        fetchConversationIdUUIDDomainStringZMConversationCallsCount += 1
        fetchConversationIdUUIDDomainStringZMConversationReceivedArguments = (id: id, domain: domain)
        fetchConversationIdUUIDDomainStringZMConversationReceivedInvocations.append((id: id, domain: domain))
        if let fetchConversationIdUUIDDomainStringZMConversationClosure = fetchConversationIdUUIDDomainStringZMConversationClosure {
            return await fetchConversationIdUUIDDomainStringZMConversationClosure(id, domain)
        } else {
            return fetchConversationIdUUIDDomainStringZMConversationReturnValue
        }
    }

    //MARK: - wipeMLSGroup

    public var wipeMLSGroupGroupIDWireDataModelMLSGroupIDVoidThrowableError: (any Error)?
    public var wipeMLSGroupGroupIDWireDataModelMLSGroupIDVoidCallsCount = 0
    public var wipeMLSGroupGroupIDWireDataModelMLSGroupIDVoidCalled: Bool {
        return wipeMLSGroupGroupIDWireDataModelMLSGroupIDVoidCallsCount > 0
    }
    public var wipeMLSGroupGroupIDWireDataModelMLSGroupIDVoidReceivedGroupID: (WireDataModel.MLSGroupID)?
    public var wipeMLSGroupGroupIDWireDataModelMLSGroupIDVoidReceivedInvocations: [(WireDataModel.MLSGroupID)] = []
    public var wipeMLSGroupGroupIDWireDataModelMLSGroupIDVoidClosure: ((WireDataModel.MLSGroupID) async throws -> Void)?

    public func wipeMLSGroup(groupID: WireDataModel.MLSGroupID) async throws {
        wipeMLSGroupGroupIDWireDataModelMLSGroupIDVoidCallsCount += 1
        wipeMLSGroupGroupIDWireDataModelMLSGroupIDVoidReceivedGroupID = groupID
        wipeMLSGroupGroupIDWireDataModelMLSGroupIDVoidReceivedInvocations.append(groupID)
        if let error = wipeMLSGroupGroupIDWireDataModelMLSGroupIDVoidThrowableError {
            throw error
        }
        try await wipeMLSGroupGroupIDWireDataModelMLSGroupIDVoidClosure?(groupID)
    }

    //MARK: - removeParticipantFromAllGroupConversations

    public var removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringDateDateVoidThrowableError: (any Error)?
    public var removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringDateDateVoidCallsCount = 0
    public var removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringDateDateVoidCalled: Bool {
        return removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringDateDateVoidCallsCount > 0
    }
    public var removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringDateDateVoidReceivedArguments: (participantID: UUID, participantDomain: String?, date: Date)?
    public var removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringDateDateVoidReceivedInvocations: [(participantID: UUID, participantDomain: String?, date: Date)] = []
    public var removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringDateDateVoidClosure: ((UUID, String?, Date) async throws -> Void)?

    public func removeParticipantFromAllGroupConversations(participantID: UUID, participantDomain: String?, date: Date) async throws {
        removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringDateDateVoidCallsCount += 1
        removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringDateDateVoidReceivedArguments = (participantID: participantID, participantDomain: participantDomain, date: date)
        removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringDateDateVoidReceivedInvocations.append((participantID: participantID, participantDomain: participantDomain, date: date))
        if let error = removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringDateDateVoidThrowableError {
            throw error
        }
        try await removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringDateDateVoidClosure?(participantID, participantDomain, date)
    }

    //MARK: - addOrUpdateParticipant

    public var addOrUpdateParticipantUserZMUserWithRoleRoleStringInConversationZMConversationVoidCallsCount = 0
    public var addOrUpdateParticipantUserZMUserWithRoleRoleStringInConversationZMConversationVoidCalled: Bool {
        return addOrUpdateParticipantUserZMUserWithRoleRoleStringInConversationZMConversationVoidCallsCount > 0
    }
    public var addOrUpdateParticipantUserZMUserWithRoleRoleStringInConversationZMConversationVoidReceivedArguments: (user: ZMUser, role: String, conversation: ZMConversation)?
    public var addOrUpdateParticipantUserZMUserWithRoleRoleStringInConversationZMConversationVoidReceivedInvocations: [(user: ZMUser, role: String, conversation: ZMConversation)] = []
    public var addOrUpdateParticipantUserZMUserWithRoleRoleStringInConversationZMConversationVoidClosure: ((ZMUser, String, ZMConversation) async -> Void)?

    public func addOrUpdateParticipant(_ user: ZMUser, withRole role: String, in conversation: ZMConversation) async {
        addOrUpdateParticipantUserZMUserWithRoleRoleStringInConversationZMConversationVoidCallsCount += 1
        addOrUpdateParticipantUserZMUserWithRoleRoleStringInConversationZMConversationVoidReceivedArguments = (user: user, role: role, conversation: conversation)
        addOrUpdateParticipantUserZMUserWithRoleRoleStringInConversationZMConversationVoidReceivedInvocations.append((user: user, role: role, conversation: conversation))
        await addOrUpdateParticipantUserZMUserWithRoleRoleStringInConversationZMConversationVoidClosure?(user, role, conversation)
    }

    //MARK: - addParticipants

    public var addParticipantsParticipantsIdUUIDDomainStringRoleStringAddedBySenderIdUUIDDomainStringAtDateDateDateConversationIdUUIDDomainStringVoidThrowableError: (any Error)?
    public var addParticipantsParticipantsIdUUIDDomainStringRoleStringAddedBySenderIdUUIDDomainStringAtDateDateDateConversationIdUUIDDomainStringVoidCallsCount = 0
    public var addParticipantsParticipantsIdUUIDDomainStringRoleStringAddedBySenderIdUUIDDomainStringAtDateDateDateConversationIdUUIDDomainStringVoidCalled: Bool {
        return addParticipantsParticipantsIdUUIDDomainStringRoleStringAddedBySenderIdUUIDDomainStringAtDateDateDateConversationIdUUIDDomainStringVoidCallsCount > 0
    }
    public var addParticipantsParticipantsIdUUIDDomainStringRoleStringAddedBySenderIdUUIDDomainStringAtDateDateDateConversationIdUUIDDomainStringVoidReceivedArguments: (participants: [(id: UUID, domain: String?, role: String?)], sender: (id: UUID, domain: String?), date: Date, conversation: (id: UUID, domain: String))?
    public var addParticipantsParticipantsIdUUIDDomainStringRoleStringAddedBySenderIdUUIDDomainStringAtDateDateDateConversationIdUUIDDomainStringVoidReceivedInvocations: [(participants: [(id: UUID, domain: String?, role: String?)], sender: (id: UUID, domain: String?), date: Date, conversation: (id: UUID, domain: String))] = []
    public var addParticipantsParticipantsIdUUIDDomainStringRoleStringAddedBySenderIdUUIDDomainStringAtDateDateDateConversationIdUUIDDomainStringVoidClosure: (([(id: UUID, domain: String?, role: String?)], (id: UUID, domain: String?), Date, (id: UUID, domain: String)) async throws -> Void)?

    public func addParticipants(_ participants: [(id: UUID, domain: String?, role: String?)], addedBy sender: (id: UUID, domain: String?), atDate date: Date, conversation: (id: UUID, domain: String)) async throws {
        addParticipantsParticipantsIdUUIDDomainStringRoleStringAddedBySenderIdUUIDDomainStringAtDateDateDateConversationIdUUIDDomainStringVoidCallsCount += 1
        addParticipantsParticipantsIdUUIDDomainStringRoleStringAddedBySenderIdUUIDDomainStringAtDateDateDateConversationIdUUIDDomainStringVoidReceivedArguments = (participants: participants, sender: sender, date: date, conversation: conversation)
        addParticipantsParticipantsIdUUIDDomainStringRoleStringAddedBySenderIdUUIDDomainStringAtDateDateDateConversationIdUUIDDomainStringVoidReceivedInvocations.append((participants: participants, sender: sender, date: date, conversation: conversation))
        if let error = addParticipantsParticipantsIdUUIDDomainStringRoleStringAddedBySenderIdUUIDDomainStringAtDateDateDateConversationIdUUIDDomainStringVoidThrowableError {
            throw error
        }
        try await addParticipantsParticipantsIdUUIDDomainStringRoleStringAddedBySenderIdUUIDDomainStringAtDateDateDateConversationIdUUIDDomainStringVoidClosure?(participants, sender, date, conversation)
    }

    //MARK: - updateMemberStatus

    public var updateMemberStatusMutedStatusInfoStatusIntReferenceDateDateArchivedStatusInfoStatusBoolReferenceDateDateForLocalConversationZMConversationVoidCallsCount = 0
    public var updateMemberStatusMutedStatusInfoStatusIntReferenceDateDateArchivedStatusInfoStatusBoolReferenceDateDateForLocalConversationZMConversationVoidCalled: Bool {
        return updateMemberStatusMutedStatusInfoStatusIntReferenceDateDateArchivedStatusInfoStatusBoolReferenceDateDateForLocalConversationZMConversationVoidCallsCount > 0
    }
    public var updateMemberStatusMutedStatusInfoStatusIntReferenceDateDateArchivedStatusInfoStatusBoolReferenceDateDateForLocalConversationZMConversationVoidReceivedArguments: (mutedStatusInfo: (status: Int?, referenceDate: Date?), archivedStatusInfo: (status: Bool?, referenceDate: Date?), localConversation: ZMConversation)?
    public var updateMemberStatusMutedStatusInfoStatusIntReferenceDateDateArchivedStatusInfoStatusBoolReferenceDateDateForLocalConversationZMConversationVoidReceivedInvocations: [(mutedStatusInfo: (status: Int?, referenceDate: Date?), archivedStatusInfo: (status: Bool?, referenceDate: Date?), localConversation: ZMConversation)] = []
    public var updateMemberStatusMutedStatusInfoStatusIntReferenceDateDateArchivedStatusInfoStatusBoolReferenceDateDateForLocalConversationZMConversationVoidClosure: (((status: Int?, referenceDate: Date?), (status: Bool?, referenceDate: Date?), ZMConversation) async -> Void)?

    public func updateMemberStatus(mutedStatusInfo: (status: Int?, referenceDate: Date?), archivedStatusInfo: (status: Bool?, referenceDate: Date?), for localConversation: ZMConversation) async {
        updateMemberStatusMutedStatusInfoStatusIntReferenceDateDateArchivedStatusInfoStatusBoolReferenceDateDateForLocalConversationZMConversationVoidCallsCount += 1
        updateMemberStatusMutedStatusInfoStatusIntReferenceDateDateArchivedStatusInfoStatusBoolReferenceDateDateForLocalConversationZMConversationVoidReceivedArguments = (mutedStatusInfo: mutedStatusInfo, archivedStatusInfo: archivedStatusInfo, localConversation: localConversation)
        updateMemberStatusMutedStatusInfoStatusIntReferenceDateDateArchivedStatusInfoStatusBoolReferenceDateDateForLocalConversationZMConversationVoidReceivedInvocations.append((mutedStatusInfo: mutedStatusInfo, archivedStatusInfo: archivedStatusInfo, localConversation: localConversation))
        await updateMemberStatusMutedStatusInfoStatusIntReferenceDateDateArchivedStatusInfoStatusBoolReferenceDateDateForLocalConversationZMConversationVoidClosure?(mutedStatusInfo, archivedStatusInfo, localConversation)
    }

    //MARK: - updateAccesses

    public var updateAccessesForConversationZMConversationAccessModesStringAccessRolesStringVoidCallsCount = 0
    public var updateAccessesForConversationZMConversationAccessModesStringAccessRolesStringVoidCalled: Bool {
        return updateAccessesForConversationZMConversationAccessModesStringAccessRolesStringVoidCallsCount > 0
    }
    public var updateAccessesForConversationZMConversationAccessModesStringAccessRolesStringVoidReceivedArguments: (conversation: ZMConversation, accessModes: [String], accessRoles: [String])?
    public var updateAccessesForConversationZMConversationAccessModesStringAccessRolesStringVoidReceivedInvocations: [(conversation: ZMConversation, accessModes: [String], accessRoles: [String])] = []
    public var updateAccessesForConversationZMConversationAccessModesStringAccessRolesStringVoidClosure: ((ZMConversation, [String], [String]) async -> Void)?

    public func updateAccesses(for conversation: ZMConversation, accessModes: [String], accessRoles: [String]) async {
        updateAccessesForConversationZMConversationAccessModesStringAccessRolesStringVoidCallsCount += 1
        updateAccessesForConversationZMConversationAccessModesStringAccessRolesStringVoidReceivedArguments = (conversation: conversation, accessModes: accessModes, accessRoles: accessRoles)
        updateAccessesForConversationZMConversationAccessModesStringAccessRolesStringVoidReceivedInvocations.append((conversation: conversation, accessModes: accessModes, accessRoles: accessRoles))
        await updateAccessesForConversationZMConversationAccessModesStringAccessRolesStringVoidClosure?(conversation, accessModes, accessRoles)
    }

    //MARK: - messageProtocol

    public var messageProtocolForConversationZMConversationWireDataModelMessageProtocolCallsCount = 0
    public var messageProtocolForConversationZMConversationWireDataModelMessageProtocolCalled: Bool {
        return messageProtocolForConversationZMConversationWireDataModelMessageProtocolCallsCount > 0
    }
    public var messageProtocolForConversationZMConversationWireDataModelMessageProtocolReceivedConversation: (ZMConversation)?
    public var messageProtocolForConversationZMConversationWireDataModelMessageProtocolReceivedInvocations: [(ZMConversation)] = []
    public var messageProtocolForConversationZMConversationWireDataModelMessageProtocolReturnValue: WireDataModel.MessageProtocol!
    public var messageProtocolForConversationZMConversationWireDataModelMessageProtocolClosure: ((ZMConversation) async -> WireDataModel.MessageProtocol)?

    public func messageProtocol(for conversation: ZMConversation) async -> WireDataModel.MessageProtocol {
        messageProtocolForConversationZMConversationWireDataModelMessageProtocolCallsCount += 1
        messageProtocolForConversationZMConversationWireDataModelMessageProtocolReceivedConversation = conversation
        messageProtocolForConversationZMConversationWireDataModelMessageProtocolReceivedInvocations.append(conversation)
        if let messageProtocolForConversationZMConversationWireDataModelMessageProtocolClosure = messageProtocolForConversationZMConversationWireDataModelMessageProtocolClosure {
            return await messageProtocolForConversationZMConversationWireDataModelMessageProtocolClosure(conversation)
        } else {
            return messageProtocolForConversationZMConversationWireDataModelMessageProtocolReturnValue
        }
    }

    //MARK: - storeConversation

    public var storeConversationHasReadReceiptsEnabledBoolForConversationZMConversationVoidCallsCount = 0
    public var storeConversationHasReadReceiptsEnabledBoolForConversationZMConversationVoidCalled: Bool {
        return storeConversationHasReadReceiptsEnabledBoolForConversationZMConversationVoidCallsCount > 0
    }
    public var storeConversationHasReadReceiptsEnabledBoolForConversationZMConversationVoidReceivedArguments: (hasReadReceiptsEnabled: Bool, conversation: ZMConversation)?
    public var storeConversationHasReadReceiptsEnabledBoolForConversationZMConversationVoidReceivedInvocations: [(hasReadReceiptsEnabled: Bool, conversation: ZMConversation)] = []
    public var storeConversationHasReadReceiptsEnabledBoolForConversationZMConversationVoidClosure: ((Bool, ZMConversation) async -> Void)?

    public func storeConversation(hasReadReceiptsEnabled: Bool, for conversation: ZMConversation) async {
        storeConversationHasReadReceiptsEnabledBoolForConversationZMConversationVoidCallsCount += 1
        storeConversationHasReadReceiptsEnabledBoolForConversationZMConversationVoidReceivedArguments = (hasReadReceiptsEnabled: hasReadReceiptsEnabled, conversation: conversation)
        storeConversationHasReadReceiptsEnabledBoolForConversationZMConversationVoidReceivedInvocations.append((hasReadReceiptsEnabled: hasReadReceiptsEnabled, conversation: conversation))
        await storeConversationHasReadReceiptsEnabledBoolForConversationZMConversationVoidClosure?(hasReadReceiptsEnabled, conversation)
    }

    //MARK: - isConversationForcedReadOnly

    public var isConversationForcedReadOnlyConversationZMConversationBoolCallsCount = 0
    public var isConversationForcedReadOnlyConversationZMConversationBoolCalled: Bool {
        return isConversationForcedReadOnlyConversationZMConversationBoolCallsCount > 0
    }
    public var isConversationForcedReadOnlyConversationZMConversationBoolReceivedConversation: (ZMConversation)?
    public var isConversationForcedReadOnlyConversationZMConversationBoolReceivedInvocations: [(ZMConversation)] = []
    public var isConversationForcedReadOnlyConversationZMConversationBoolReturnValue: Bool!
    public var isConversationForcedReadOnlyConversationZMConversationBoolClosure: ((ZMConversation) async -> Bool)?

    public func isConversationForcedReadOnly(_ conversation: ZMConversation) async -> Bool {
        isConversationForcedReadOnlyConversationZMConversationBoolCallsCount += 1
        isConversationForcedReadOnlyConversationZMConversationBoolReceivedConversation = conversation
        isConversationForcedReadOnlyConversationZMConversationBoolReceivedInvocations.append(conversation)
        if let isConversationForcedReadOnlyConversationZMConversationBoolClosure = isConversationForcedReadOnlyConversationZMConversationBoolClosure {
            return await isConversationForcedReadOnlyConversationZMConversationBoolClosure(conversation)
        } else {
            return isConversationForcedReadOnlyConversationZMConversationBoolReturnValue
        }
    }

    //MARK: - removeParticipantsAndUpdateConversationState

    public var removeParticipantsAndUpdateConversationStateConversationZMConversationUsersSetZMUserInitiatingUserZMUserVoidCallsCount = 0
    public var removeParticipantsAndUpdateConversationStateConversationZMConversationUsersSetZMUserInitiatingUserZMUserVoidCalled: Bool {
        return removeParticipantsAndUpdateConversationStateConversationZMConversationUsersSetZMUserInitiatingUserZMUserVoidCallsCount > 0
    }
    public var removeParticipantsAndUpdateConversationStateConversationZMConversationUsersSetZMUserInitiatingUserZMUserVoidReceivedArguments: (conversation: ZMConversation, users: Set<ZMUser>, initiatingUser: ZMUser)?
    public var removeParticipantsAndUpdateConversationStateConversationZMConversationUsersSetZMUserInitiatingUserZMUserVoidReceivedInvocations: [(conversation: ZMConversation, users: Set<ZMUser>, initiatingUser: ZMUser)] = []
    public var removeParticipantsAndUpdateConversationStateConversationZMConversationUsersSetZMUserInitiatingUserZMUserVoidClosure: ((ZMConversation, Set<ZMUser>, ZMUser) async -> Void)?

    public func removeParticipantsAndUpdateConversationState(conversation: ZMConversation, users: Set<ZMUser>, initiatingUser: ZMUser) async {
        removeParticipantsAndUpdateConversationStateConversationZMConversationUsersSetZMUserInitiatingUserZMUserVoidCallsCount += 1
        removeParticipantsAndUpdateConversationStateConversationZMConversationUsersSetZMUserInitiatingUserZMUserVoidReceivedArguments = (conversation: conversation, users: users, initiatingUser: initiatingUser)
        removeParticipantsAndUpdateConversationStateConversationZMConversationUsersSetZMUserInitiatingUserZMUserVoidReceivedInvocations.append((conversation: conversation, users: users, initiatingUser: initiatingUser))
        await removeParticipantsAndUpdateConversationStateConversationZMConversationUsersSetZMUserInitiatingUserZMUserVoidClosure?(conversation, users, initiatingUser)
    }

    //MARK: - conversationMessageDestructionTimeout

    public var conversationMessageDestructionTimeoutConversationZMConversationMessageDestructionTimeoutValueCallsCount = 0
    public var conversationMessageDestructionTimeoutConversationZMConversationMessageDestructionTimeoutValueCalled: Bool {
        return conversationMessageDestructionTimeoutConversationZMConversationMessageDestructionTimeoutValueCallsCount > 0
    }
    public var conversationMessageDestructionTimeoutConversationZMConversationMessageDestructionTimeoutValueReceivedConversation: (ZMConversation)?
    public var conversationMessageDestructionTimeoutConversationZMConversationMessageDestructionTimeoutValueReceivedInvocations: [(ZMConversation)] = []
    public var conversationMessageDestructionTimeoutConversationZMConversationMessageDestructionTimeoutValueReturnValue: MessageDestructionTimeoutValue!
    public var conversationMessageDestructionTimeoutConversationZMConversationMessageDestructionTimeoutValueClosure: ((ZMConversation) async -> MessageDestructionTimeoutValue)?

    public func conversationMessageDestructionTimeout(_ conversation: ZMConversation) async -> MessageDestructionTimeoutValue {
        conversationMessageDestructionTimeoutConversationZMConversationMessageDestructionTimeoutValueCallsCount += 1
        conversationMessageDestructionTimeoutConversationZMConversationMessageDestructionTimeoutValueReceivedConversation = conversation
        conversationMessageDestructionTimeoutConversationZMConversationMessageDestructionTimeoutValueReceivedInvocations.append(conversation)
        if let conversationMessageDestructionTimeoutConversationZMConversationMessageDestructionTimeoutValueClosure = conversationMessageDestructionTimeoutConversationZMConversationMessageDestructionTimeoutValueClosure {
            return await conversationMessageDestructionTimeoutConversationZMConversationMessageDestructionTimeoutValueClosure(conversation)
        } else {
            return conversationMessageDestructionTimeoutConversationZMConversationMessageDestructionTimeoutValueReturnValue
        }
    }

    //MARK: - storeConversation

    public var storeConversationTimeoutValueDoubleForConversationZMConversationVoidCallsCount = 0
    public var storeConversationTimeoutValueDoubleForConversationZMConversationVoidCalled: Bool {
        return storeConversationTimeoutValueDoubleForConversationZMConversationVoidCallsCount > 0
    }
    public var storeConversationTimeoutValueDoubleForConversationZMConversationVoidReceivedArguments: (timeoutValue: Double, conversation: ZMConversation)?
    public var storeConversationTimeoutValueDoubleForConversationZMConversationVoidReceivedInvocations: [(timeoutValue: Double, conversation: ZMConversation)] = []
    public var storeConversationTimeoutValueDoubleForConversationZMConversationVoidClosure: ((Double, ZMConversation) async -> Void)?

    public func storeConversation(timeoutValue: Double, for conversation: ZMConversation) async {
        storeConversationTimeoutValueDoubleForConversationZMConversationVoidCallsCount += 1
        storeConversationTimeoutValueDoubleForConversationZMConversationVoidReceivedArguments = (timeoutValue: timeoutValue, conversation: conversation)
        storeConversationTimeoutValueDoubleForConversationZMConversationVoidReceivedInvocations.append((timeoutValue: timeoutValue, conversation: conversation))
        await storeConversationTimeoutValueDoubleForConversationZMConversationVoidClosure?(timeoutValue, conversation)
    }

    //MARK: - fetchOrCreateRole

    public var fetchOrCreateRoleRoleStringInConversationZMConversationRoleCallsCount = 0
    public var fetchOrCreateRoleRoleStringInConversationZMConversationRoleCalled: Bool {
        return fetchOrCreateRoleRoleStringInConversationZMConversationRoleCallsCount > 0
    }
    public var fetchOrCreateRoleRoleStringInConversationZMConversationRoleReceivedArguments: (role: String, conversation: ZMConversation)?
    public var fetchOrCreateRoleRoleStringInConversationZMConversationRoleReceivedInvocations: [(role: String, conversation: ZMConversation)] = []
    public var fetchOrCreateRoleRoleStringInConversationZMConversationRoleReturnValue: Role!
    public var fetchOrCreateRoleRoleStringInConversationZMConversationRoleClosure: ((String, ZMConversation) async -> Role)?

    public func fetchOrCreateRole(_ role: String, in conversation: ZMConversation) async -> Role {
        fetchOrCreateRoleRoleStringInConversationZMConversationRoleCallsCount += 1
        fetchOrCreateRoleRoleStringInConversationZMConversationRoleReceivedArguments = (role: role, conversation: conversation)
        fetchOrCreateRoleRoleStringInConversationZMConversationRoleReceivedInvocations.append((role: role, conversation: conversation))
        if let fetchOrCreateRoleRoleStringInConversationZMConversationRoleClosure = fetchOrCreateRoleRoleStringInConversationZMConversationRoleClosure {
            return await fetchOrCreateRoleRoleStringInConversationZMConversationRoleClosure(role, conversation)
        } else {
            return fetchOrCreateRoleRoleStringInConversationZMConversationRoleReturnValue
        }
    }

    //MARK: - localParticipants

    public var localParticipantsInConversationZMConversationSetZMUserCallsCount = 0
    public var localParticipantsInConversationZMConversationSetZMUserCalled: Bool {
        return localParticipantsInConversationZMConversationSetZMUserCallsCount > 0
    }
    public var localParticipantsInConversationZMConversationSetZMUserReceivedConversation: (ZMConversation)?
    public var localParticipantsInConversationZMConversationSetZMUserReceivedInvocations: [(ZMConversation)] = []
    public var localParticipantsInConversationZMConversationSetZMUserReturnValue: Set<ZMUser>!
    public var localParticipantsInConversationZMConversationSetZMUserClosure: ((ZMConversation) async -> Set<ZMUser>)?

    public func localParticipants(in conversation: ZMConversation) async -> Set<ZMUser> {
        localParticipantsInConversationZMConversationSetZMUserCallsCount += 1
        localParticipantsInConversationZMConversationSetZMUserReceivedConversation = conversation
        localParticipantsInConversationZMConversationSetZMUserReceivedInvocations.append(conversation)
        if let localParticipantsInConversationZMConversationSetZMUserClosure = localParticipantsInConversationZMConversationSetZMUserClosure {
            return await localParticipantsInConversationZMConversationSetZMUserClosure(conversation)
        } else {
            return localParticipantsInConversationZMConversationSetZMUserReturnValue
        }
    }

    //MARK: - isGroupConversation

    public var isGroupConversationConversationZMConversationBoolCallsCount = 0
    public var isGroupConversationConversationZMConversationBoolCalled: Bool {
        return isGroupConversationConversationZMConversationBoolCallsCount > 0
    }
    public var isGroupConversationConversationZMConversationBoolReceivedConversation: (ZMConversation)?
    public var isGroupConversationConversationZMConversationBoolReceivedInvocations: [(ZMConversation)] = []
    public var isGroupConversationConversationZMConversationBoolReturnValue: Bool!
    public var isGroupConversationConversationZMConversationBoolClosure: ((ZMConversation) async -> Bool)?

    public func isGroupConversation(_ conversation: ZMConversation) async -> Bool {
        isGroupConversationConversationZMConversationBoolCallsCount += 1
        isGroupConversationConversationZMConversationBoolReceivedConversation = conversation
        isGroupConversationConversationZMConversationBoolReceivedInvocations.append(conversation)
        if let isGroupConversationConversationZMConversationBoolClosure = isGroupConversationConversationZMConversationBoolClosure {
            return await isGroupConversationConversationZMConversationBoolClosure(conversation)
        } else {
            return isGroupConversationConversationZMConversationBoolReturnValue
        }
    }

    //MARK: - deleteConversation

    public var deleteConversationConversationZMConversationVoidCallsCount = 0
    public var deleteConversationConversationZMConversationVoidCalled: Bool {
        return deleteConversationConversationZMConversationVoidCallsCount > 0
    }
    public var deleteConversationConversationZMConversationVoidReceivedConversation: (ZMConversation)?
    public var deleteConversationConversationZMConversationVoidReceivedInvocations: [(ZMConversation)] = []
    public var deleteConversationConversationZMConversationVoidClosure: ((ZMConversation) async -> Void)?

    public func deleteConversation(_ conversation: ZMConversation) async {
        deleteConversationConversationZMConversationVoidCallsCount += 1
        deleteConversationConversationZMConversationVoidReceivedConversation = conversation
        deleteConversationConversationZMConversationVoidReceivedInvocations.append(conversation)
        await deleteConversationConversationZMConversationVoidClosure?(conversation)
    }

    //MARK: - storeConversation

    public var storeConversationIsDeletedRemotelyBoolConversationZMConversationVoidCallsCount = 0
    public var storeConversationIsDeletedRemotelyBoolConversationZMConversationVoidCalled: Bool {
        return storeConversationIsDeletedRemotelyBoolConversationZMConversationVoidCallsCount > 0
    }
    public var storeConversationIsDeletedRemotelyBoolConversationZMConversationVoidReceivedArguments: (isDeletedRemotely: Bool, conversation: ZMConversation)?
    public var storeConversationIsDeletedRemotelyBoolConversationZMConversationVoidReceivedInvocations: [(isDeletedRemotely: Bool, conversation: ZMConversation)] = []
    public var storeConversationIsDeletedRemotelyBoolConversationZMConversationVoidClosure: ((Bool, ZMConversation) async -> Void)?

    public func storeConversation(isDeletedRemotely: Bool, conversation: ZMConversation) async {
        storeConversationIsDeletedRemotelyBoolConversationZMConversationVoidCallsCount += 1
        storeConversationIsDeletedRemotelyBoolConversationZMConversationVoidReceivedArguments = (isDeletedRemotely: isDeletedRemotely, conversation: conversation)
        storeConversationIsDeletedRemotelyBoolConversationZMConversationVoidReceivedInvocations.append((isDeletedRemotely: isDeletedRemotely, conversation: conversation))
        await storeConversationIsDeletedRemotelyBoolConversationZMConversationVoidClosure?(isDeletedRemotely, conversation)
    }

    //MARK: - mlsConversationInfo

    public var mlsConversationInfoConversationZMConversation_MlsGroupIDMLSGroupIDIsMLSReadyBoolCallsCount = 0
    public var mlsConversationInfoConversationZMConversation_MlsGroupIDMLSGroupIDIsMLSReadyBoolCalled: Bool {
        return mlsConversationInfoConversationZMConversation_MlsGroupIDMLSGroupIDIsMLSReadyBoolCallsCount > 0
    }
    public var mlsConversationInfoConversationZMConversation_MlsGroupIDMLSGroupIDIsMLSReadyBoolReceivedConversation: (ZMConversation)?
    public var mlsConversationInfoConversationZMConversation_MlsGroupIDMLSGroupIDIsMLSReadyBoolReceivedInvocations: [(ZMConversation)] = []
    public var mlsConversationInfoConversationZMConversation_MlsGroupIDMLSGroupIDIsMLSReadyBoolReturnValue: (mlsGroupID: MLSGroupID, isMLSReady: Bool)?
    public var mlsConversationInfoConversationZMConversation_MlsGroupIDMLSGroupIDIsMLSReadyBoolClosure: ((ZMConversation) async -> (mlsGroupID: MLSGroupID, isMLSReady: Bool)?)?

    public func mlsConversationInfo(conversation: ZMConversation) async -> (mlsGroupID: MLSGroupID, isMLSReady: Bool)? {
        mlsConversationInfoConversationZMConversation_MlsGroupIDMLSGroupIDIsMLSReadyBoolCallsCount += 1
        mlsConversationInfoConversationZMConversation_MlsGroupIDMLSGroupIDIsMLSReadyBoolReceivedConversation = conversation
        mlsConversationInfoConversationZMConversation_MlsGroupIDMLSGroupIDIsMLSReadyBoolReceivedInvocations.append(conversation)
        if let mlsConversationInfoConversationZMConversation_MlsGroupIDMLSGroupIDIsMLSReadyBoolClosure = mlsConversationInfoConversationZMConversation_MlsGroupIDMLSGroupIDIsMLSReadyBoolClosure {
            return await mlsConversationInfoConversationZMConversation_MlsGroupIDMLSGroupIDIsMLSReadyBoolClosure(conversation)
        } else {
            return mlsConversationInfoConversationZMConversation_MlsGroupIDMLSGroupIDIsMLSReadyBoolReturnValue
        }
    }

    //MARK: - updateCommitPendingProposal

    public var updateCommitPendingProposalDateDateForConversationZMConversationCommitDelayUInt64VoidCallsCount = 0
    public var updateCommitPendingProposalDateDateForConversationZMConversationCommitDelayUInt64VoidCalled: Bool {
        return updateCommitPendingProposalDateDateForConversationZMConversationCommitDelayUInt64VoidCallsCount > 0
    }
    public var updateCommitPendingProposalDateDateForConversationZMConversationCommitDelayUInt64VoidReceivedArguments: (date: Date, conversation: ZMConversation, commitDelay: UInt64)?
    public var updateCommitPendingProposalDateDateForConversationZMConversationCommitDelayUInt64VoidReceivedInvocations: [(date: Date, conversation: ZMConversation, commitDelay: UInt64)] = []
    public var updateCommitPendingProposalDateDateForConversationZMConversationCommitDelayUInt64VoidClosure: ((Date, ZMConversation, UInt64) async -> Void)?

    public func updateCommitPendingProposal(date: Date, for conversation: ZMConversation, commitDelay: UInt64) async {
        updateCommitPendingProposalDateDateForConversationZMConversationCommitDelayUInt64VoidCallsCount += 1
        updateCommitPendingProposalDateDateForConversationZMConversationCommitDelayUInt64VoidReceivedArguments = (date: date, conversation: conversation, commitDelay: commitDelay)
        updateCommitPendingProposalDateDateForConversationZMConversationCommitDelayUInt64VoidReceivedInvocations.append((date: date, conversation: conversation, commitDelay: commitDelay))
        await updateCommitPendingProposalDateDateForConversationZMConversationCommitDelayUInt64VoidClosure?(date, conversation, commitDelay)
    }

    //MARK: - updateSecurityLevelAfterReceivingMessage

    public var updateSecurityLevelAfterReceivingMessageConversationZMConversationGenericMessageGenericMessageDateDateVoidCallsCount = 0
    public var updateSecurityLevelAfterReceivingMessageConversationZMConversationGenericMessageGenericMessageDateDateVoidCalled: Bool {
        return updateSecurityLevelAfterReceivingMessageConversationZMConversationGenericMessageGenericMessageDateDateVoidCallsCount > 0
    }
    public var updateSecurityLevelAfterReceivingMessageConversationZMConversationGenericMessageGenericMessageDateDateVoidReceivedArguments: (conversation: ZMConversation, genericMessage: GenericMessage, date: Date)?
    public var updateSecurityLevelAfterReceivingMessageConversationZMConversationGenericMessageGenericMessageDateDateVoidReceivedInvocations: [(conversation: ZMConversation, genericMessage: GenericMessage, date: Date)] = []
    public var updateSecurityLevelAfterReceivingMessageConversationZMConversationGenericMessageGenericMessageDateDateVoidClosure: ((ZMConversation, GenericMessage, Date) async -> Void)?

    public func updateSecurityLevelAfterReceivingMessage(conversation: ZMConversation, genericMessage: GenericMessage, date: Date) async {
        updateSecurityLevelAfterReceivingMessageConversationZMConversationGenericMessageGenericMessageDateDateVoidCallsCount += 1
        updateSecurityLevelAfterReceivingMessageConversationZMConversationGenericMessageGenericMessageDateDateVoidReceivedArguments = (conversation: conversation, genericMessage: genericMessage, date: date)
        updateSecurityLevelAfterReceivingMessageConversationZMConversationGenericMessageGenericMessageDateDateVoidReceivedInvocations.append((conversation: conversation, genericMessage: genericMessage, date: date))
        await updateSecurityLevelAfterReceivingMessageConversationZMConversationGenericMessageGenericMessageDateDateVoidClosure?(conversation, genericMessage, date)
    }

    //MARK: - addParticipantIfNeeded

    public var addParticipantIfNeededParticipantIDUUIDParticipantDomainStringInConversationZMConversationDateDateVoidCallsCount = 0
    public var addParticipantIfNeededParticipantIDUUIDParticipantDomainStringInConversationZMConversationDateDateVoidCalled: Bool {
        return addParticipantIfNeededParticipantIDUUIDParticipantDomainStringInConversationZMConversationDateDateVoidCallsCount > 0
    }
    public var addParticipantIfNeededParticipantIDUUIDParticipantDomainStringInConversationZMConversationDateDateVoidReceivedArguments: (participantID: UUID, participantDomain: String?, conversation: ZMConversation, date: Date)?
    public var addParticipantIfNeededParticipantIDUUIDParticipantDomainStringInConversationZMConversationDateDateVoidReceivedInvocations: [(participantID: UUID, participantDomain: String?, conversation: ZMConversation, date: Date)] = []
    public var addParticipantIfNeededParticipantIDUUIDParticipantDomainStringInConversationZMConversationDateDateVoidClosure: ((UUID, String?, ZMConversation, Date) async -> Void)?

    public func addParticipantIfNeeded(participantID: UUID, participantDomain: String?, in conversation: ZMConversation, date: Date) async {
        addParticipantIfNeededParticipantIDUUIDParticipantDomainStringInConversationZMConversationDateDateVoidCallsCount += 1
        addParticipantIfNeededParticipantIDUUIDParticipantDomainStringInConversationZMConversationDateDateVoidReceivedArguments = (participantID: participantID, participantDomain: participantDomain, conversation: conversation, date: date)
        addParticipantIfNeededParticipantIDUUIDParticipantDomainStringInConversationZMConversationDateDateVoidReceivedInvocations.append((participantID: participantID, participantDomain: participantDomain, conversation: conversation, date: date))
        await addParticipantIfNeededParticipantIDUUIDParticipantDomainStringInConversationZMConversationDateDateVoidClosure?(participantID, participantDomain, conversation, date)
    }

    //MARK: - updateLastReadMessageTimestamp

    public var updateLastReadMessageTimestampLastReadMessageLastReadInConversationZMConversationVoidCallsCount = 0
    public var updateLastReadMessageTimestampLastReadMessageLastReadInConversationZMConversationVoidCalled: Bool {
        return updateLastReadMessageTimestampLastReadMessageLastReadInConversationZMConversationVoidCallsCount > 0
    }
    public var updateLastReadMessageTimestampLastReadMessageLastReadInConversationZMConversationVoidReceivedArguments: (lastReadMessage: LastRead, conversation: ZMConversation)?
    public var updateLastReadMessageTimestampLastReadMessageLastReadInConversationZMConversationVoidReceivedInvocations: [(lastReadMessage: LastRead, conversation: ZMConversation)] = []
    public var updateLastReadMessageTimestampLastReadMessageLastReadInConversationZMConversationVoidClosure: ((LastRead, ZMConversation) async -> Void)?

    public func updateLastReadMessageTimestamp(_ lastReadMessage: LastRead, in conversation: ZMConversation) async {
        updateLastReadMessageTimestampLastReadMessageLastReadInConversationZMConversationVoidCallsCount += 1
        updateLastReadMessageTimestampLastReadMessageLastReadInConversationZMConversationVoidReceivedArguments = (lastReadMessage: lastReadMessage, conversation: conversation)
        updateLastReadMessageTimestampLastReadMessageLastReadInConversationZMConversationVoidReceivedInvocations.append((lastReadMessage: lastReadMessage, conversation: conversation))
        await updateLastReadMessageTimestampLastReadMessageLastReadInConversationZMConversationVoidClosure?(lastReadMessage, conversation)
    }

    //MARK: - updateClearedMessageTimestamp

    public var updateClearedMessageTimestampClearedMessageClearedInConversationZMConversationVoidCallsCount = 0
    public var updateClearedMessageTimestampClearedMessageClearedInConversationZMConversationVoidCalled: Bool {
        return updateClearedMessageTimestampClearedMessageClearedInConversationZMConversationVoidCallsCount > 0
    }
    public var updateClearedMessageTimestampClearedMessageClearedInConversationZMConversationVoidReceivedArguments: (clearedMessage: Cleared, conversation: ZMConversation)?
    public var updateClearedMessageTimestampClearedMessageClearedInConversationZMConversationVoidReceivedInvocations: [(clearedMessage: Cleared, conversation: ZMConversation)] = []
    public var updateClearedMessageTimestampClearedMessageClearedInConversationZMConversationVoidClosure: ((Cleared, ZMConversation) async -> Void)?

    public func updateClearedMessageTimestamp(_ clearedMessage: Cleared, in conversation: ZMConversation) async {
        updateClearedMessageTimestampClearedMessageClearedInConversationZMConversationVoidCallsCount += 1
        updateClearedMessageTimestampClearedMessageClearedInConversationZMConversationVoidReceivedArguments = (clearedMessage: clearedMessage, conversation: conversation)
        updateClearedMessageTimestampClearedMessageClearedInConversationZMConversationVoidReceivedInvocations.append((clearedMessage: clearedMessage, conversation: conversation))
        await updateClearedMessageTimestampClearedMessageClearedInConversationZMConversationVoidClosure?(clearedMessage, conversation)
    }

    //MARK: - obtainPermanentIDs

    public var obtainPermanentIDsUserZMUserConversationZMConversationVoidCallsCount = 0
    public var obtainPermanentIDsUserZMUserConversationZMConversationVoidCalled: Bool {
        return obtainPermanentIDsUserZMUserConversationZMConversationVoidCallsCount > 0
    }
    public var obtainPermanentIDsUserZMUserConversationZMConversationVoidReceivedArguments: (user: ZMUser, conversation: ZMConversation)?
    public var obtainPermanentIDsUserZMUserConversationZMConversationVoidReceivedInvocations: [(user: ZMUser, conversation: ZMConversation)] = []
    public var obtainPermanentIDsUserZMUserConversationZMConversationVoidClosure: ((ZMUser, ZMConversation) async -> Void)?

    public func obtainPermanentIDs(user: ZMUser, conversation: ZMConversation) async {
        obtainPermanentIDsUserZMUserConversationZMConversationVoidCallsCount += 1
        obtainPermanentIDsUserZMUserConversationZMConversationVoidReceivedArguments = (user: user, conversation: conversation)
        obtainPermanentIDsUserZMUserConversationZMConversationVoidReceivedInvocations.append((user: user, conversation: conversation))
        await obtainPermanentIDsUserZMUserConversationZMConversationVoidClosure?(user, conversation)
    }

    //MARK: - conversationName

    public var conversationNameConversationZMConversationStringCallsCount = 0
    public var conversationNameConversationZMConversationStringCalled: Bool {
        return conversationNameConversationZMConversationStringCallsCount > 0
    }
    public var conversationNameConversationZMConversationStringReceivedConversation: (ZMConversation)?
    public var conversationNameConversationZMConversationStringReceivedInvocations: [(ZMConversation)] = []
    public var conversationNameConversationZMConversationStringReturnValue: String?
    public var conversationNameConversationZMConversationStringClosure: ((ZMConversation) async -> String?)?

    public func conversationName(conversation: ZMConversation) async -> String? {
        conversationNameConversationZMConversationStringCallsCount += 1
        conversationNameConversationZMConversationStringReceivedConversation = conversation
        conversationNameConversationZMConversationStringReceivedInvocations.append(conversation)
        if let conversationNameConversationZMConversationStringClosure = conversationNameConversationZMConversationStringClosure {
            return await conversationNameConversationZMConversationStringClosure(conversation)
        } else {
            return conversationNameConversationZMConversationStringReturnValue
        }
    }

    //MARK: - storeConversation

    public var storeConversationNewNameStringConversationZMConversationVoidCallsCount = 0
    public var storeConversationNewNameStringConversationZMConversationVoidCalled: Bool {
        return storeConversationNewNameStringConversationZMConversationVoidCallsCount > 0
    }
    public var storeConversationNewNameStringConversationZMConversationVoidReceivedArguments: (newName: String, conversation: ZMConversation)?
    public var storeConversationNewNameStringConversationZMConversationVoidReceivedInvocations: [(newName: String, conversation: ZMConversation)] = []
    public var storeConversationNewNameStringConversationZMConversationVoidClosure: ((String, ZMConversation) async -> Void)?

    public func storeConversation(newName: String, conversation: ZMConversation) async {
        storeConversationNewNameStringConversationZMConversationVoidCallsCount += 1
        storeConversationNewNameStringConversationZMConversationVoidReceivedArguments = (newName: newName, conversation: conversation)
        storeConversationNewNameStringConversationZMConversationVoidReceivedInvocations.append((newName: newName, conversation: conversation))
        await storeConversationNewNameStringConversationZMConversationVoidClosure?(newName, conversation)
    }

    //MARK: - updateOrCreateMLSGroup

    public var updateOrCreateMLSGroupGroupIDMLSGroupIDVoidCallsCount = 0
    public var updateOrCreateMLSGroupGroupIDMLSGroupIDVoidCalled: Bool {
        return updateOrCreateMLSGroupGroupIDMLSGroupIDVoidCallsCount > 0
    }
    public var updateOrCreateMLSGroupGroupIDMLSGroupIDVoidReceivedGroupID: (MLSGroupID)?
    public var updateOrCreateMLSGroupGroupIDMLSGroupIDVoidReceivedInvocations: [(MLSGroupID)] = []
    public var updateOrCreateMLSGroupGroupIDMLSGroupIDVoidClosure: ((MLSGroupID) async -> Void)?

    public func updateOrCreateMLSGroup(groupID: MLSGroupID) async {
        updateOrCreateMLSGroupGroupIDMLSGroupIDVoidCallsCount += 1
        updateOrCreateMLSGroupGroupIDMLSGroupIDVoidReceivedGroupID = groupID
        updateOrCreateMLSGroupGroupIDMLSGroupIDVoidReceivedInvocations.append(groupID)
        await updateOrCreateMLSGroupGroupIDMLSGroupIDVoidClosure?(groupID)
    }

    //MARK: - storeMLSConversationEstablished

    public var storeMLSConversationEstablishedMlsGroupIDMLSGroupIDConversationZMConversationVoidCallsCount = 0
    public var storeMLSConversationEstablishedMlsGroupIDMLSGroupIDConversationZMConversationVoidCalled: Bool {
        return storeMLSConversationEstablishedMlsGroupIDMLSGroupIDConversationZMConversationVoidCallsCount > 0
    }
    public var storeMLSConversationEstablishedMlsGroupIDMLSGroupIDConversationZMConversationVoidReceivedArguments: (mlsGroupID: MLSGroupID, conversation: ZMConversation)?
    public var storeMLSConversationEstablishedMlsGroupIDMLSGroupIDConversationZMConversationVoidReceivedInvocations: [(mlsGroupID: MLSGroupID, conversation: ZMConversation)] = []
    public var storeMLSConversationEstablishedMlsGroupIDMLSGroupIDConversationZMConversationVoidClosure: ((MLSGroupID, ZMConversation) async -> Void)?

    public func storeMLSConversationEstablished(mlsGroupID: MLSGroupID, conversation: ZMConversation) async {
        storeMLSConversationEstablishedMlsGroupIDMLSGroupIDConversationZMConversationVoidCallsCount += 1
        storeMLSConversationEstablishedMlsGroupIDMLSGroupIDConversationZMConversationVoidReceivedArguments = (mlsGroupID: mlsGroupID, conversation: conversation)
        storeMLSConversationEstablishedMlsGroupIDMLSGroupIDConversationZMConversationVoidReceivedInvocations.append((mlsGroupID: mlsGroupID, conversation: conversation))
        await storeMLSConversationEstablishedMlsGroupIDMLSGroupIDConversationZMConversationVoidClosure?(mlsGroupID, conversation)
    }

    //MARK: - storeMLSConversationPendingJoin

    public var storeMLSConversationPendingJoinNewMLSGroupIDMLSGroupIDConversationZMConversationVoidCallsCount = 0
    public var storeMLSConversationPendingJoinNewMLSGroupIDMLSGroupIDConversationZMConversationVoidCalled: Bool {
        return storeMLSConversationPendingJoinNewMLSGroupIDMLSGroupIDConversationZMConversationVoidCallsCount > 0
    }
    public var storeMLSConversationPendingJoinNewMLSGroupIDMLSGroupIDConversationZMConversationVoidReceivedArguments: (newMLSGroupID: MLSGroupID, conversation: ZMConversation)?
    public var storeMLSConversationPendingJoinNewMLSGroupIDMLSGroupIDConversationZMConversationVoidReceivedInvocations: [(newMLSGroupID: MLSGroupID, conversation: ZMConversation)] = []
    public var storeMLSConversationPendingJoinNewMLSGroupIDMLSGroupIDConversationZMConversationVoidClosure: ((MLSGroupID, ZMConversation) async -> Void)?

    public func storeMLSConversationPendingJoin(newMLSGroupID: MLSGroupID, conversation: ZMConversation) async {
        storeMLSConversationPendingJoinNewMLSGroupIDMLSGroupIDConversationZMConversationVoidCallsCount += 1
        storeMLSConversationPendingJoinNewMLSGroupIDMLSGroupIDConversationZMConversationVoidReceivedArguments = (newMLSGroupID: newMLSGroupID, conversation: conversation)
        storeMLSConversationPendingJoinNewMLSGroupIDMLSGroupIDConversationZMConversationVoidReceivedInvocations.append((newMLSGroupID: newMLSGroupID, conversation: conversation))
        await storeMLSConversationPendingJoinNewMLSGroupIDMLSGroupIDConversationZMConversationVoidClosure?(newMLSGroupID, conversation)
    }

    //MARK: - fetchOtherUserIDInOneOnOneConversation

    public var fetchOtherUserIDInOneOnOneConversationConversationZMConversationWireDataModelQualifiedIDCallsCount = 0
    public var fetchOtherUserIDInOneOnOneConversationConversationZMConversationWireDataModelQualifiedIDCalled: Bool {
        return fetchOtherUserIDInOneOnOneConversationConversationZMConversationWireDataModelQualifiedIDCallsCount > 0
    }
    public var fetchOtherUserIDInOneOnOneConversationConversationZMConversationWireDataModelQualifiedIDReceivedConversation: (ZMConversation)?
    public var fetchOtherUserIDInOneOnOneConversationConversationZMConversationWireDataModelQualifiedIDReceivedInvocations: [(ZMConversation)] = []
    public var fetchOtherUserIDInOneOnOneConversationConversationZMConversationWireDataModelQualifiedIDReturnValue: WireDataModel.QualifiedID?
    public var fetchOtherUserIDInOneOnOneConversationConversationZMConversationWireDataModelQualifiedIDClosure: ((ZMConversation) async -> WireDataModel.QualifiedID?)?

    public func fetchOtherUserIDInOneOnOneConversation(conversation: ZMConversation) async -> WireDataModel.QualifiedID? {
        fetchOtherUserIDInOneOnOneConversationConversationZMConversationWireDataModelQualifiedIDCallsCount += 1
        fetchOtherUserIDInOneOnOneConversationConversationZMConversationWireDataModelQualifiedIDReceivedConversation = conversation
        fetchOtherUserIDInOneOnOneConversationConversationZMConversationWireDataModelQualifiedIDReceivedInvocations.append(conversation)
        if let fetchOtherUserIDInOneOnOneConversationConversationZMConversationWireDataModelQualifiedIDClosure = fetchOtherUserIDInOneOnOneConversationConversationZMConversationWireDataModelQualifiedIDClosure {
            return await fetchOtherUserIDInOneOnOneConversationConversationZMConversationWireDataModelQualifiedIDClosure(conversation)
        } else {
            return fetchOtherUserIDInOneOnOneConversationConversationZMConversationWireDataModelQualifiedIDReturnValue
        }
    }

    //MARK: - name

    public var nameForConversationZMConversationStringCallsCount = 0
    public var nameForConversationZMConversationStringCalled: Bool {
        return nameForConversationZMConversationStringCallsCount > 0
    }
    public var nameForConversationZMConversationStringReceivedConversation: (ZMConversation)?
    public var nameForConversationZMConversationStringReceivedInvocations: [(ZMConversation)] = []
    public var nameForConversationZMConversationStringReturnValue: String?
    public var nameForConversationZMConversationStringClosure: ((ZMConversation) async -> String?)?

    public func name(for conversation: ZMConversation) async -> String? {
        nameForConversationZMConversationStringCallsCount += 1
        nameForConversationZMConversationStringReceivedConversation = conversation
        nameForConversationZMConversationStringReceivedInvocations.append(conversation)
        if let nameForConversationZMConversationStringClosure = nameForConversationZMConversationStringClosure {
            return await nameForConversationZMConversationStringClosure(conversation)
        } else {
            return nameForConversationZMConversationStringReturnValue
        }
    }

    //MARK: - shouldHideNotification

    public var shouldHideNotificationBoolCallsCount = 0
    public var shouldHideNotificationBoolCalled: Bool {
        return shouldHideNotificationBoolCallsCount > 0
    }
    public var shouldHideNotificationBoolReturnValue: Bool!
    public var shouldHideNotificationBoolClosure: (() async -> Bool)?

    public func shouldHideNotification() async -> Bool {
        shouldHideNotificationBoolCallsCount += 1
        if let shouldHideNotificationBoolClosure = shouldHideNotificationBoolClosure {
            return await shouldHideNotificationBoolClosure()
        } else {
            return shouldHideNotificationBoolReturnValue
        }
    }

    //MARK: - isMessageSilenced

    public var isMessageSilencedMessageGenericMessageSenderIDUUIDConversationZMConversationBoolCallsCount = 0
    public var isMessageSilencedMessageGenericMessageSenderIDUUIDConversationZMConversationBoolCalled: Bool {
        return isMessageSilencedMessageGenericMessageSenderIDUUIDConversationZMConversationBoolCallsCount > 0
    }
    public var isMessageSilencedMessageGenericMessageSenderIDUUIDConversationZMConversationBoolReceivedArguments: (message: GenericMessage, senderID: UUID?, conversation: ZMConversation)?
    public var isMessageSilencedMessageGenericMessageSenderIDUUIDConversationZMConversationBoolReceivedInvocations: [(message: GenericMessage, senderID: UUID?, conversation: ZMConversation)] = []
    public var isMessageSilencedMessageGenericMessageSenderIDUUIDConversationZMConversationBoolReturnValue: Bool!
    public var isMessageSilencedMessageGenericMessageSenderIDUUIDConversationZMConversationBoolClosure: ((GenericMessage, UUID?, ZMConversation) async -> Bool)?

    public func isMessageSilenced(_ message: GenericMessage, senderID: UUID?, conversation: ZMConversation) async -> Bool {
        isMessageSilencedMessageGenericMessageSenderIDUUIDConversationZMConversationBoolCallsCount += 1
        isMessageSilencedMessageGenericMessageSenderIDUUIDConversationZMConversationBoolReceivedArguments = (message: message, senderID: senderID, conversation: conversation)
        isMessageSilencedMessageGenericMessageSenderIDUUIDConversationZMConversationBoolReceivedInvocations.append((message: message, senderID: senderID, conversation: conversation))
        if let isMessageSilencedMessageGenericMessageSenderIDUUIDConversationZMConversationBoolClosure = isMessageSilencedMessageGenericMessageSenderIDUUIDConversationZMConversationBoolClosure {
            return await isMessageSilencedMessageGenericMessageSenderIDUUIDConversationZMConversationBoolClosure(message, senderID, conversation)
        } else {
            return isMessageSilencedMessageGenericMessageSenderIDUUIDConversationZMConversationBoolReturnValue
        }
    }

    //MARK: - conversationMutedMessageTypesIncludingAvailability

    public var conversationMutedMessageTypesIncludingAvailabilityConversationZMConversationMutedMessageTypesCallsCount = 0
    public var conversationMutedMessageTypesIncludingAvailabilityConversationZMConversationMutedMessageTypesCalled: Bool {
        return conversationMutedMessageTypesIncludingAvailabilityConversationZMConversationMutedMessageTypesCallsCount > 0
    }
    public var conversationMutedMessageTypesIncludingAvailabilityConversationZMConversationMutedMessageTypesReceivedConversation: (ZMConversation)?
    public var conversationMutedMessageTypesIncludingAvailabilityConversationZMConversationMutedMessageTypesReceivedInvocations: [(ZMConversation)] = []
    public var conversationMutedMessageTypesIncludingAvailabilityConversationZMConversationMutedMessageTypesReturnValue: MutedMessageTypes!
    public var conversationMutedMessageTypesIncludingAvailabilityConversationZMConversationMutedMessageTypesClosure: ((ZMConversation) async -> MutedMessageTypes)?

    public func conversationMutedMessageTypesIncludingAvailability(_ conversation: ZMConversation) async -> MutedMessageTypes {
        conversationMutedMessageTypesIncludingAvailabilityConversationZMConversationMutedMessageTypesCallsCount += 1
        conversationMutedMessageTypesIncludingAvailabilityConversationZMConversationMutedMessageTypesReceivedConversation = conversation
        conversationMutedMessageTypesIncludingAvailabilityConversationZMConversationMutedMessageTypesReceivedInvocations.append(conversation)
        if let conversationMutedMessageTypesIncludingAvailabilityConversationZMConversationMutedMessageTypesClosure = conversationMutedMessageTypesIncludingAvailabilityConversationZMConversationMutedMessageTypesClosure {
            return await conversationMutedMessageTypesIncludingAvailabilityConversationZMConversationMutedMessageTypesClosure(conversation)
        } else {
            return conversationMutedMessageTypesIncludingAvailabilityConversationZMConversationMutedMessageTypesReturnValue
        }
    }

    //MARK: - lastReadServerTimestamp

    public var lastReadServerTimestampConversationZMConversationDateCallsCount = 0
    public var lastReadServerTimestampConversationZMConversationDateCalled: Bool {
        return lastReadServerTimestampConversationZMConversationDateCallsCount > 0
    }
    public var lastReadServerTimestampConversationZMConversationDateReceivedConversation: (ZMConversation)?
    public var lastReadServerTimestampConversationZMConversationDateReceivedInvocations: [(ZMConversation)] = []
    public var lastReadServerTimestampConversationZMConversationDateReturnValue: Date?
    public var lastReadServerTimestampConversationZMConversationDateClosure: ((ZMConversation) async -> Date?)?

    public func lastReadServerTimestamp(_ conversation: ZMConversation) async -> Date? {
        lastReadServerTimestampConversationZMConversationDateCallsCount += 1
        lastReadServerTimestampConversationZMConversationDateReceivedConversation = conversation
        lastReadServerTimestampConversationZMConversationDateReceivedInvocations.append(conversation)
        if let lastReadServerTimestampConversationZMConversationDateClosure = lastReadServerTimestampConversationZMConversationDateClosure {
            return await lastReadServerTimestampConversationZMConversationDateClosure(conversation)
        } else {
            return lastReadServerTimestampConversationZMConversationDateReturnValue
        }
    }

    //MARK: - conversationNeedsBackendUpdate

    public var conversationNeedsBackendUpdateConversationZMConversationBoolCallsCount = 0
    public var conversationNeedsBackendUpdateConversationZMConversationBoolCalled: Bool {
        return conversationNeedsBackendUpdateConversationZMConversationBoolCallsCount > 0
    }
    public var conversationNeedsBackendUpdateConversationZMConversationBoolReceivedConversation: (ZMConversation)?
    public var conversationNeedsBackendUpdateConversationZMConversationBoolReceivedInvocations: [(ZMConversation)] = []
    public var conversationNeedsBackendUpdateConversationZMConversationBoolReturnValue: Bool!
    public var conversationNeedsBackendUpdateConversationZMConversationBoolClosure: ((ZMConversation) async -> Bool)?

    public func conversationNeedsBackendUpdate(_ conversation: ZMConversation) async -> Bool {
        conversationNeedsBackendUpdateConversationZMConversationBoolCallsCount += 1
        conversationNeedsBackendUpdateConversationZMConversationBoolReceivedConversation = conversation
        conversationNeedsBackendUpdateConversationZMConversationBoolReceivedInvocations.append(conversation)
        if let conversationNeedsBackendUpdateConversationZMConversationBoolClosure = conversationNeedsBackendUpdateConversationZMConversationBoolClosure {
            return await conversationNeedsBackendUpdateConversationZMConversationBoolClosure(conversation)
        } else {
            return conversationNeedsBackendUpdateConversationZMConversationBoolReturnValue
        }
    }

    //MARK: - increaseUnreadCount

    public var increaseUnreadCountForConversationZMConversationVoidCallsCount = 0
    public var increaseUnreadCountForConversationZMConversationVoidCalled: Bool {
        return increaseUnreadCountForConversationZMConversationVoidCallsCount > 0
    }
    public var increaseUnreadCountForConversationZMConversationVoidReceivedConversation: (ZMConversation)?
    public var increaseUnreadCountForConversationZMConversationVoidReceivedInvocations: [(ZMConversation)] = []
    public var increaseUnreadCountForConversationZMConversationVoidClosure: ((ZMConversation) async -> Void)?

    public func increaseUnreadCount(for conversation: ZMConversation) async {
        increaseUnreadCountForConversationZMConversationVoidCallsCount += 1
        increaseUnreadCountForConversationZMConversationVoidReceivedConversation = conversation
        increaseUnreadCountForConversationZMConversationVoidReceivedInvocations.append(conversation)
        await increaseUnreadCountForConversationZMConversationVoidClosure?(conversation)
    }

    //MARK: - decreaseUnreadCount

    public var decreaseUnreadCountForConversationZMConversationVoidCallsCount = 0
    public var decreaseUnreadCountForConversationZMConversationVoidCalled: Bool {
        return decreaseUnreadCountForConversationZMConversationVoidCallsCount > 0
    }
    public var decreaseUnreadCountForConversationZMConversationVoidReceivedConversation: (ZMConversation)?
    public var decreaseUnreadCountForConversationZMConversationVoidReceivedInvocations: [(ZMConversation)] = []
    public var decreaseUnreadCountForConversationZMConversationVoidClosure: ((ZMConversation) async -> Void)?

    public func decreaseUnreadCount(for conversation: ZMConversation) async {
        decreaseUnreadCountForConversationZMConversationVoidCallsCount += 1
        decreaseUnreadCountForConversationZMConversationVoidReceivedConversation = conversation
        decreaseUnreadCountForConversationZMConversationVoidReceivedInvocations.append(conversation)
        await decreaseUnreadCountForConversationZMConversationVoidClosure?(conversation)
    }

    //MARK: - increaseUnreadSelfMentionCount

    public var increaseUnreadSelfMentionCountForConversationZMConversationVoidCallsCount = 0
    public var increaseUnreadSelfMentionCountForConversationZMConversationVoidCalled: Bool {
        return increaseUnreadSelfMentionCountForConversationZMConversationVoidCallsCount > 0
    }
    public var increaseUnreadSelfMentionCountForConversationZMConversationVoidReceivedConversation: (ZMConversation)?
    public var increaseUnreadSelfMentionCountForConversationZMConversationVoidReceivedInvocations: [(ZMConversation)] = []
    public var increaseUnreadSelfMentionCountForConversationZMConversationVoidClosure: ((ZMConversation) async -> Void)?

    public func increaseUnreadSelfMentionCount(for conversation: ZMConversation) async {
        increaseUnreadSelfMentionCountForConversationZMConversationVoidCallsCount += 1
        increaseUnreadSelfMentionCountForConversationZMConversationVoidReceivedConversation = conversation
        increaseUnreadSelfMentionCountForConversationZMConversationVoidReceivedInvocations.append(conversation)
        await increaseUnreadSelfMentionCountForConversationZMConversationVoidClosure?(conversation)
    }

    //MARK: - increaseUnreadSelfReplyCount

    public var increaseUnreadSelfReplyCountForConversationZMConversationVoidCallsCount = 0
    public var increaseUnreadSelfReplyCountForConversationZMConversationVoidCalled: Bool {
        return increaseUnreadSelfReplyCountForConversationZMConversationVoidCallsCount > 0
    }
    public var increaseUnreadSelfReplyCountForConversationZMConversationVoidReceivedConversation: (ZMConversation)?
    public var increaseUnreadSelfReplyCountForConversationZMConversationVoidReceivedInvocations: [(ZMConversation)] = []
    public var increaseUnreadSelfReplyCountForConversationZMConversationVoidClosure: ((ZMConversation) async -> Void)?

    public func increaseUnreadSelfReplyCount(for conversation: ZMConversation) async {
        increaseUnreadSelfReplyCountForConversationZMConversationVoidCallsCount += 1
        increaseUnreadSelfReplyCountForConversationZMConversationVoidReceivedConversation = conversation
        increaseUnreadSelfReplyCountForConversationZMConversationVoidReceivedInvocations.append(conversation)
        await increaseUnreadSelfReplyCountForConversationZMConversationVoidClosure?(conversation)
    }

    //MARK: - unreadConversationCount

    public var unreadConversationCountUIntCallsCount = 0
    public var unreadConversationCountUIntCalled: Bool {
        return unreadConversationCountUIntCallsCount > 0
    }
    public var unreadConversationCountUIntReturnValue: UInt!
    public var unreadConversationCountUIntClosure: (() async -> UInt)?

    public func unreadConversationCount() async -> UInt {
        unreadConversationCountUIntCallsCount += 1
        if let unreadConversationCountUIntClosure = unreadConversationCountUIntClosure {
            return await unreadConversationCountUIntClosure()
        } else {
            return unreadConversationCountUIntReturnValue
        }
    }

    //MARK: - storeConversation

    public var storeConversationPermissionWireDomainConversationChannelPermissionConversationZMConversationVoidCallsCount = 0
    public var storeConversationPermissionWireDomainConversationChannelPermissionConversationZMConversationVoidCalled: Bool {
        return storeConversationPermissionWireDomainConversationChannelPermissionConversationZMConversationVoidCallsCount > 0
    }
    public var storeConversationPermissionWireDomainConversationChannelPermissionConversationZMConversationVoidReceivedArguments: (permission: WireDomain.Conversation.ChannelPermission, conversation: ZMConversation)?
    public var storeConversationPermissionWireDomainConversationChannelPermissionConversationZMConversationVoidReceivedInvocations: [(permission: WireDomain.Conversation.ChannelPermission, conversation: ZMConversation)] = []
    public var storeConversationPermissionWireDomainConversationChannelPermissionConversationZMConversationVoidClosure: ((WireDomain.Conversation.ChannelPermission, ZMConversation) async -> Void)?

    public func storeConversation(permission: WireDomain.Conversation.ChannelPermission, conversation: ZMConversation) async {
        storeConversationPermissionWireDomainConversationChannelPermissionConversationZMConversationVoidCallsCount += 1
        storeConversationPermissionWireDomainConversationChannelPermissionConversationZMConversationVoidReceivedArguments = (permission: permission, conversation: conversation)
        storeConversationPermissionWireDomainConversationChannelPermissionConversationZMConversationVoidReceivedInvocations.append((permission: permission, conversation: conversation))
        await storeConversationPermissionWireDomainConversationChannelPermissionConversationZMConversationVoidClosure?(permission, conversation)
    }

    //MARK: - fetchServerTimeDelta

    public var fetchServerTimeDeltaTimeIntervalCallsCount = 0
    public var fetchServerTimeDeltaTimeIntervalCalled: Bool {
        return fetchServerTimeDeltaTimeIntervalCallsCount > 0
    }
    public var fetchServerTimeDeltaTimeIntervalReturnValue: TimeInterval!
    public var fetchServerTimeDeltaTimeIntervalClosure: (() async -> TimeInterval)?

    public func fetchServerTimeDelta() async -> TimeInterval {
        fetchServerTimeDeltaTimeIntervalCallsCount += 1
        if let fetchServerTimeDeltaTimeIntervalClosure = fetchServerTimeDeltaTimeIntervalClosure {
            return await fetchServerTimeDeltaTimeIntervalClosure()
        } else {
            return fetchServerTimeDeltaTimeIntervalReturnValue
        }
    }


}
class ConversationLocationMessageNotificationBuilderProtocolMock: ConversationLocationMessageNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount = 0
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCalled: Bool {
        return buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount > 0
    }
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments: (conversationID: ConversationID, senderID: UserID)?
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations: [(conversationID: ConversationID, senderID: UserID)] = []
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue: UserNotification!
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure: ((ConversationID, UserID) async -> UserNotification)?

    func buildContent(conversationID: ConversationID, senderID: UserID) async -> UserNotification {
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount += 1
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments = (conversationID: conversationID, senderID: senderID)
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations.append((conversationID: conversationID, senderID: senderID))
        if let buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure = buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure {
            return await buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure(conversationID, senderID)
        } else {
            return buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue
        }
    }


}
class ConversationMemberJoinEventNotificationBuilderProtocolMock: ConversationMemberJoinEventNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentEventConversationMemberJoinEventUserNotificationCallsCount = 0
    var buildContentEventConversationMemberJoinEventUserNotificationCalled: Bool {
        return buildContentEventConversationMemberJoinEventUserNotificationCallsCount > 0
    }
    var buildContentEventConversationMemberJoinEventUserNotificationReceivedEvent: (ConversationMemberJoinEvent)?
    var buildContentEventConversationMemberJoinEventUserNotificationReceivedInvocations: [(ConversationMemberJoinEvent)] = []
    var buildContentEventConversationMemberJoinEventUserNotificationReturnValue: UserNotification?
    var buildContentEventConversationMemberJoinEventUserNotificationClosure: ((ConversationMemberJoinEvent) async -> UserNotification?)?

    func buildContent(event: ConversationMemberJoinEvent) async -> UserNotification? {
        buildContentEventConversationMemberJoinEventUserNotificationCallsCount += 1
        buildContentEventConversationMemberJoinEventUserNotificationReceivedEvent = event
        buildContentEventConversationMemberJoinEventUserNotificationReceivedInvocations.append(event)
        if let buildContentEventConversationMemberJoinEventUserNotificationClosure = buildContentEventConversationMemberJoinEventUserNotificationClosure {
            return await buildContentEventConversationMemberJoinEventUserNotificationClosure(event)
        } else {
            return buildContentEventConversationMemberJoinEventUserNotificationReturnValue
        }
    }


}
class ConversationMemberLeaveEventNotificationBuilderProtocolMock: ConversationMemberLeaveEventNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentEventConversationMemberLeaveEventUserNotificationCallsCount = 0
    var buildContentEventConversationMemberLeaveEventUserNotificationCalled: Bool {
        return buildContentEventConversationMemberLeaveEventUserNotificationCallsCount > 0
    }
    var buildContentEventConversationMemberLeaveEventUserNotificationReceivedEvent: (ConversationMemberLeaveEvent)?
    var buildContentEventConversationMemberLeaveEventUserNotificationReceivedInvocations: [(ConversationMemberLeaveEvent)] = []
    var buildContentEventConversationMemberLeaveEventUserNotificationReturnValue: UserNotification?
    var buildContentEventConversationMemberLeaveEventUserNotificationClosure: ((ConversationMemberLeaveEvent) async -> UserNotification?)?

    func buildContent(event: ConversationMemberLeaveEvent) async -> UserNotification? {
        buildContentEventConversationMemberLeaveEventUserNotificationCallsCount += 1
        buildContentEventConversationMemberLeaveEventUserNotificationReceivedEvent = event
        buildContentEventConversationMemberLeaveEventUserNotificationReceivedInvocations.append(event)
        if let buildContentEventConversationMemberLeaveEventUserNotificationClosure = buildContentEventConversationMemberLeaveEventUserNotificationClosure {
            return await buildContentEventConversationMemberLeaveEventUserNotificationClosure(event)
        } else {
            return buildContentEventConversationMemberLeaveEventUserNotificationReturnValue
        }
    }


}
class ConversationMessageTimerUpdateEventNotificationBuilderProtocolMock: ConversationMessageTimerUpdateEventNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentEventConversationMessageTimerUpdateEventUserNotificationCallsCount = 0
    var buildContentEventConversationMessageTimerUpdateEventUserNotificationCalled: Bool {
        return buildContentEventConversationMessageTimerUpdateEventUserNotificationCallsCount > 0
    }
    var buildContentEventConversationMessageTimerUpdateEventUserNotificationReceivedEvent: (ConversationMessageTimerUpdateEvent)?
    var buildContentEventConversationMessageTimerUpdateEventUserNotificationReceivedInvocations: [(ConversationMessageTimerUpdateEvent)] = []
    var buildContentEventConversationMessageTimerUpdateEventUserNotificationReturnValue: UserNotification?
    var buildContentEventConversationMessageTimerUpdateEventUserNotificationClosure: ((ConversationMessageTimerUpdateEvent) async -> UserNotification?)?

    func buildContent(event: ConversationMessageTimerUpdateEvent) async -> UserNotification? {
        buildContentEventConversationMessageTimerUpdateEventUserNotificationCallsCount += 1
        buildContentEventConversationMessageTimerUpdateEventUserNotificationReceivedEvent = event
        buildContentEventConversationMessageTimerUpdateEventUserNotificationReceivedInvocations.append(event)
        if let buildContentEventConversationMessageTimerUpdateEventUserNotificationClosure = buildContentEventConversationMessageTimerUpdateEventUserNotificationClosure {
            return await buildContentEventConversationMessageTimerUpdateEventUserNotificationClosure(event)
        } else {
            return buildContentEventConversationMessageTimerUpdateEventUserNotificationReturnValue
        }
    }


}
class ConversationPingMessageNotificationBuilderProtocolMock: ConversationPingMessageNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount = 0
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCalled: Bool {
        return buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount > 0
    }
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments: (conversationID: ConversationID, senderID: UserID)?
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations: [(conversationID: ConversationID, senderID: UserID)] = []
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue: UserNotification!
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure: ((ConversationID, UserID) async -> UserNotification)?

    func buildContent(conversationID: ConversationID, senderID: UserID) async -> UserNotification {
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount += 1
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments = (conversationID: conversationID, senderID: senderID)
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations.append((conversationID: conversationID, senderID: senderID))
        if let buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure = buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure {
            return await buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure(conversationID, senderID)
        } else {
            return buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue
        }
    }


}
public class ConversationProtobufMessageProcessorProtocolMock: ConversationProtobufMessageProcessorProtocol {

    public init() {}



    //MARK: - processProtobufMessage

    public var processProtobufMessageMessageGenericMessageContentGenericMessageOneOfContentConversationZMConversationConversationIDConversationIDSenderIDUserIDSenderClientIDStringDateDateEventMessageStringVoidThrowableError: (any Error)?
    public var processProtobufMessageMessageGenericMessageContentGenericMessageOneOfContentConversationZMConversationConversationIDConversationIDSenderIDUserIDSenderClientIDStringDateDateEventMessageStringVoidCallsCount = 0
    public var processProtobufMessageMessageGenericMessageContentGenericMessageOneOfContentConversationZMConversationConversationIDConversationIDSenderIDUserIDSenderClientIDStringDateDateEventMessageStringVoidCalled: Bool {
        return processProtobufMessageMessageGenericMessageContentGenericMessageOneOfContentConversationZMConversationConversationIDConversationIDSenderIDUserIDSenderClientIDStringDateDateEventMessageStringVoidCallsCount > 0
    }
    public var processProtobufMessageMessageGenericMessageContentGenericMessageOneOfContentConversationZMConversationConversationIDConversationIDSenderIDUserIDSenderClientIDStringDateDateEventMessageStringVoidReceivedArguments: (message: GenericMessage, content: GenericMessage.OneOf_Content, conversation: ZMConversation, conversationID: ConversationID, senderID: UserID, senderClientID: String?, date: Date, eventMessage: String)?
    public var processProtobufMessageMessageGenericMessageContentGenericMessageOneOfContentConversationZMConversationConversationIDConversationIDSenderIDUserIDSenderClientIDStringDateDateEventMessageStringVoidReceivedInvocations: [(message: GenericMessage, content: GenericMessage.OneOf_Content, conversation: ZMConversation, conversationID: ConversationID, senderID: UserID, senderClientID: String?, date: Date, eventMessage: String)] = []
    public var processProtobufMessageMessageGenericMessageContentGenericMessageOneOfContentConversationZMConversationConversationIDConversationIDSenderIDUserIDSenderClientIDStringDateDateEventMessageStringVoidClosure: ((GenericMessage, GenericMessage.OneOf_Content, ZMConversation, ConversationID, UserID, String?, Date, String) async throws -> Void)?

    public func processProtobufMessage(_ message: GenericMessage, content: GenericMessage.OneOf_Content, conversation: ZMConversation, conversationID: ConversationID, senderID: UserID, senderClientID: String?, date: Date, eventMessage: String) async throws {
        processProtobufMessageMessageGenericMessageContentGenericMessageOneOfContentConversationZMConversationConversationIDConversationIDSenderIDUserIDSenderClientIDStringDateDateEventMessageStringVoidCallsCount += 1
        processProtobufMessageMessageGenericMessageContentGenericMessageOneOfContentConversationZMConversationConversationIDConversationIDSenderIDUserIDSenderClientIDStringDateDateEventMessageStringVoidReceivedArguments = (message: message, content: content, conversation: conversation, conversationID: conversationID, senderID: senderID, senderClientID: senderClientID, date: date, eventMessage: eventMessage)
        processProtobufMessageMessageGenericMessageContentGenericMessageOneOfContentConversationZMConversationConversationIDConversationIDSenderIDUserIDSenderClientIDStringDateDateEventMessageStringVoidReceivedInvocations.append((message: message, content: content, conversation: conversation, conversationID: conversationID, senderID: senderID, senderClientID: senderClientID, date: date, eventMessage: eventMessage))
        if let error = processProtobufMessageMessageGenericMessageContentGenericMessageOneOfContentConversationZMConversationConversationIDConversationIDSenderIDUserIDSenderClientIDStringDateDateEventMessageStringVoidThrowableError {
            throw error
        }
        try await processProtobufMessageMessageGenericMessageContentGenericMessageOneOfContentConversationZMConversationConversationIDConversationIDSenderIDUserIDSenderClientIDStringDateDateEventMessageStringVoidClosure?(message, content, conversation, conversationID, senderID, senderClientID, date, eventMessage)
    }


}
public class ConversationRepositoryProtocolMock: ConversationRepositoryProtocol {

    public init() {}



    //MARK: - pullConversation

    public var pullConversationIdUUIDDomainStringVoidThrowableError: (any Error)?
    public var pullConversationIdUUIDDomainStringVoidCallsCount = 0
    public var pullConversationIdUUIDDomainStringVoidCalled: Bool {
        return pullConversationIdUUIDDomainStringVoidCallsCount > 0
    }
    public var pullConversationIdUUIDDomainStringVoidReceivedArguments: (id: UUID, domain: String)?
    public var pullConversationIdUUIDDomainStringVoidReceivedInvocations: [(id: UUID, domain: String)] = []
    public var pullConversationIdUUIDDomainStringVoidClosure: ((UUID, String) async throws -> Void)?

    public func pullConversation(id: UUID, domain: String) async throws {
        pullConversationIdUUIDDomainStringVoidCallsCount += 1
        pullConversationIdUUIDDomainStringVoidReceivedArguments = (id: id, domain: domain)
        pullConversationIdUUIDDomainStringVoidReceivedInvocations.append((id: id, domain: domain))
        if let error = pullConversationIdUUIDDomainStringVoidThrowableError {
            throw error
        }
        try await pullConversationIdUUIDDomainStringVoidClosure?(id, domain)
    }

    //MARK: - fetchConversation

    public var fetchConversationIdUUIDDomainStringZMConversationCallsCount = 0
    public var fetchConversationIdUUIDDomainStringZMConversationCalled: Bool {
        return fetchConversationIdUUIDDomainStringZMConversationCallsCount > 0
    }
    public var fetchConversationIdUUIDDomainStringZMConversationReceivedArguments: (id: UUID, domain: String?)?
    public var fetchConversationIdUUIDDomainStringZMConversationReceivedInvocations: [(id: UUID, domain: String?)] = []
    public var fetchConversationIdUUIDDomainStringZMConversationReturnValue: ZMConversation?
    public var fetchConversationIdUUIDDomainStringZMConversationClosure: ((UUID, String?) async -> ZMConversation?)?

    public func fetchConversation(id: UUID, domain: String?) async -> ZMConversation? {
        fetchConversationIdUUIDDomainStringZMConversationCallsCount += 1
        fetchConversationIdUUIDDomainStringZMConversationReceivedArguments = (id: id, domain: domain)
        fetchConversationIdUUIDDomainStringZMConversationReceivedInvocations.append((id: id, domain: domain))
        if let fetchConversationIdUUIDDomainStringZMConversationClosure = fetchConversationIdUUIDDomainStringZMConversationClosure {
            return await fetchConversationIdUUIDDomainStringZMConversationClosure(id, domain)
        } else {
            return fetchConversationIdUUIDDomainStringZMConversationReturnValue
        }
    }

    //MARK: - storeConversation

    public var storeConversationConversationWireDomainConversationTimestampDateVoidCallsCount = 0
    public var storeConversationConversationWireDomainConversationTimestampDateVoidCalled: Bool {
        return storeConversationConversationWireDomainConversationTimestampDateVoidCallsCount > 0
    }
    public var storeConversationConversationWireDomainConversationTimestampDateVoidReceivedArguments: (conversation: WireDomain.Conversation, timestamp: Date)?
    public var storeConversationConversationWireDomainConversationTimestampDateVoidReceivedInvocations: [(conversation: WireDomain.Conversation, timestamp: Date)] = []
    public var storeConversationConversationWireDomainConversationTimestampDateVoidClosure: ((WireDomain.Conversation, Date) async -> Void)?

    public func storeConversation(_ conversation: WireDomain.Conversation, timestamp: Date) async {
        storeConversationConversationWireDomainConversationTimestampDateVoidCallsCount += 1
        storeConversationConversationWireDomainConversationTimestampDateVoidReceivedArguments = (conversation: conversation, timestamp: timestamp)
        storeConversationConversationWireDomainConversationTimestampDateVoidReceivedInvocations.append((conversation: conversation, timestamp: timestamp))
        await storeConversationConversationWireDomainConversationTimestampDateVoidClosure?(conversation, timestamp)
    }

    //MARK: - fetchOrCreateConversation

    public var fetchOrCreateConversationIdUUIDDomainStringZMConversationCallsCount = 0
    public var fetchOrCreateConversationIdUUIDDomainStringZMConversationCalled: Bool {
        return fetchOrCreateConversationIdUUIDDomainStringZMConversationCallsCount > 0
    }
    public var fetchOrCreateConversationIdUUIDDomainStringZMConversationReceivedArguments: (id: UUID, domain: String?)?
    public var fetchOrCreateConversationIdUUIDDomainStringZMConversationReceivedInvocations: [(id: UUID, domain: String?)] = []
    public var fetchOrCreateConversationIdUUIDDomainStringZMConversationReturnValue: ZMConversation!
    public var fetchOrCreateConversationIdUUIDDomainStringZMConversationClosure: ((UUID, String?) async -> ZMConversation)?

    public func fetchOrCreateConversation(id: UUID, domain: String?) async -> ZMConversation {
        fetchOrCreateConversationIdUUIDDomainStringZMConversationCallsCount += 1
        fetchOrCreateConversationIdUUIDDomainStringZMConversationReceivedArguments = (id: id, domain: domain)
        fetchOrCreateConversationIdUUIDDomainStringZMConversationReceivedInvocations.append((id: id, domain: domain))
        if let fetchOrCreateConversationIdUUIDDomainStringZMConversationClosure = fetchOrCreateConversationIdUUIDDomainStringZMConversationClosure {
            return await fetchOrCreateConversationIdUUIDDomainStringZMConversationClosure(id, domain)
        } else {
            return fetchOrCreateConversationIdUUIDDomainStringZMConversationReturnValue
        }
    }

    //MARK: - pullMLSOneToOneConversation

    public var pullMLSOneToOneConversationUserIDStringUserDomainStringStringThrowableError: (any Error)?
    public var pullMLSOneToOneConversationUserIDStringUserDomainStringStringCallsCount = 0
    public var pullMLSOneToOneConversationUserIDStringUserDomainStringStringCalled: Bool {
        return pullMLSOneToOneConversationUserIDStringUserDomainStringStringCallsCount > 0
    }
    public var pullMLSOneToOneConversationUserIDStringUserDomainStringStringReceivedArguments: (userID: String, userDomain: String)?
    public var pullMLSOneToOneConversationUserIDStringUserDomainStringStringReceivedInvocations: [(userID: String, userDomain: String)] = []
    public var pullMLSOneToOneConversationUserIDStringUserDomainStringStringReturnValue: String!
    public var pullMLSOneToOneConversationUserIDStringUserDomainStringStringClosure: ((String, String) async throws -> String)?

    public func pullMLSOneToOneConversation(userID: String, userDomain: String) async throws -> String {
        pullMLSOneToOneConversationUserIDStringUserDomainStringStringCallsCount += 1
        pullMLSOneToOneConversationUserIDStringUserDomainStringStringReceivedArguments = (userID: userID, userDomain: userDomain)
        pullMLSOneToOneConversationUserIDStringUserDomainStringStringReceivedInvocations.append((userID: userID, userDomain: userDomain))
        if let error = pullMLSOneToOneConversationUserIDStringUserDomainStringStringThrowableError {
            throw error
        }
        if let pullMLSOneToOneConversationUserIDStringUserDomainStringStringClosure = pullMLSOneToOneConversationUserIDStringUserDomainStringStringClosure {
            return try await pullMLSOneToOneConversationUserIDStringUserDomainStringStringClosure(userID, userDomain)
        } else {
            return pullMLSOneToOneConversationUserIDStringUserDomainStringStringReturnValue
        }
    }

    //MARK: - fetchMLSConversation

    public var fetchMLSConversationGroupIDStringZMConversationCallsCount = 0
    public var fetchMLSConversationGroupIDStringZMConversationCalled: Bool {
        return fetchMLSConversationGroupIDStringZMConversationCallsCount > 0
    }
    public var fetchMLSConversationGroupIDStringZMConversationReceivedGroupID: (String)?
    public var fetchMLSConversationGroupIDStringZMConversationReceivedInvocations: [(String)] = []
    public var fetchMLSConversationGroupIDStringZMConversationReturnValue: ZMConversation?
    public var fetchMLSConversationGroupIDStringZMConversationClosure: ((String) async -> ZMConversation?)?

    public func fetchMLSConversation(groupID: String) async -> ZMConversation? {
        fetchMLSConversationGroupIDStringZMConversationCallsCount += 1
        fetchMLSConversationGroupIDStringZMConversationReceivedGroupID = groupID
        fetchMLSConversationGroupIDStringZMConversationReceivedInvocations.append(groupID)
        if let fetchMLSConversationGroupIDStringZMConversationClosure = fetchMLSConversationGroupIDStringZMConversationClosure {
            return await fetchMLSConversationGroupIDStringZMConversationClosure(groupID)
        } else {
            return fetchMLSConversationGroupIDStringZMConversationReturnValue
        }
    }

    //MARK: - deleteConversation

    public var deleteConversationIdUUIDDomainStringVoidThrowableError: (any Error)?
    public var deleteConversationIdUUIDDomainStringVoidCallsCount = 0
    public var deleteConversationIdUUIDDomainStringVoidCalled: Bool {
        return deleteConversationIdUUIDDomainStringVoidCallsCount > 0
    }
    public var deleteConversationIdUUIDDomainStringVoidReceivedArguments: (id: UUID, domain: String?)?
    public var deleteConversationIdUUIDDomainStringVoidReceivedInvocations: [(id: UUID, domain: String?)] = []
    public var deleteConversationIdUUIDDomainStringVoidClosure: ((UUID, String?) async throws -> Void)?

    public func deleteConversation(id: UUID, domain: String?) async throws {
        deleteConversationIdUUIDDomainStringVoidCallsCount += 1
        deleteConversationIdUUIDDomainStringVoidReceivedArguments = (id: id, domain: domain)
        deleteConversationIdUUIDDomainStringVoidReceivedInvocations.append((id: id, domain: domain))
        if let error = deleteConversationIdUUIDDomainStringVoidThrowableError {
            throw error
        }
        try await deleteConversationIdUUIDDomainStringVoidClosure?(id, domain)
    }

    //MARK: - removeParticipantFromAllGroupConversations

    public var removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringRemovedAtDateDateVoidThrowableError: (any Error)?
    public var removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringRemovedAtDateDateVoidCallsCount = 0
    public var removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringRemovedAtDateDateVoidCalled: Bool {
        return removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringRemovedAtDateDateVoidCallsCount > 0
    }
    public var removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringRemovedAtDateDateVoidReceivedArguments: (participantID: UUID, participantDomain: String?, date: Date)?
    public var removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringRemovedAtDateDateVoidReceivedInvocations: [(participantID: UUID, participantDomain: String?, date: Date)] = []
    public var removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringRemovedAtDateDateVoidClosure: ((UUID, String?, Date) async throws -> Void)?

    public func removeParticipantFromAllGroupConversations(participantID: UUID, participantDomain: String?, removedAt date: Date) async throws {
        removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringRemovedAtDateDateVoidCallsCount += 1
        removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringRemovedAtDateDateVoidReceivedArguments = (participantID: participantID, participantDomain: participantDomain, date: date)
        removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringRemovedAtDateDateVoidReceivedInvocations.append((participantID: participantID, participantDomain: participantDomain, date: date))
        if let error = removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringRemovedAtDateDateVoidThrowableError {
            throw error
        }
        try await removeParticipantFromAllGroupConversationsParticipantIDUUIDParticipantDomainStringRemovedAtDateDateVoidClosure?(participantID, participantDomain, date)
    }

    //MARK: - addOrUpdateParticipant

    public var addOrUpdateParticipantParticipantIDUUIDParticipantDomainStringParticipantRoleStringConversationIDUUIDConversationDomainStringVoidCallsCount = 0
    public var addOrUpdateParticipantParticipantIDUUIDParticipantDomainStringParticipantRoleStringConversationIDUUIDConversationDomainStringVoidCalled: Bool {
        return addOrUpdateParticipantParticipantIDUUIDParticipantDomainStringParticipantRoleStringConversationIDUUIDConversationDomainStringVoidCallsCount > 0
    }
    public var addOrUpdateParticipantParticipantIDUUIDParticipantDomainStringParticipantRoleStringConversationIDUUIDConversationDomainStringVoidReceivedArguments: (participantID: UUID, participantDomain: String?, participantRole: String, conversationID: UUID, conversationDomain: String?)?
    public var addOrUpdateParticipantParticipantIDUUIDParticipantDomainStringParticipantRoleStringConversationIDUUIDConversationDomainStringVoidReceivedInvocations: [(participantID: UUID, participantDomain: String?, participantRole: String, conversationID: UUID, conversationDomain: String?)] = []
    public var addOrUpdateParticipantParticipantIDUUIDParticipantDomainStringParticipantRoleStringConversationIDUUIDConversationDomainStringVoidClosure: ((UUID, String?, String, UUID, String?) async -> Void)?

    public func addOrUpdateParticipant(participantID: UUID, participantDomain: String?, participantRole: String, conversationID: UUID, conversationDomain: String?) async {
        addOrUpdateParticipantParticipantIDUUIDParticipantDomainStringParticipantRoleStringConversationIDUUIDConversationDomainStringVoidCallsCount += 1
        addOrUpdateParticipantParticipantIDUUIDParticipantDomainStringParticipantRoleStringConversationIDUUIDConversationDomainStringVoidReceivedArguments = (participantID: participantID, participantDomain: participantDomain, participantRole: participantRole, conversationID: conversationID, conversationDomain: conversationDomain)
        addOrUpdateParticipantParticipantIDUUIDParticipantDomainStringParticipantRoleStringConversationIDUUIDConversationDomainStringVoidReceivedInvocations.append((participantID: participantID, participantDomain: participantDomain, participantRole: participantRole, conversationID: conversationID, conversationDomain: conversationDomain))
        await addOrUpdateParticipantParticipantIDUUIDParticipantDomainStringParticipantRoleStringConversationIDUUIDConversationDomainStringVoidClosure?(participantID, participantDomain, participantRole, conversationID, conversationDomain)
    }

    //MARK: - addParticipants

    public var addParticipantsParticipantsIdUUIDDomainStringRoleStringSenderIdUUIDDomainStringDateDateConversationIDUUIDConversationDomainStringVoidThrowableError: (any Error)?
    public var addParticipantsParticipantsIdUUIDDomainStringRoleStringSenderIdUUIDDomainStringDateDateConversationIDUUIDConversationDomainStringVoidCallsCount = 0
    public var addParticipantsParticipantsIdUUIDDomainStringRoleStringSenderIdUUIDDomainStringDateDateConversationIDUUIDConversationDomainStringVoidCalled: Bool {
        return addParticipantsParticipantsIdUUIDDomainStringRoleStringSenderIdUUIDDomainStringDateDateConversationIDUUIDConversationDomainStringVoidCallsCount > 0
    }
    public var addParticipantsParticipantsIdUUIDDomainStringRoleStringSenderIdUUIDDomainStringDateDateConversationIDUUIDConversationDomainStringVoidReceivedArguments: (participants: [(id: UUID, domain: String?, role: String?)], sender: (id: UUID, domain: String?), date: Date, conversationID: UUID, conversationDomain: String)?
    public var addParticipantsParticipantsIdUUIDDomainStringRoleStringSenderIdUUIDDomainStringDateDateConversationIDUUIDConversationDomainStringVoidReceivedInvocations: [(participants: [(id: UUID, domain: String?, role: String?)], sender: (id: UUID, domain: String?), date: Date, conversationID: UUID, conversationDomain: String)] = []
    public var addParticipantsParticipantsIdUUIDDomainStringRoleStringSenderIdUUIDDomainStringDateDateConversationIDUUIDConversationDomainStringVoidClosure: (([(id: UUID, domain: String?, role: String?)], (id: UUID, domain: String?), Date, UUID, String) async throws -> Void)?

    public func addParticipants(_ participants: [(id: UUID, domain: String?, role: String?)], sender: (id: UUID, domain: String?), date: Date, conversationID: UUID, conversationDomain: String) async throws {
        addParticipantsParticipantsIdUUIDDomainStringRoleStringSenderIdUUIDDomainStringDateDateConversationIDUUIDConversationDomainStringVoidCallsCount += 1
        addParticipantsParticipantsIdUUIDDomainStringRoleStringSenderIdUUIDDomainStringDateDateConversationIDUUIDConversationDomainStringVoidReceivedArguments = (participants: participants, sender: sender, date: date, conversationID: conversationID, conversationDomain: conversationDomain)
        addParticipantsParticipantsIdUUIDDomainStringRoleStringSenderIdUUIDDomainStringDateDateConversationIDUUIDConversationDomainStringVoidReceivedInvocations.append((participants: participants, sender: sender, date: date, conversationID: conversationID, conversationDomain: conversationDomain))
        if let error = addParticipantsParticipantsIdUUIDDomainStringRoleStringSenderIdUUIDDomainStringDateDateConversationIDUUIDConversationDomainStringVoidThrowableError {
            throw error
        }
        try await addParticipantsParticipantsIdUUIDDomainStringRoleStringSenderIdUUIDDomainStringDateDateConversationIDUUIDConversationDomainStringVoidClosure?(participants, sender, date, conversationID, conversationDomain)
    }

    //MARK: - removeMembers

    public var removeMembersUserIDsSetUserIDFromConversationConversationIDInitiatedBySenderUserIDAtDateDateReasonConversationMemberLeaveReasonVoidThrowableError: (any Error)?
    public var removeMembersUserIDsSetUserIDFromConversationConversationIDInitiatedBySenderUserIDAtDateDateReasonConversationMemberLeaveReasonVoidCallsCount = 0
    public var removeMembersUserIDsSetUserIDFromConversationConversationIDInitiatedBySenderUserIDAtDateDateReasonConversationMemberLeaveReasonVoidCalled: Bool {
        return removeMembersUserIDsSetUserIDFromConversationConversationIDInitiatedBySenderUserIDAtDateDateReasonConversationMemberLeaveReasonVoidCallsCount > 0
    }
    public var removeMembersUserIDsSetUserIDFromConversationConversationIDInitiatedBySenderUserIDAtDateDateReasonConversationMemberLeaveReasonVoidReceivedArguments: (userIDs: Set<UserID>, conversation: ConversationID, sender: UserID, date: Date, reason: ConversationMemberLeaveReason)?
    public var removeMembersUserIDsSetUserIDFromConversationConversationIDInitiatedBySenderUserIDAtDateDateReasonConversationMemberLeaveReasonVoidReceivedInvocations: [(userIDs: Set<UserID>, conversation: ConversationID, sender: UserID, date: Date, reason: ConversationMemberLeaveReason)] = []
    public var removeMembersUserIDsSetUserIDFromConversationConversationIDInitiatedBySenderUserIDAtDateDateReasonConversationMemberLeaveReasonVoidClosure: ((Set<UserID>, ConversationID, UserID, Date, ConversationMemberLeaveReason) async throws -> Void)?

    public func removeMembers(_ userIDs: Set<UserID>, from conversation: ConversationID, initiatedBy sender: UserID, at date: Date, reason: ConversationMemberLeaveReason) async throws {
        removeMembersUserIDsSetUserIDFromConversationConversationIDInitiatedBySenderUserIDAtDateDateReasonConversationMemberLeaveReasonVoidCallsCount += 1
        removeMembersUserIDsSetUserIDFromConversationConversationIDInitiatedBySenderUserIDAtDateDateReasonConversationMemberLeaveReasonVoidReceivedArguments = (userIDs: userIDs, conversation: conversation, sender: sender, date: date, reason: reason)
        removeMembersUserIDsSetUserIDFromConversationConversationIDInitiatedBySenderUserIDAtDateDateReasonConversationMemberLeaveReasonVoidReceivedInvocations.append((userIDs: userIDs, conversation: conversation, sender: sender, date: date, reason: reason))
        if let error = removeMembersUserIDsSetUserIDFromConversationConversationIDInitiatedBySenderUserIDAtDateDateReasonConversationMemberLeaveReasonVoidThrowableError {
            throw error
        }
        try await removeMembersUserIDsSetUserIDFromConversationConversationIDInitiatedBySenderUserIDAtDateDateReasonConversationMemberLeaveReasonVoidClosure?(userIDs, conversation, sender, date, reason)
    }

    //MARK: - updateConversationName

    public var updateConversationNameNewNameStringConversationIDUUIDConversationDomainStringSenderIDUUIDSenderDomainStringDateDateVoidCallsCount = 0
    public var updateConversationNameNewNameStringConversationIDUUIDConversationDomainStringSenderIDUUIDSenderDomainStringDateDateVoidCalled: Bool {
        return updateConversationNameNewNameStringConversationIDUUIDConversationDomainStringSenderIDUUIDSenderDomainStringDateDateVoidCallsCount > 0
    }
    public var updateConversationNameNewNameStringConversationIDUUIDConversationDomainStringSenderIDUUIDSenderDomainStringDateDateVoidReceivedArguments: (newName: String, conversationID: UUID, conversationDomain: String?, senderID: UUID, senderDomain: String?, date: Date)?
    public var updateConversationNameNewNameStringConversationIDUUIDConversationDomainStringSenderIDUUIDSenderDomainStringDateDateVoidReceivedInvocations: [(newName: String, conversationID: UUID, conversationDomain: String?, senderID: UUID, senderDomain: String?, date: Date)] = []
    public var updateConversationNameNewNameStringConversationIDUUIDConversationDomainStringSenderIDUUIDSenderDomainStringDateDateVoidClosure: ((String, UUID, String?, UUID, String?, Date) async -> Void)?

    public func updateConversationName(newName: String, conversationID: UUID, conversationDomain: String?, senderID: UUID, senderDomain: String?, date: Date) async {
        updateConversationNameNewNameStringConversationIDUUIDConversationDomainStringSenderIDUUIDSenderDomainStringDateDateVoidCallsCount += 1
        updateConversationNameNewNameStringConversationIDUUIDConversationDomainStringSenderIDUUIDSenderDomainStringDateDateVoidReceivedArguments = (newName: newName, conversationID: conversationID, conversationDomain: conversationDomain, senderID: senderID, senderDomain: senderDomain, date: date)
        updateConversationNameNewNameStringConversationIDUUIDConversationDomainStringSenderIDUUIDSenderDomainStringDateDateVoidReceivedInvocations.append((newName: newName, conversationID: conversationID, conversationDomain: conversationDomain, senderID: senderID, senderDomain: senderDomain, date: date))
        await updateConversationNameNewNameStringConversationIDUUIDConversationDomainStringSenderIDUUIDSenderDomainStringDateDateVoidClosure?(newName, conversationID, conversationDomain, senderID, senderDomain, date)
    }

    //MARK: - fetchConversationGuestLink

    public var fetchConversationGuestLinkConversationIDStringStringThrowableError: (any Error)?
    public var fetchConversationGuestLinkConversationIDStringStringCallsCount = 0
    public var fetchConversationGuestLinkConversationIDStringStringCalled: Bool {
        return fetchConversationGuestLinkConversationIDStringStringCallsCount > 0
    }
    public var fetchConversationGuestLinkConversationIDStringStringReceivedConversationID: (String)?
    public var fetchConversationGuestLinkConversationIDStringStringReceivedInvocations: [(String)] = []
    public var fetchConversationGuestLinkConversationIDStringStringReturnValue: String?
    public var fetchConversationGuestLinkConversationIDStringStringClosure: ((String) async throws -> String?)?

    public func fetchConversationGuestLink(conversationID: String) async throws -> String? {
        fetchConversationGuestLinkConversationIDStringStringCallsCount += 1
        fetchConversationGuestLinkConversationIDStringStringReceivedConversationID = conversationID
        fetchConversationGuestLinkConversationIDStringStringReceivedInvocations.append(conversationID)
        if let error = fetchConversationGuestLinkConversationIDStringStringThrowableError {
            throw error
        }
        if let fetchConversationGuestLinkConversationIDStringStringClosure = fetchConversationGuestLinkConversationIDStringStringClosure {
            return try await fetchConversationGuestLinkConversationIDStringStringClosure(conversationID)
        } else {
            return fetchConversationGuestLinkConversationIDStringStringReturnValue
        }
    }


}
class ConversationTextMessageNotificationBuilderProtocolMock: ConversationTextMessageNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentTextTextConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount = 0
    var buildContentTextTextConversationIDConversationIDSenderIDUserIDUserNotificationCalled: Bool {
        return buildContentTextTextConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount > 0
    }
    var buildContentTextTextConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments: (text: Text, conversationID: ConversationID, senderID: UserID)?
    var buildContentTextTextConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations: [(text: Text, conversationID: ConversationID, senderID: UserID)] = []
    var buildContentTextTextConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue: UserNotification?
    var buildContentTextTextConversationIDConversationIDSenderIDUserIDUserNotificationClosure: ((Text, ConversationID, UserID) async -> UserNotification?)?

    func buildContent(text: Text, conversationID: ConversationID, senderID: UserID) async -> UserNotification? {
        buildContentTextTextConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount += 1
        buildContentTextTextConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments = (text: text, conversationID: conversationID, senderID: senderID)
        buildContentTextTextConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations.append((text: text, conversationID: conversationID, senderID: senderID))
        if let buildContentTextTextConversationIDConversationIDSenderIDUserIDUserNotificationClosure = buildContentTextTextConversationIDConversationIDSenderIDUserIDUserNotificationClosure {
            return await buildContentTextTextConversationIDConversationIDSenderIDUserIDUserNotificationClosure(text, conversationID, senderID)
        } else {
            return buildContentTextTextConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue
        }
    }


}
class ConversationVideoMessageNotificationBuilderProtocolMock: ConversationVideoMessageNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount = 0
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCalled: Bool {
        return buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount > 0
    }
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments: (conversationID: ConversationID, senderID: UserID)?
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations: [(conversationID: ConversationID, senderID: UserID)] = []
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue: UserNotification!
    var buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure: ((ConversationID, UserID) async -> UserNotification)?

    func buildContent(conversationID: ConversationID, senderID: UserID) async -> UserNotification {
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationCallsCount += 1
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedArguments = (conversationID: conversationID, senderID: senderID)
        buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReceivedInvocations.append((conversationID: conversationID, senderID: senderID))
        if let buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure = buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure {
            return await buildContentConversationIDConversationIDSenderIDUserIDUserNotificationClosure(conversationID, senderID)
        } else {
            return buildContentConversationIDConversationIDSenderIDUserIDUserNotificationReturnValue
        }
    }


}
public class CreateChannelUseCaseProtocolMock: CreateChannelUseCaseProtocol {

    public init() {}



    //MARK: - invoke

    public var invokeTeamIDUUIDNameStringHistoryDepthIntUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolZMConversationThrowableError: (any Error)?
    public var invokeTeamIDUUIDNameStringHistoryDepthIntUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolZMConversationCallsCount = 0
    public var invokeTeamIDUUIDNameStringHistoryDepthIntUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolZMConversationCalled: Bool {
        return invokeTeamIDUUIDNameStringHistoryDepthIntUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolZMConversationCallsCount > 0
    }
    public var invokeTeamIDUUIDNameStringHistoryDepthIntUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolZMConversationReceivedArguments: (teamID: UUID, name: String?, historyDepth: Int?, users: Set<ZMUser>, accessMode: Set<WireNetwork.ConversationAccessMode>, accessRoles: Set<WireNetwork.ConversationAccessRole>, enableReceipts: Bool)?
    public var invokeTeamIDUUIDNameStringHistoryDepthIntUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolZMConversationReceivedInvocations: [(teamID: UUID, name: String?, historyDepth: Int?, users: Set<ZMUser>, accessMode: Set<WireNetwork.ConversationAccessMode>, accessRoles: Set<WireNetwork.ConversationAccessRole>, enableReceipts: Bool)] = []
    public var invokeTeamIDUUIDNameStringHistoryDepthIntUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolZMConversationReturnValue: ZMConversation!
    public var invokeTeamIDUUIDNameStringHistoryDepthIntUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolZMConversationClosure: ((UUID, String?, Int?, Set<ZMUser>, Set<WireNetwork.ConversationAccessMode>, Set<WireNetwork.ConversationAccessRole>, Bool) async throws -> ZMConversation)?

    public func invoke(teamID: UUID, name: String?, historyDepth: Int?, users: Set<ZMUser>, accessMode: Set<WireNetwork.ConversationAccessMode>, accessRoles: Set<WireNetwork.ConversationAccessRole>, enableReceipts: Bool) async throws -> ZMConversation {
        invokeTeamIDUUIDNameStringHistoryDepthIntUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolZMConversationCallsCount += 1
        invokeTeamIDUUIDNameStringHistoryDepthIntUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolZMConversationReceivedArguments = (teamID: teamID, name: name, historyDepth: historyDepth, users: users, accessMode: accessMode, accessRoles: accessRoles, enableReceipts: enableReceipts)
        invokeTeamIDUUIDNameStringHistoryDepthIntUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolZMConversationReceivedInvocations.append((teamID: teamID, name: name, historyDepth: historyDepth, users: users, accessMode: accessMode, accessRoles: accessRoles, enableReceipts: enableReceipts))
        if let error = invokeTeamIDUUIDNameStringHistoryDepthIntUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolZMConversationThrowableError {
            throw error
        }
        if let invokeTeamIDUUIDNameStringHistoryDepthIntUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolZMConversationClosure = invokeTeamIDUUIDNameStringHistoryDepthIntUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolZMConversationClosure {
            return try await invokeTeamIDUUIDNameStringHistoryDepthIntUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolZMConversationClosure(teamID, name, historyDepth, users, accessMode, accessRoles, enableReceipts)
        } else {
            return invokeTeamIDUUIDNameStringHistoryDepthIntUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolZMConversationReturnValue
        }
    }


}
public class CreateGroupConversationUseCaseProtocolMock: CreateGroupConversationUseCaseProtocol {

    public init() {}



    //MARK: - invoke

    public var invokeTeamIDUUIDMessageProtocolWireNetworkConversationMessageProtocolNameStringUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolIsMLSEnabledBoolZMConversationThrowableError: (any Error)?
    public var invokeTeamIDUUIDMessageProtocolWireNetworkConversationMessageProtocolNameStringUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolIsMLSEnabledBoolZMConversationCallsCount = 0
    public var invokeTeamIDUUIDMessageProtocolWireNetworkConversationMessageProtocolNameStringUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolIsMLSEnabledBoolZMConversationCalled: Bool {
        return invokeTeamIDUUIDMessageProtocolWireNetworkConversationMessageProtocolNameStringUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolIsMLSEnabledBoolZMConversationCallsCount > 0
    }
    public var invokeTeamIDUUIDMessageProtocolWireNetworkConversationMessageProtocolNameStringUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolIsMLSEnabledBoolZMConversationReceivedArguments: (teamID: UUID?, messageProtocol: WireNetwork.ConversationMessageProtocol, name: String?, users: Set<ZMUser>, accessMode: Set<WireNetwork.ConversationAccessMode>, accessRoles: Set<WireNetwork.ConversationAccessRole>, enableReceipts: Bool, isMLSEnabled: Bool)?
    public var invokeTeamIDUUIDMessageProtocolWireNetworkConversationMessageProtocolNameStringUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolIsMLSEnabledBoolZMConversationReceivedInvocations: [(teamID: UUID?, messageProtocol: WireNetwork.ConversationMessageProtocol, name: String?, users: Set<ZMUser>, accessMode: Set<WireNetwork.ConversationAccessMode>, accessRoles: Set<WireNetwork.ConversationAccessRole>, enableReceipts: Bool, isMLSEnabled: Bool)] = []
    public var invokeTeamIDUUIDMessageProtocolWireNetworkConversationMessageProtocolNameStringUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolIsMLSEnabledBoolZMConversationReturnValue: ZMConversation!
    public var invokeTeamIDUUIDMessageProtocolWireNetworkConversationMessageProtocolNameStringUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolIsMLSEnabledBoolZMConversationClosure: ((UUID?, WireNetwork.ConversationMessageProtocol, String?, Set<ZMUser>, Set<WireNetwork.ConversationAccessMode>, Set<WireNetwork.ConversationAccessRole>, Bool, Bool) async throws -> ZMConversation)?

    public func invoke(teamID: UUID?, messageProtocol: WireNetwork.ConversationMessageProtocol, name: String?, users: Set<ZMUser>, accessMode: Set<WireNetwork.ConversationAccessMode>, accessRoles: Set<WireNetwork.ConversationAccessRole>, enableReceipts: Bool, isMLSEnabled: Bool) async throws -> ZMConversation {
        invokeTeamIDUUIDMessageProtocolWireNetworkConversationMessageProtocolNameStringUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolIsMLSEnabledBoolZMConversationCallsCount += 1
        invokeTeamIDUUIDMessageProtocolWireNetworkConversationMessageProtocolNameStringUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolIsMLSEnabledBoolZMConversationReceivedArguments = (teamID: teamID, messageProtocol: messageProtocol, name: name, users: users, accessMode: accessMode, accessRoles: accessRoles, enableReceipts: enableReceipts, isMLSEnabled: isMLSEnabled)
        invokeTeamIDUUIDMessageProtocolWireNetworkConversationMessageProtocolNameStringUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolIsMLSEnabledBoolZMConversationReceivedInvocations.append((teamID: teamID, messageProtocol: messageProtocol, name: name, users: users, accessMode: accessMode, accessRoles: accessRoles, enableReceipts: enableReceipts, isMLSEnabled: isMLSEnabled))
        if let error = invokeTeamIDUUIDMessageProtocolWireNetworkConversationMessageProtocolNameStringUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolIsMLSEnabledBoolZMConversationThrowableError {
            throw error
        }
        if let invokeTeamIDUUIDMessageProtocolWireNetworkConversationMessageProtocolNameStringUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolIsMLSEnabledBoolZMConversationClosure = invokeTeamIDUUIDMessageProtocolWireNetworkConversationMessageProtocolNameStringUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolIsMLSEnabledBoolZMConversationClosure {
            return try await invokeTeamIDUUIDMessageProtocolWireNetworkConversationMessageProtocolNameStringUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolIsMLSEnabledBoolZMConversationClosure(teamID, messageProtocol, name, users, accessMode, accessRoles, enableReceipts, isMLSEnabled)
        } else {
            return invokeTeamIDUUIDMessageProtocolWireNetworkConversationMessageProtocolNameStringUsersSetZMUserAccessModeSetWireNetworkConversationAccessModeAccessRolesSetWireNetworkConversationAccessRoleEnableReceiptsBoolIsMLSEnabledBoolZMConversationReturnValue
        }
    }


}
public class DatabaseSaverProtocolMock: DatabaseSaverProtocol {

    public init() {}



    //MARK: - save

    public var saveVoidThrowableError: (any Error)?
    public var saveVoidCallsCount = 0
    public var saveVoidCalled: Bool {
        return saveVoidCallsCount > 0
    }
    public var saveVoidClosure: (() async throws -> Void)?

    public func save() async throws {
        saveVoidCallsCount += 1
        if let error = saveVoidThrowableError {
            throw error
        }
        try await saveVoidClosure?()
    }


}
class GenerateNotificationUseCaseProtocolMock: GenerateNotificationUseCaseProtocol {




    //MARK: - invoke

    var invokeUpdateEventsAsyncStreamUpdateEventUserNotificationThrowableError: (any Error)?
    var invokeUpdateEventsAsyncStreamUpdateEventUserNotificationCallsCount = 0
    var invokeUpdateEventsAsyncStreamUpdateEventUserNotificationCalled: Bool {
        return invokeUpdateEventsAsyncStreamUpdateEventUserNotificationCallsCount > 0
    }
    var invokeUpdateEventsAsyncStreamUpdateEventUserNotificationReceivedUpdateEvents: (AsyncStream<[UpdateEvent]>)?
    var invokeUpdateEventsAsyncStreamUpdateEventUserNotificationReceivedInvocations: [(AsyncStream<[UpdateEvent]>)] = []
    var invokeUpdateEventsAsyncStreamUpdateEventUserNotificationReturnValue: [UserNotification]!
    var invokeUpdateEventsAsyncStreamUpdateEventUserNotificationClosure: ((AsyncStream<[UpdateEvent]>) async throws -> [UserNotification])?

    func invoke(updateEvents: AsyncStream<[UpdateEvent]>) async throws -> [UserNotification] {
        invokeUpdateEventsAsyncStreamUpdateEventUserNotificationCallsCount += 1
        invokeUpdateEventsAsyncStreamUpdateEventUserNotificationReceivedUpdateEvents = updateEvents
        invokeUpdateEventsAsyncStreamUpdateEventUserNotificationReceivedInvocations.append(updateEvents)
        if let error = invokeUpdateEventsAsyncStreamUpdateEventUserNotificationThrowableError {
            throw error
        }
        if let invokeUpdateEventsAsyncStreamUpdateEventUserNotificationClosure = invokeUpdateEventsAsyncStreamUpdateEventUserNotificationClosure {
            return try await invokeUpdateEventsAsyncStreamUpdateEventUserNotificationClosure(updateEvents)
        } else {
            return invokeUpdateEventsAsyncStreamUpdateEventUserNotificationReturnValue
        }
    }


}
public class IncrementalSyncProtocolMock: IncrementalSyncProtocol {

    public init() {}



    //MARK: - perform

    public var performIncrementalSyncTokenThrowableError: (any Error)?
    public var performIncrementalSyncTokenCallsCount = 0
    public var performIncrementalSyncTokenCalled: Bool {
        return performIncrementalSyncTokenCallsCount > 0
    }
    public var performIncrementalSyncTokenReturnValue: IncrementalSync.Token!
    public var performIncrementalSyncTokenClosure: (() async throws -> IncrementalSync.Token)?

    public func perform() async throws -> IncrementalSync.Token {
        performIncrementalSyncTokenCallsCount += 1
        if let error = performIncrementalSyncTokenThrowableError {
            throw error
        }
        if let performIncrementalSyncTokenClosure = performIncrementalSyncTokenClosure {
            return try await performIncrementalSyncTokenClosure()
        } else {
            return performIncrementalSyncTokenReturnValue
        }
    }


}
public class InitialSyncProtocolMock: InitialSyncProtocol {

    public init() {}



    //MARK: - perform

    public var performSkipPullingLastUpdateEventIDBoolVoidThrowableError: (any Error)?
    public var performSkipPullingLastUpdateEventIDBoolVoidCallsCount = 0
    public var performSkipPullingLastUpdateEventIDBoolVoidCalled: Bool {
        return performSkipPullingLastUpdateEventIDBoolVoidCallsCount > 0
    }
    public var performSkipPullingLastUpdateEventIDBoolVoidReceivedSkipPullingLastUpdateEventID: (Bool)?
    public var performSkipPullingLastUpdateEventIDBoolVoidReceivedInvocations: [(Bool)] = []
    public var performSkipPullingLastUpdateEventIDBoolVoidClosure: ((Bool) async throws -> Void)?

    public func perform(skipPullingLastUpdateEventID: Bool) async throws {
        performSkipPullingLastUpdateEventIDBoolVoidCallsCount += 1
        performSkipPullingLastUpdateEventIDBoolVoidReceivedSkipPullingLastUpdateEventID = skipPullingLastUpdateEventID
        performSkipPullingLastUpdateEventIDBoolVoidReceivedInvocations.append(skipPullingLastUpdateEventID)
        if let error = performSkipPullingLastUpdateEventIDBoolVoidThrowableError {
            throw error
        }
        try await performSkipPullingLastUpdateEventIDBoolVoidClosure?(skipPullingLastUpdateEventID)
    }


}
public class LiveSyncDelegateMock: LiveSyncDelegate {

    public init() {}



    //MARK: - isUpToDate

    public var isUpToDateSyncIncrementalSyncV2VoidCallsCount = 0
    public var isUpToDateSyncIncrementalSyncV2VoidCalled: Bool {
        return isUpToDateSyncIncrementalSyncV2VoidCallsCount > 0
    }
    public var isUpToDateSyncIncrementalSyncV2VoidReceivedSync: (IncrementalSyncV2)?
    public var isUpToDateSyncIncrementalSyncV2VoidReceivedInvocations: [(IncrementalSyncV2)] = []
    public var isUpToDateSyncIncrementalSyncV2VoidClosure: ((IncrementalSyncV2) -> Void)?

    public func isUpToDate(sync: IncrementalSyncV2) {
        isUpToDateSyncIncrementalSyncV2VoidCallsCount += 1
        isUpToDateSyncIncrementalSyncV2VoidReceivedSync = sync
        isUpToDateSyncIncrementalSyncV2VoidReceivedInvocations.append(sync)
        isUpToDateSyncIncrementalSyncV2VoidClosure?(sync)
    }

    //MARK: - didMissedEvents

    public var didMissedEventsSyncIncrementalSyncV2VoidCallsCount = 0
    public var didMissedEventsSyncIncrementalSyncV2VoidCalled: Bool {
        return didMissedEventsSyncIncrementalSyncV2VoidCallsCount > 0
    }
    public var didMissedEventsSyncIncrementalSyncV2VoidReceivedSync: (IncrementalSyncV2)?
    public var didMissedEventsSyncIncrementalSyncV2VoidReceivedInvocations: [(IncrementalSyncV2)] = []
    public var didMissedEventsSyncIncrementalSyncV2VoidClosure: ((IncrementalSyncV2) async -> Void)?

    public func didMissedEvents(sync: IncrementalSyncV2) async {
        didMissedEventsSyncIncrementalSyncV2VoidCallsCount += 1
        didMissedEventsSyncIncrementalSyncV2VoidReceivedSync = sync
        didMissedEventsSyncIncrementalSyncV2VoidReceivedInvocations.append(sync)
        await didMissedEventsSyncIncrementalSyncV2VoidClosure?(sync)
    }

    //MARK: - didFail

    public var didFailSyncIncrementalSyncV2ErrorAnyErrorVoidCallsCount = 0
    public var didFailSyncIncrementalSyncV2ErrorAnyErrorVoidCalled: Bool {
        return didFailSyncIncrementalSyncV2ErrorAnyErrorVoidCallsCount > 0
    }
    public var didFailSyncIncrementalSyncV2ErrorAnyErrorVoidReceivedArguments: (sync: IncrementalSyncV2, error: any Error)?
    public var didFailSyncIncrementalSyncV2ErrorAnyErrorVoidReceivedInvocations: [(sync: IncrementalSyncV2, error: any Error)] = []
    public var didFailSyncIncrementalSyncV2ErrorAnyErrorVoidClosure: ((IncrementalSyncV2, any Error) -> Void)?

    public func didFail(sync: IncrementalSyncV2, error: any Error) {
        didFailSyncIncrementalSyncV2ErrorAnyErrorVoidCallsCount += 1
        didFailSyncIncrementalSyncV2ErrorAnyErrorVoidReceivedArguments = (sync: sync, error: error)
        didFailSyncIncrementalSyncV2ErrorAnyErrorVoidReceivedInvocations.append((sync: sync, error: error))
        didFailSyncIncrementalSyncV2ErrorAnyErrorVoidClosure?(sync, error)
    }


}
public class LiveSyncProtocolMock: LiveSyncProtocol {

    public init() {}



    //MARK: - perform

    public var performIncrementalSyncTokenThrowableError: (any Error)?
    public var performIncrementalSyncTokenCallsCount = 0
    public var performIncrementalSyncTokenCalled: Bool {
        return performIncrementalSyncTokenCallsCount > 0
    }
    public var performIncrementalSyncTokenReturnValue: IncrementalSync.Token!
    public var performIncrementalSyncTokenClosure: (() async throws -> IncrementalSync.Token)?

    public func perform() async throws -> IncrementalSync.Token {
        performIncrementalSyncTokenCallsCount += 1
        if let error = performIncrementalSyncTokenThrowableError {
            throw error
        }
        if let performIncrementalSyncTokenClosure = performIncrementalSyncTokenClosure {
            return try await performIncrementalSyncTokenClosure()
        } else {
            return performIncrementalSyncTokenReturnValue
        }
    }


}
public class MLSGroupRepairAgentProtocolMock: MLSGroupRepairAgentProtocol {

    public init() {}



    //MARK: - repairConversations

    public var repairConversationsVoidCallsCount = 0
    public var repairConversationsVoidCalled: Bool {
        return repairConversationsVoidCallsCount > 0
    }
    public var repairConversationsVoidClosure: (() async -> Void)?

    public func repairConversations() async {
        repairConversationsVoidCallsCount += 1
        await repairConversationsVoidClosure?()
    }


}
class MLSMessageDecryptorProtocolMock: MLSMessageDecryptorProtocol {




    //MARK: - decryptedMessageAddEventData

    var decryptedMessageAddEventDataFromEventDataConversationMLSMessageAddEventContextCoreCryptoContextProtocolConversationMLSMessageAddEventThrowableError: (any Error)?
    var decryptedMessageAddEventDataFromEventDataConversationMLSMessageAddEventContextCoreCryptoContextProtocolConversationMLSMessageAddEventCallsCount = 0
    var decryptedMessageAddEventDataFromEventDataConversationMLSMessageAddEventContextCoreCryptoContextProtocolConversationMLSMessageAddEventCalled: Bool {
        return decryptedMessageAddEventDataFromEventDataConversationMLSMessageAddEventContextCoreCryptoContextProtocolConversationMLSMessageAddEventCallsCount > 0
    }
    var decryptedMessageAddEventDataFromEventDataConversationMLSMessageAddEventContextCoreCryptoContextProtocolConversationMLSMessageAddEventReceivedArguments: (eventData: ConversationMLSMessageAddEvent, context: CoreCryptoContextProtocol?)?
    var decryptedMessageAddEventDataFromEventDataConversationMLSMessageAddEventContextCoreCryptoContextProtocolConversationMLSMessageAddEventReceivedInvocations: [(eventData: ConversationMLSMessageAddEvent, context: CoreCryptoContextProtocol?)] = []
    var decryptedMessageAddEventDataFromEventDataConversationMLSMessageAddEventContextCoreCryptoContextProtocolConversationMLSMessageAddEventReturnValue: ConversationMLSMessageAddEvent!
    var decryptedMessageAddEventDataFromEventDataConversationMLSMessageAddEventContextCoreCryptoContextProtocolConversationMLSMessageAddEventClosure: ((ConversationMLSMessageAddEvent, CoreCryptoContextProtocol?) async throws -> ConversationMLSMessageAddEvent)?

    func decryptedMessageAddEventData(from eventData: ConversationMLSMessageAddEvent, context: CoreCryptoContextProtocol?) async throws -> ConversationMLSMessageAddEvent {
        decryptedMessageAddEventDataFromEventDataConversationMLSMessageAddEventContextCoreCryptoContextProtocolConversationMLSMessageAddEventCallsCount += 1
        decryptedMessageAddEventDataFromEventDataConversationMLSMessageAddEventContextCoreCryptoContextProtocolConversationMLSMessageAddEventReceivedArguments = (eventData: eventData, context: context)
        decryptedMessageAddEventDataFromEventDataConversationMLSMessageAddEventContextCoreCryptoContextProtocolConversationMLSMessageAddEventReceivedInvocations.append((eventData: eventData, context: context))
        if let error = decryptedMessageAddEventDataFromEventDataConversationMLSMessageAddEventContextCoreCryptoContextProtocolConversationMLSMessageAddEventThrowableError {
            throw error
        }
        if let decryptedMessageAddEventDataFromEventDataConversationMLSMessageAddEventContextCoreCryptoContextProtocolConversationMLSMessageAddEventClosure = decryptedMessageAddEventDataFromEventDataConversationMLSMessageAddEventContextCoreCryptoContextProtocolConversationMLSMessageAddEventClosure {
            return try await decryptedMessageAddEventDataFromEventDataConversationMLSMessageAddEventContextCoreCryptoContextProtocolConversationMLSMessageAddEventClosure(eventData, context)
        } else {
            return decryptedMessageAddEventDataFromEventDataConversationMLSMessageAddEventContextCoreCryptoContextProtocolConversationMLSMessageAddEventReturnValue
        }
    }

    //MARK: - decryptedWelcomeMessageEventData

    var decryptedWelcomeMessageEventDataFromEventDataConversationMLSWelcomeEventContextCoreCryptoContextProtocolVoidThrowableError: (any Error)?
    var decryptedWelcomeMessageEventDataFromEventDataConversationMLSWelcomeEventContextCoreCryptoContextProtocolVoidCallsCount = 0
    var decryptedWelcomeMessageEventDataFromEventDataConversationMLSWelcomeEventContextCoreCryptoContextProtocolVoidCalled: Bool {
        return decryptedWelcomeMessageEventDataFromEventDataConversationMLSWelcomeEventContextCoreCryptoContextProtocolVoidCallsCount > 0
    }
    var decryptedWelcomeMessageEventDataFromEventDataConversationMLSWelcomeEventContextCoreCryptoContextProtocolVoidReceivedArguments: (eventData: ConversationMLSWelcomeEvent, context: CoreCryptoContextProtocol?)?
    var decryptedWelcomeMessageEventDataFromEventDataConversationMLSWelcomeEventContextCoreCryptoContextProtocolVoidReceivedInvocations: [(eventData: ConversationMLSWelcomeEvent, context: CoreCryptoContextProtocol?)] = []
    var decryptedWelcomeMessageEventDataFromEventDataConversationMLSWelcomeEventContextCoreCryptoContextProtocolVoidClosure: ((ConversationMLSWelcomeEvent, CoreCryptoContextProtocol?) async throws -> Void)?

    func decryptedWelcomeMessageEventData(from eventData: ConversationMLSWelcomeEvent, context: CoreCryptoContextProtocol?) async throws {
        decryptedWelcomeMessageEventDataFromEventDataConversationMLSWelcomeEventContextCoreCryptoContextProtocolVoidCallsCount += 1
        decryptedWelcomeMessageEventDataFromEventDataConversationMLSWelcomeEventContextCoreCryptoContextProtocolVoidReceivedArguments = (eventData: eventData, context: context)
        decryptedWelcomeMessageEventDataFromEventDataConversationMLSWelcomeEventContextCoreCryptoContextProtocolVoidReceivedInvocations.append((eventData: eventData, context: context))
        if let error = decryptedWelcomeMessageEventDataFromEventDataConversationMLSWelcomeEventContextCoreCryptoContextProtocolVoidThrowableError {
            throw error
        }
        try await decryptedWelcomeMessageEventDataFromEventDataConversationMLSWelcomeEventContextCoreCryptoContextProtocolVoidClosure?(eventData, context)
    }


}
public class MessageLocalStoreProtocolMock: MessageLocalStoreProtocol {

    public init() {}



    //MARK: - addSystemMessage

    public var addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidCallsCount = 0
    public var addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidCalled: Bool {
        return addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidCallsCount > 0
    }
    public var addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidReceivedArguments: (messageType: SystemMessageType, conversationID: UUID, conversationDomain: String?)?
    public var addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidReceivedInvocations: [(messageType: SystemMessageType, conversationID: UUID, conversationDomain: String?)] = []
    public var addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidClosure: ((SystemMessageType, UUID, String?) async -> Void)?

    public func addSystemMessage(messageType: SystemMessageType, conversationID: UUID, conversationDomain: String?) async {
        addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidCallsCount += 1
        addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidReceivedArguments = (messageType: messageType, conversationID: conversationID, conversationDomain: conversationDomain)
        addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidReceivedInvocations.append((messageType: messageType, conversationID: conversationID, conversationDomain: conversationDomain))
        await addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidClosure?(messageType, conversationID, conversationDomain)
    }

    //MARK: - addPotentialGapSystemMessage

    public var addPotentialGapSystemMessageVoidThrowableError: (any Error)?
    public var addPotentialGapSystemMessageVoidCallsCount = 0
    public var addPotentialGapSystemMessageVoidCalled: Bool {
        return addPotentialGapSystemMessageVoidCallsCount > 0
    }
    public var addPotentialGapSystemMessageVoidClosure: (() async throws -> Void)?

    public func addPotentialGapSystemMessage() async throws {
        addPotentialGapSystemMessageVoidCallsCount += 1
        if let error = addPotentialGapSystemMessageVoidThrowableError {
            throw error
        }
        try await addPotentialGapSystemMessageVoidClosure?()
    }

    //MARK: - fetchOrCreateClientMessage

    public var fetchOrCreateClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMClientMessageIsNewBoolThrowableError: (any Error)?
    public var fetchOrCreateClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMClientMessageIsNewBoolCallsCount = 0
    public var fetchOrCreateClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMClientMessageIsNewBoolCalled: Bool {
        return fetchOrCreateClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMClientMessageIsNewBoolCallsCount > 0
    }
    public var fetchOrCreateClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMClientMessageIsNewBoolReceivedArguments: (id: String, conversation: ZMConversation, sender: (id: UUID, domain: String, clientID: String?), date: Date)?
    public var fetchOrCreateClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMClientMessageIsNewBoolReceivedInvocations: [(id: String, conversation: ZMConversation, sender: (id: UUID, domain: String, clientID: String?), date: Date)] = []
    public var fetchOrCreateClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMClientMessageIsNewBoolReturnValue: (ZMClientMessage, isNew: Bool)!
    public var fetchOrCreateClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMClientMessageIsNewBoolClosure: ((String, ZMConversation, (id: UUID, domain: String, clientID: String?), Date) async throws -> (ZMClientMessage, isNew: Bool))?

    public func fetchOrCreateClientMessage(id: String, conversation: ZMConversation, sender: (id: UUID, domain: String, clientID: String?), date: Date) async throws -> (ZMClientMessage, isNew: Bool) {
        fetchOrCreateClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMClientMessageIsNewBoolCallsCount += 1
        fetchOrCreateClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMClientMessageIsNewBoolReceivedArguments = (id: id, conversation: conversation, sender: sender, date: date)
        fetchOrCreateClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMClientMessageIsNewBoolReceivedInvocations.append((id: id, conversation: conversation, sender: sender, date: date))
        if let error = fetchOrCreateClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMClientMessageIsNewBoolThrowableError {
            throw error
        }
        if let fetchOrCreateClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMClientMessageIsNewBoolClosure = fetchOrCreateClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMClientMessageIsNewBoolClosure {
            return try await fetchOrCreateClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMClientMessageIsNewBoolClosure(id, conversation, sender, date)
        } else {
            return fetchOrCreateClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMClientMessageIsNewBoolReturnValue
        }
    }

    //MARK: - fetchOrCreateAssetClientMessage

    public var fetchOrCreateAssetClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMAssetClientMessageIsNewBoolThrowableError: (any Error)?
    public var fetchOrCreateAssetClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMAssetClientMessageIsNewBoolCallsCount = 0
    public var fetchOrCreateAssetClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMAssetClientMessageIsNewBoolCalled: Bool {
        return fetchOrCreateAssetClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMAssetClientMessageIsNewBoolCallsCount > 0
    }
    public var fetchOrCreateAssetClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMAssetClientMessageIsNewBoolReceivedArguments: (id: String, conversation: ZMConversation, sender: (id: UUID, domain: String, clientID: String?), date: Date)?
    public var fetchOrCreateAssetClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMAssetClientMessageIsNewBoolReceivedInvocations: [(id: String, conversation: ZMConversation, sender: (id: UUID, domain: String, clientID: String?), date: Date)] = []
    public var fetchOrCreateAssetClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMAssetClientMessageIsNewBoolReturnValue: (ZMAssetClientMessage, isNew: Bool)!
    public var fetchOrCreateAssetClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMAssetClientMessageIsNewBoolClosure: ((String, ZMConversation, (id: UUID, domain: String, clientID: String?), Date) async throws -> (ZMAssetClientMessage, isNew: Bool))?

    public func fetchOrCreateAssetClientMessage(id: String, conversation: ZMConversation, sender: (id: UUID, domain: String, clientID: String?), date: Date) async throws -> (ZMAssetClientMessage, isNew: Bool) {
        fetchOrCreateAssetClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMAssetClientMessageIsNewBoolCallsCount += 1
        fetchOrCreateAssetClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMAssetClientMessageIsNewBoolReceivedArguments = (id: id, conversation: conversation, sender: sender, date: date)
        fetchOrCreateAssetClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMAssetClientMessageIsNewBoolReceivedInvocations.append((id: id, conversation: conversation, sender: sender, date: date))
        if let error = fetchOrCreateAssetClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMAssetClientMessageIsNewBoolThrowableError {
            throw error
        }
        if let fetchOrCreateAssetClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMAssetClientMessageIsNewBoolClosure = fetchOrCreateAssetClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMAssetClientMessageIsNewBoolClosure {
            return try await fetchOrCreateAssetClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMAssetClientMessageIsNewBoolClosure(id, conversation, sender, date)
        } else {
            return fetchOrCreateAssetClientMessageIdStringConversationZMConversationSenderIdUUIDDomainStringClientIDStringDateDate_ZMAssetClientMessageIsNewBoolReturnValue
        }
    }

    //MARK: - addClientMessage

    public var addClientMessageClientMessageZMClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidCallsCount = 0
    public var addClientMessageClientMessageZMClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidCalled: Bool {
        return addClientMessageClientMessageZMClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidCallsCount > 0
    }
    public var addClientMessageClientMessageZMClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidReceivedArguments: (clientMessage: ZMClientMessage, isNewMessage: Bool, genericMessage: GenericMessage, conversation: ZMConversation, senderID: UUID, senderDomain: String)?
    public var addClientMessageClientMessageZMClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidReceivedInvocations: [(clientMessage: ZMClientMessage, isNewMessage: Bool, genericMessage: GenericMessage, conversation: ZMConversation, senderID: UUID, senderDomain: String)] = []
    public var addClientMessageClientMessageZMClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidClosure: ((ZMClientMessage, Bool, GenericMessage, ZMConversation, UUID, String) async -> Void)?

    public func addClientMessage(_ clientMessage: ZMClientMessage, isNewMessage: Bool, genericMessage: GenericMessage, conversation: ZMConversation, senderID: UUID, senderDomain: String) async {
        addClientMessageClientMessageZMClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidCallsCount += 1
        addClientMessageClientMessageZMClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidReceivedArguments = (clientMessage: clientMessage, isNewMessage: isNewMessage, genericMessage: genericMessage, conversation: conversation, senderID: senderID, senderDomain: senderDomain)
        addClientMessageClientMessageZMClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidReceivedInvocations.append((clientMessage: clientMessage, isNewMessage: isNewMessage, genericMessage: genericMessage, conversation: conversation, senderID: senderID, senderDomain: senderDomain))
        await addClientMessageClientMessageZMClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidClosure?(clientMessage, isNewMessage, genericMessage, conversation, senderID, senderDomain)
    }

    //MARK: - addAssetClientMessage

    public var addAssetClientMessageAssetClientMessageZMAssetClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidCallsCount = 0
    public var addAssetClientMessageAssetClientMessageZMAssetClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidCalled: Bool {
        return addAssetClientMessageAssetClientMessageZMAssetClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidCallsCount > 0
    }
    public var addAssetClientMessageAssetClientMessageZMAssetClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidReceivedArguments: (assetClientMessage: ZMAssetClientMessage, isNewMessage: Bool, genericMessage: GenericMessage, conversation: ZMConversation, senderID: UUID, senderDomain: String)?
    public var addAssetClientMessageAssetClientMessageZMAssetClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidReceivedInvocations: [(assetClientMessage: ZMAssetClientMessage, isNewMessage: Bool, genericMessage: GenericMessage, conversation: ZMConversation, senderID: UUID, senderDomain: String)] = []
    public var addAssetClientMessageAssetClientMessageZMAssetClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidClosure: ((ZMAssetClientMessage, Bool, GenericMessage, ZMConversation, UUID, String) async -> Void)?

    public func addAssetClientMessage(_ assetClientMessage: ZMAssetClientMessage, isNewMessage: Bool, genericMessage: GenericMessage, conversation: ZMConversation, senderID: UUID, senderDomain: String) async {
        addAssetClientMessageAssetClientMessageZMAssetClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidCallsCount += 1
        addAssetClientMessageAssetClientMessageZMAssetClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidReceivedArguments = (assetClientMessage: assetClientMessage, isNewMessage: isNewMessage, genericMessage: genericMessage, conversation: conversation, senderID: senderID, senderDomain: senderDomain)
        addAssetClientMessageAssetClientMessageZMAssetClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidReceivedInvocations.append((assetClientMessage: assetClientMessage, isNewMessage: isNewMessage, genericMessage: genericMessage, conversation: conversation, senderID: senderID, senderDomain: senderDomain))
        await addAssetClientMessageAssetClientMessageZMAssetClientMessageIsNewMessageBoolGenericMessageGenericMessageConversationZMConversationSenderIDUUIDSenderDomainStringVoidClosure?(assetClientMessage, isNewMessage, genericMessage, conversation, senderID, senderDomain)
    }

    //MARK: - canAddMessage

    public var canAddMessageConversationZMConversationSenderIDUUIDBoolCallsCount = 0
    public var canAddMessageConversationZMConversationSenderIDUUIDBoolCalled: Bool {
        return canAddMessageConversationZMConversationSenderIDUUIDBoolCallsCount > 0
    }
    public var canAddMessageConversationZMConversationSenderIDUUIDBoolReceivedArguments: (conversation: ZMConversation, senderID: UUID)?
    public var canAddMessageConversationZMConversationSenderIDUUIDBoolReceivedInvocations: [(conversation: ZMConversation, senderID: UUID)] = []
    public var canAddMessageConversationZMConversationSenderIDUUIDBoolReturnValue: Bool!
    public var canAddMessageConversationZMConversationSenderIDUUIDBoolClosure: ((ZMConversation, UUID) async -> Bool)?

    public func canAddMessage(conversation: ZMConversation, senderID: UUID) async -> Bool {
        canAddMessageConversationZMConversationSenderIDUUIDBoolCallsCount += 1
        canAddMessageConversationZMConversationSenderIDUUIDBoolReceivedArguments = (conversation: conversation, senderID: senderID)
        canAddMessageConversationZMConversationSenderIDUUIDBoolReceivedInvocations.append((conversation: conversation, senderID: senderID))
        if let canAddMessageConversationZMConversationSenderIDUUIDBoolClosure = canAddMessageConversationZMConversationSenderIDUUIDBoolClosure {
            return await canAddMessageConversationZMConversationSenderIDUUIDBoolClosure(conversation, senderID)
        } else {
            return canAddMessageConversationZMConversationSenderIDUUIDBoolReturnValue
        }
    }

    //MARK: - deleteMessageForSelf

    public var deleteMessageForSelfHiddenMessageMessageHideInConversationZMConversationVoidCallsCount = 0
    public var deleteMessageForSelfHiddenMessageMessageHideInConversationZMConversationVoidCalled: Bool {
        return deleteMessageForSelfHiddenMessageMessageHideInConversationZMConversationVoidCallsCount > 0
    }
    public var deleteMessageForSelfHiddenMessageMessageHideInConversationZMConversationVoidReceivedArguments: (hiddenMessage: MessageHide, conversation: ZMConversation)?
    public var deleteMessageForSelfHiddenMessageMessageHideInConversationZMConversationVoidReceivedInvocations: [(hiddenMessage: MessageHide, conversation: ZMConversation)] = []
    public var deleteMessageForSelfHiddenMessageMessageHideInConversationZMConversationVoidClosure: ((MessageHide, ZMConversation) async -> Void)?

    public func deleteMessageForSelf(_ hiddenMessage: MessageHide, in conversation: ZMConversation) async {
        deleteMessageForSelfHiddenMessageMessageHideInConversationZMConversationVoidCallsCount += 1
        deleteMessageForSelfHiddenMessageMessageHideInConversationZMConversationVoidReceivedArguments = (hiddenMessage: hiddenMessage, conversation: conversation)
        deleteMessageForSelfHiddenMessageMessageHideInConversationZMConversationVoidReceivedInvocations.append((hiddenMessage: hiddenMessage, conversation: conversation))
        await deleteMessageForSelfHiddenMessageMessageHideInConversationZMConversationVoidClosure?(hiddenMessage, conversation)
    }

    //MARK: - deleteMessageForEveryone

    public var deleteMessageForEveryoneDeletedMessageMessageDeleteInConversationZMConversationSenderIDUUIDVoidCallsCount = 0
    public var deleteMessageForEveryoneDeletedMessageMessageDeleteInConversationZMConversationSenderIDUUIDVoidCalled: Bool {
        return deleteMessageForEveryoneDeletedMessageMessageDeleteInConversationZMConversationSenderIDUUIDVoidCallsCount > 0
    }
    public var deleteMessageForEveryoneDeletedMessageMessageDeleteInConversationZMConversationSenderIDUUIDVoidReceivedArguments: (deletedMessage: MessageDelete, conversation: ZMConversation, senderID: UUID)?
    public var deleteMessageForEveryoneDeletedMessageMessageDeleteInConversationZMConversationSenderIDUUIDVoidReceivedInvocations: [(deletedMessage: MessageDelete, conversation: ZMConversation, senderID: UUID)] = []
    public var deleteMessageForEveryoneDeletedMessageMessageDeleteInConversationZMConversationSenderIDUUIDVoidClosure: ((MessageDelete, ZMConversation, UUID) async -> Void)?

    public func deleteMessageForEveryone(_ deletedMessage: MessageDelete, in conversation: ZMConversation, senderID: UUID) async {
        deleteMessageForEveryoneDeletedMessageMessageDeleteInConversationZMConversationSenderIDUUIDVoidCallsCount += 1
        deleteMessageForEveryoneDeletedMessageMessageDeleteInConversationZMConversationSenderIDUUIDVoidReceivedArguments = (deletedMessage: deletedMessage, conversation: conversation, senderID: senderID)
        deleteMessageForEveryoneDeletedMessageMessageDeleteInConversationZMConversationSenderIDUUIDVoidReceivedInvocations.append((deletedMessage: deletedMessage, conversation: conversation, senderID: senderID))
        await deleteMessageForEveryoneDeletedMessageMessageDeleteInConversationZMConversationSenderIDUUIDVoidClosure?(deletedMessage, conversation, senderID)
    }

    //MARK: - addMessageReaction

    public var addMessageReactionMessageReactionGenericMessageProtocolReactionInConversationZMConversationSenderIDUUIDDateDateVoidCallsCount = 0
    public var addMessageReactionMessageReactionGenericMessageProtocolReactionInConversationZMConversationSenderIDUUIDDateDateVoidCalled: Bool {
        return addMessageReactionMessageReactionGenericMessageProtocolReactionInConversationZMConversationSenderIDUUIDDateDateVoidCallsCount > 0
    }
    public var addMessageReactionMessageReactionGenericMessageProtocolReactionInConversationZMConversationSenderIDUUIDDateDateVoidReceivedArguments: (messageReaction: GenericMessageProtocol.Reaction, conversation: ZMConversation, senderID: UUID, date: Date)?
    public var addMessageReactionMessageReactionGenericMessageProtocolReactionInConversationZMConversationSenderIDUUIDDateDateVoidReceivedInvocations: [(messageReaction: GenericMessageProtocol.Reaction, conversation: ZMConversation, senderID: UUID, date: Date)] = []
    public var addMessageReactionMessageReactionGenericMessageProtocolReactionInConversationZMConversationSenderIDUUIDDateDateVoidClosure: ((GenericMessageProtocol.Reaction, ZMConversation, UUID, Date) async -> Void)?

    public func addMessageReaction(_ messageReaction: GenericMessageProtocol.Reaction, in conversation: ZMConversation, senderID: UUID, date: Date) async {
        addMessageReactionMessageReactionGenericMessageProtocolReactionInConversationZMConversationSenderIDUUIDDateDateVoidCallsCount += 1
        addMessageReactionMessageReactionGenericMessageProtocolReactionInConversationZMConversationSenderIDUUIDDateDateVoidReceivedArguments = (messageReaction: messageReaction, conversation: conversation, senderID: senderID, date: date)
        addMessageReactionMessageReactionGenericMessageProtocolReactionInConversationZMConversationSenderIDUUIDDateDateVoidReceivedInvocations.append((messageReaction: messageReaction, conversation: conversation, senderID: senderID, date: date))
        await addMessageReactionMessageReactionGenericMessageProtocolReactionInConversationZMConversationSenderIDUUIDDateDateVoidClosure?(messageReaction, conversation, senderID, date)
    }

    //MARK: - addMessageConfirmation

    public var addMessageConfirmationConfirmationGenericMessageProtocolConfirmationInConversationZMConversationSenderIDUUIDSenderDomainStringDateDateVoidCallsCount = 0
    public var addMessageConfirmationConfirmationGenericMessageProtocolConfirmationInConversationZMConversationSenderIDUUIDSenderDomainStringDateDateVoidCalled: Bool {
        return addMessageConfirmationConfirmationGenericMessageProtocolConfirmationInConversationZMConversationSenderIDUUIDSenderDomainStringDateDateVoidCallsCount > 0
    }
    public var addMessageConfirmationConfirmationGenericMessageProtocolConfirmationInConversationZMConversationSenderIDUUIDSenderDomainStringDateDateVoidReceivedArguments: (confirmation: GenericMessageProtocol.Confirmation, conversation: ZMConversation, senderID: UUID, senderDomain: String, date: Date)?
    public var addMessageConfirmationConfirmationGenericMessageProtocolConfirmationInConversationZMConversationSenderIDUUIDSenderDomainStringDateDateVoidReceivedInvocations: [(confirmation: GenericMessageProtocol.Confirmation, conversation: ZMConversation, senderID: UUID, senderDomain: String, date: Date)] = []
    public var addMessageConfirmationConfirmationGenericMessageProtocolConfirmationInConversationZMConversationSenderIDUUIDSenderDomainStringDateDateVoidClosure: ((GenericMessageProtocol.Confirmation, ZMConversation, UUID, String, Date) async -> Void)?

    public func addMessageConfirmation(_ confirmation: GenericMessageProtocol.Confirmation, in conversation: ZMConversation, senderID: UUID, senderDomain: String, date: Date) async {
        addMessageConfirmationConfirmationGenericMessageProtocolConfirmationInConversationZMConversationSenderIDUUIDSenderDomainStringDateDateVoidCallsCount += 1
        addMessageConfirmationConfirmationGenericMessageProtocolConfirmationInConversationZMConversationSenderIDUUIDSenderDomainStringDateDateVoidReceivedArguments = (confirmation: confirmation, conversation: conversation, senderID: senderID, senderDomain: senderDomain, date: date)
        addMessageConfirmationConfirmationGenericMessageProtocolConfirmationInConversationZMConversationSenderIDUUIDSenderDomainStringDateDateVoidReceivedInvocations.append((confirmation: confirmation, conversation: conversation, senderID: senderID, senderDomain: senderDomain, date: date))
        await addMessageConfirmationConfirmationGenericMessageProtocolConfirmationInConversationZMConversationSenderIDUUIDSenderDomainStringDateDateVoidClosure?(confirmation, conversation, senderID, senderDomain, date)
    }

    //MARK: - updateButtonStates

    public var updateButtonStatesButtonActionConfirmationButtonActionConfirmationInConversationZMConversationVoidCallsCount = 0
    public var updateButtonStatesButtonActionConfirmationButtonActionConfirmationInConversationZMConversationVoidCalled: Bool {
        return updateButtonStatesButtonActionConfirmationButtonActionConfirmationInConversationZMConversationVoidCallsCount > 0
    }
    public var updateButtonStatesButtonActionConfirmationButtonActionConfirmationInConversationZMConversationVoidReceivedArguments: (buttonActionConfirmation: ButtonActionConfirmation, conversation: ZMConversation)?
    public var updateButtonStatesButtonActionConfirmationButtonActionConfirmationInConversationZMConversationVoidReceivedInvocations: [(buttonActionConfirmation: ButtonActionConfirmation, conversation: ZMConversation)] = []
    public var updateButtonStatesButtonActionConfirmationButtonActionConfirmationInConversationZMConversationVoidClosure: ((ButtonActionConfirmation, ZMConversation) async -> Void)?

    public func updateButtonStates(_ buttonActionConfirmation: ButtonActionConfirmation, in conversation: ZMConversation) async {
        updateButtonStatesButtonActionConfirmationButtonActionConfirmationInConversationZMConversationVoidCallsCount += 1
        updateButtonStatesButtonActionConfirmationButtonActionConfirmationInConversationZMConversationVoidReceivedArguments = (buttonActionConfirmation: buttonActionConfirmation, conversation: conversation)
        updateButtonStatesButtonActionConfirmationButtonActionConfirmationInConversationZMConversationVoidReceivedInvocations.append((buttonActionConfirmation: buttonActionConfirmation, conversation: conversation))
        await updateButtonStatesButtonActionConfirmationButtonActionConfirmationInConversationZMConversationVoidClosure?(buttonActionConfirmation, conversation)
    }

    //MARK: - editMessage

    public var editMessageMessageEditMessageEditInConversationZMConversationSenderIDUUIDGenericMessageGenericMessageDateDateVoidCallsCount = 0
    public var editMessageMessageEditMessageEditInConversationZMConversationSenderIDUUIDGenericMessageGenericMessageDateDateVoidCalled: Bool {
        return editMessageMessageEditMessageEditInConversationZMConversationSenderIDUUIDGenericMessageGenericMessageDateDateVoidCallsCount > 0
    }
    public var editMessageMessageEditMessageEditInConversationZMConversationSenderIDUUIDGenericMessageGenericMessageDateDateVoidReceivedArguments: (messageEdit: MessageEdit, conversation: ZMConversation, senderID: UUID, genericMessage: GenericMessage, date: Date)?
    public var editMessageMessageEditMessageEditInConversationZMConversationSenderIDUUIDGenericMessageGenericMessageDateDateVoidReceivedInvocations: [(messageEdit: MessageEdit, conversation: ZMConversation, senderID: UUID, genericMessage: GenericMessage, date: Date)] = []
    public var editMessageMessageEditMessageEditInConversationZMConversationSenderIDUUIDGenericMessageGenericMessageDateDateVoidClosure: ((MessageEdit, ZMConversation, UUID, GenericMessage, Date) async -> Void)?

    public func editMessage(_ messageEdit: MessageEdit, in conversation: ZMConversation, senderID: UUID, genericMessage: GenericMessage, date: Date) async {
        editMessageMessageEditMessageEditInConversationZMConversationSenderIDUUIDGenericMessageGenericMessageDateDateVoidCallsCount += 1
        editMessageMessageEditMessageEditInConversationZMConversationSenderIDUUIDGenericMessageGenericMessageDateDateVoidReceivedArguments = (messageEdit: messageEdit, conversation: conversation, senderID: senderID, genericMessage: genericMessage, date: date)
        editMessageMessageEditMessageEditInConversationZMConversationSenderIDUUIDGenericMessageGenericMessageDateDateVoidReceivedInvocations.append((messageEdit: messageEdit, conversation: conversation, senderID: senderID, genericMessage: genericMessage, date: date))
        await editMessageMessageEditMessageEditInConversationZMConversationSenderIDUUIDGenericMessageGenericMessageDateDateVoidClosure?(messageEdit, conversation, senderID, genericMessage, date)
    }

    //MARK: - fetchMessage

    public var fetchMessageIdUUIDConversationIDUUIDConversationDomainStringZMOTRMessageCallsCount = 0
    public var fetchMessageIdUUIDConversationIDUUIDConversationDomainStringZMOTRMessageCalled: Bool {
        return fetchMessageIdUUIDConversationIDUUIDConversationDomainStringZMOTRMessageCallsCount > 0
    }
    public var fetchMessageIdUUIDConversationIDUUIDConversationDomainStringZMOTRMessageReceivedArguments: (id: UUID?, conversationID: UUID, conversationDomain: String?)?
    public var fetchMessageIdUUIDConversationIDUUIDConversationDomainStringZMOTRMessageReceivedInvocations: [(id: UUID?, conversationID: UUID, conversationDomain: String?)] = []
    public var fetchMessageIdUUIDConversationIDUUIDConversationDomainStringZMOTRMessageReturnValue: ZMOTRMessage?
    public var fetchMessageIdUUIDConversationIDUUIDConversationDomainStringZMOTRMessageClosure: ((UUID?, UUID, String?) async -> ZMOTRMessage?)?

    public func fetchMessage(id: UUID?, conversationID: UUID, conversationDomain: String?) async -> ZMOTRMessage? {
        fetchMessageIdUUIDConversationIDUUIDConversationDomainStringZMOTRMessageCallsCount += 1
        fetchMessageIdUUIDConversationIDUUIDConversationDomainStringZMOTRMessageReceivedArguments = (id: id, conversationID: conversationID, conversationDomain: conversationDomain)
        fetchMessageIdUUIDConversationIDUUIDConversationDomainStringZMOTRMessageReceivedInvocations.append((id: id, conversationID: conversationID, conversationDomain: conversationDomain))
        if let fetchMessageIdUUIDConversationIDUUIDConversationDomainStringZMOTRMessageClosure = fetchMessageIdUUIDConversationIDUUIDConversationDomainStringZMOTRMessageClosure {
            return await fetchMessageIdUUIDConversationIDUUIDConversationDomainStringZMOTRMessageClosure(id, conversationID, conversationDomain)
        } else {
            return fetchMessageIdUUIDConversationIDUUIDConversationDomainStringZMOTRMessageReturnValue
        }
    }

    //MARK: - isMessageMentioningSelf

    public var isMessageMentioningSelfTextTextBoolCallsCount = 0
    public var isMessageMentioningSelfTextTextBoolCalled: Bool {
        return isMessageMentioningSelfTextTextBoolCallsCount > 0
    }
    public var isMessageMentioningSelfTextTextBoolReceivedText: (Text)?
    public var isMessageMentioningSelfTextTextBoolReceivedInvocations: [(Text)] = []
    public var isMessageMentioningSelfTextTextBoolReturnValue: Bool!
    public var isMessageMentioningSelfTextTextBoolClosure: ((Text) async -> Bool)?

    public func isMessageMentioningSelf(text: Text) async -> Bool {
        isMessageMentioningSelfTextTextBoolCallsCount += 1
        isMessageMentioningSelfTextTextBoolReceivedText = text
        isMessageMentioningSelfTextTextBoolReceivedInvocations.append(text)
        if let isMessageMentioningSelfTextTextBoolClosure = isMessageMentioningSelfTextTextBoolClosure {
            return await isMessageMentioningSelfTextTextBoolClosure(text)
        } else {
            return isMessageMentioningSelfTextTextBoolReturnValue
        }
    }

    //MARK: - isMessageQuotingSelf

    public var isMessageQuotingSelfQuotedMessageZMOTRMessageBoolCallsCount = 0
    public var isMessageQuotingSelfQuotedMessageZMOTRMessageBoolCalled: Bool {
        return isMessageQuotingSelfQuotedMessageZMOTRMessageBoolCallsCount > 0
    }
    public var isMessageQuotingSelfQuotedMessageZMOTRMessageBoolReceivedQuotedMessage: (ZMOTRMessage)?
    public var isMessageQuotingSelfQuotedMessageZMOTRMessageBoolReceivedInvocations: [(ZMOTRMessage)?] = []
    public var isMessageQuotingSelfQuotedMessageZMOTRMessageBoolReturnValue: Bool!
    public var isMessageQuotingSelfQuotedMessageZMOTRMessageBoolClosure: ((ZMOTRMessage?) async -> Bool)?

    public func isMessageQuotingSelf(quotedMessage: ZMOTRMessage?) async -> Bool {
        isMessageQuotingSelfQuotedMessageZMOTRMessageBoolCallsCount += 1
        isMessageQuotingSelfQuotedMessageZMOTRMessageBoolReceivedQuotedMessage = quotedMessage
        isMessageQuotingSelfQuotedMessageZMOTRMessageBoolReceivedInvocations.append(quotedMessage)
        if let isMessageQuotingSelfQuotedMessageZMOTRMessageBoolClosure = isMessageQuotingSelfQuotedMessageZMOTRMessageBoolClosure {
            return await isMessageQuotingSelfQuotedMessageZMOTRMessageBoolClosure(quotedMessage)
        } else {
            return isMessageQuotingSelfQuotedMessageZMOTRMessageBoolReturnValue
        }
    }


}
public class MessageRepositoryProtocolMock: MessageRepositoryProtocol {

    public init() {}



    //MARK: - addSystemMessage

    public var addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidCallsCount = 0
    public var addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidCalled: Bool {
        return addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidCallsCount > 0
    }
    public var addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidReceivedArguments: (messageType: SystemMessageType, conversationID: UUID, conversationDomain: String?)?
    public var addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidReceivedInvocations: [(messageType: SystemMessageType, conversationID: UUID, conversationDomain: String?)] = []
    public var addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidClosure: ((SystemMessageType, UUID, String?) async -> Void)?

    public func addSystemMessage(messageType: SystemMessageType, conversationID: UUID, conversationDomain: String?) async {
        addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidCallsCount += 1
        addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidReceivedArguments = (messageType: messageType, conversationID: conversationID, conversationDomain: conversationDomain)
        addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidReceivedInvocations.append((messageType: messageType, conversationID: conversationID, conversationDomain: conversationDomain))
        await addSystemMessageMessageTypeSystemMessageTypeConversationIDUUIDConversationDomainStringVoidClosure?(messageType, conversationID, conversationDomain)
    }


}
public class OneOnOneResolverProtocolMock: OneOnOneResolverProtocol {

    public init() {}



    //MARK: - resolveOneOnOneConversation

    public var resolveOneOnOneConversationWithUserIDWireDataModelQualifiedIDVoidThrowableError: (any Error)?
    public var resolveOneOnOneConversationWithUserIDWireDataModelQualifiedIDVoidCallsCount = 0
    public var resolveOneOnOneConversationWithUserIDWireDataModelQualifiedIDVoidCalled: Bool {
        return resolveOneOnOneConversationWithUserIDWireDataModelQualifiedIDVoidCallsCount > 0
    }
    public var resolveOneOnOneConversationWithUserIDWireDataModelQualifiedIDVoidReceivedUserID: (WireDataModel.QualifiedID)?
    public var resolveOneOnOneConversationWithUserIDWireDataModelQualifiedIDVoidReceivedInvocations: [(WireDataModel.QualifiedID)] = []
    public var resolveOneOnOneConversationWithUserIDWireDataModelQualifiedIDVoidClosure: ((WireDataModel.QualifiedID) async throws -> Void)?

    public func resolveOneOnOneConversation(with userID: WireDataModel.QualifiedID) async throws {
        resolveOneOnOneConversationWithUserIDWireDataModelQualifiedIDVoidCallsCount += 1
        resolveOneOnOneConversationWithUserIDWireDataModelQualifiedIDVoidReceivedUserID = userID
        resolveOneOnOneConversationWithUserIDWireDataModelQualifiedIDVoidReceivedInvocations.append(userID)
        if let error = resolveOneOnOneConversationWithUserIDWireDataModelQualifiedIDVoidThrowableError {
            throw error
        }
        try await resolveOneOnOneConversationWithUserIDWireDataModelQualifiedIDVoidClosure?(userID)
    }

    //MARK: - resolveAllOneOnOneConversations

    public var resolveAllOneOnOneConversationsVoidThrowableError: (any Error)?
    public var resolveAllOneOnOneConversationsVoidCallsCount = 0
    public var resolveAllOneOnOneConversationsVoidCalled: Bool {
        return resolveAllOneOnOneConversationsVoidCallsCount > 0
    }
    public var resolveAllOneOnOneConversationsVoidClosure: (() async throws -> Void)?

    public func resolveAllOneOnOneConversations() async throws {
        resolveAllOneOnOneConversationsVoidCallsCount += 1
        if let error = resolveAllOneOnOneConversationsVoidThrowableError {
            throw error
        }
        try await resolveAllOneOnOneConversationsVoidClosure?()
    }


}
class ProcessNotificationUseCaseProtocolMock: ProcessNotificationUseCaseProtocol {




    //MARK: - invoke

    var invokeRequestUNNotificationRequestNotificationPayloadThrowableError: (any Error)?
    var invokeRequestUNNotificationRequestNotificationPayloadCallsCount = 0
    var invokeRequestUNNotificationRequestNotificationPayloadCalled: Bool {
        return invokeRequestUNNotificationRequestNotificationPayloadCallsCount > 0
    }
    var invokeRequestUNNotificationRequestNotificationPayloadReceivedRequest: (UNNotificationRequest)?
    var invokeRequestUNNotificationRequestNotificationPayloadReceivedInvocations: [(UNNotificationRequest)] = []
    var invokeRequestUNNotificationRequestNotificationPayloadReturnValue: NotificationPayload!
    var invokeRequestUNNotificationRequestNotificationPayloadClosure: ((UNNotificationRequest) async throws -> NotificationPayload)?

    func invoke(request: UNNotificationRequest) async throws -> NotificationPayload {
        invokeRequestUNNotificationRequestNotificationPayloadCallsCount += 1
        invokeRequestUNNotificationRequestNotificationPayloadReceivedRequest = request
        invokeRequestUNNotificationRequestNotificationPayloadReceivedInvocations.append(request)
        if let error = invokeRequestUNNotificationRequestNotificationPayloadThrowableError {
            throw error
        }
        if let invokeRequestUNNotificationRequestNotificationPayloadClosure = invokeRequestUNNotificationRequestNotificationPayloadClosure {
            return try await invokeRequestUNNotificationRequestNotificationPayloadClosure(request)
        } else {
            return invokeRequestUNNotificationRequestNotificationPayloadReturnValue
        }
    }


}
class ProteusMessageDecryptorProtocolMock: ProteusMessageDecryptorProtocol {




    //MARK: - decryptedEventData

    var decryptedEventDataFromEventDataConversationProteusMessageAddEventContextCoreCryptoContextProtocolConversationProteusMessageAddEventThrowableError: (any Error)?
    var decryptedEventDataFromEventDataConversationProteusMessageAddEventContextCoreCryptoContextProtocolConversationProteusMessageAddEventCallsCount = 0
    var decryptedEventDataFromEventDataConversationProteusMessageAddEventContextCoreCryptoContextProtocolConversationProteusMessageAddEventCalled: Bool {
        return decryptedEventDataFromEventDataConversationProteusMessageAddEventContextCoreCryptoContextProtocolConversationProteusMessageAddEventCallsCount > 0
    }
    var decryptedEventDataFromEventDataConversationProteusMessageAddEventContextCoreCryptoContextProtocolConversationProteusMessageAddEventReceivedArguments: (eventData: ConversationProteusMessageAddEvent, context: CoreCryptoContextProtocol?)?
    var decryptedEventDataFromEventDataConversationProteusMessageAddEventContextCoreCryptoContextProtocolConversationProteusMessageAddEventReceivedInvocations: [(eventData: ConversationProteusMessageAddEvent, context: CoreCryptoContextProtocol?)] = []
    var decryptedEventDataFromEventDataConversationProteusMessageAddEventContextCoreCryptoContextProtocolConversationProteusMessageAddEventReturnValue: ConversationProteusMessageAddEvent!
    var decryptedEventDataFromEventDataConversationProteusMessageAddEventContextCoreCryptoContextProtocolConversationProteusMessageAddEventClosure: ((ConversationProteusMessageAddEvent, CoreCryptoContextProtocol?) async throws -> ConversationProteusMessageAddEvent)?

    func decryptedEventData(from eventData: ConversationProteusMessageAddEvent, context: CoreCryptoContextProtocol?) async throws -> ConversationProteusMessageAddEvent {
        decryptedEventDataFromEventDataConversationProteusMessageAddEventContextCoreCryptoContextProtocolConversationProteusMessageAddEventCallsCount += 1
        decryptedEventDataFromEventDataConversationProteusMessageAddEventContextCoreCryptoContextProtocolConversationProteusMessageAddEventReceivedArguments = (eventData: eventData, context: context)
        decryptedEventDataFromEventDataConversationProteusMessageAddEventContextCoreCryptoContextProtocolConversationProteusMessageAddEventReceivedInvocations.append((eventData: eventData, context: context))
        if let error = decryptedEventDataFromEventDataConversationProteusMessageAddEventContextCoreCryptoContextProtocolConversationProteusMessageAddEventThrowableError {
            throw error
        }
        if let decryptedEventDataFromEventDataConversationProteusMessageAddEventContextCoreCryptoContextProtocolConversationProteusMessageAddEventClosure = decryptedEventDataFromEventDataConversationProteusMessageAddEventContextCoreCryptoContextProtocolConversationProteusMessageAddEventClosure {
            return try await decryptedEventDataFromEventDataConversationProteusMessageAddEventContextCoreCryptoContextProtocolConversationProteusMessageAddEventClosure(eventData, context)
        } else {
            return decryptedEventDataFromEventDataConversationProteusMessageAddEventContextCoreCryptoContextProtocolConversationProteusMessageAddEventReturnValue
        }
    }


}
public class PullAllConversationsSyncProtocolMock: PullAllConversationsSyncProtocol {

    public init() {}



    //MARK: - pull

    public var pullVoidThrowableError: (any Error)?
    public var pullVoidCallsCount = 0
    public var pullVoidCalled: Bool {
        return pullVoidCallsCount > 0
    }
    public var pullVoidClosure: (() async throws -> Void)?

    public func pull() async throws {
        pullVoidCallsCount += 1
        if let error = pullVoidThrowableError {
            throw error
        }
        try await pullVoidClosure?()
    }


}
class PullAllFeatureConfigsSyncProtocolMock: PullAllFeatureConfigsSyncProtocol {




    //MARK: - pull

    var pullVoidThrowableError: (any Error)?
    var pullVoidCallsCount = 0
    var pullVoidCalled: Bool {
        return pullVoidCallsCount > 0
    }
    var pullVoidClosure: (() async throws -> Void)?

    func pull() async throws {
        pullVoidCallsCount += 1
        if let error = pullVoidThrowableError {
            throw error
        }
        try await pullVoidClosure?()
    }


}
class PullConversationLabelsSyncProtocolMock: PullConversationLabelsSyncProtocol {




    //MARK: - pull

    var pullVoidThrowableError: (any Error)?
    var pullVoidCallsCount = 0
    var pullVoidCalled: Bool {
        return pullVoidCallsCount > 0
    }
    var pullVoidClosure: (() async throws -> Void)?

    func pull() async throws {
        pullVoidCallsCount += 1
        if let error = pullVoidThrowableError {
            throw error
        }
        try await pullVoidClosure?()
    }


}
class PullEventsUseCaseProtocolMock: PullEventsUseCaseProtocol {




    //MARK: - invoke

    var invokeAsyncStreamUpdateEventThrowableError: (any Error)?
    var invokeAsyncStreamUpdateEventCallsCount = 0
    var invokeAsyncStreamUpdateEventCalled: Bool {
        return invokeAsyncStreamUpdateEventCallsCount > 0
    }
    var invokeAsyncStreamUpdateEventReturnValue: AsyncStream<[UpdateEvent]>!
    var invokeAsyncStreamUpdateEventClosure: (() async throws -> AsyncStream<[UpdateEvent]>)?

    func invoke() async throws -> AsyncStream<[UpdateEvent]> {
        invokeAsyncStreamUpdateEventCallsCount += 1
        if let error = invokeAsyncStreamUpdateEventThrowableError {
            throw error
        }
        if let invokeAsyncStreamUpdateEventClosure = invokeAsyncStreamUpdateEventClosure {
            return try await invokeAsyncStreamUpdateEventClosure()
        } else {
            return invokeAsyncStreamUpdateEventReturnValue
        }
    }


}
class PullKnownUsersSyncProtocolMock: PullKnownUsersSyncProtocol {




    //MARK: - pull

    var pullVoidThrowableError: (any Error)?
    var pullVoidCallsCount = 0
    var pullVoidCalled: Bool {
        return pullVoidCallsCount > 0
    }
    var pullVoidClosure: (() async throws -> Void)?

    func pull() async throws {
        pullVoidCallsCount += 1
        if let error = pullVoidThrowableError {
            throw error
        }
        try await pullVoidClosure?()
    }


}
public class PullLastUpdateEventIDSyncProtocolMock: PullLastUpdateEventIDSyncProtocol {

    public init() {}



    //MARK: - pull

    public var pullVoidThrowableError: (any Error)?
    public var pullVoidCallsCount = 0
    public var pullVoidCalled: Bool {
        return pullVoidCallsCount > 0
    }
    public var pullVoidClosure: (() async throws -> Void)?

    public func pull() async throws {
        pullVoidCallsCount += 1
        if let error = pullVoidThrowableError {
            throw error
        }
        try await pullVoidClosure?()
    }


}
public class PullMLSOneOnOneSyncProtocolMock: PullMLSOneOnOneSyncProtocol {

    public init() {}



    //MARK: - pull

    public var pullUserIDUUIDUserDomainStringMLSGroupIDThrowableError: (any Error)?
    public var pullUserIDUUIDUserDomainStringMLSGroupIDCallsCount = 0
    public var pullUserIDUUIDUserDomainStringMLSGroupIDCalled: Bool {
        return pullUserIDUUIDUserDomainStringMLSGroupIDCallsCount > 0
    }
    public var pullUserIDUUIDUserDomainStringMLSGroupIDReceivedArguments: (userID: UUID, userDomain: String)?
    public var pullUserIDUUIDUserDomainStringMLSGroupIDReceivedInvocations: [(userID: UUID, userDomain: String)] = []
    public var pullUserIDUUIDUserDomainStringMLSGroupIDReturnValue: MLSGroupID!
    public var pullUserIDUUIDUserDomainStringMLSGroupIDClosure: ((UUID, String) async throws -> MLSGroupID)?

    public func pull(userID: UUID, userDomain: String) async throws -> MLSGroupID {
        pullUserIDUUIDUserDomainStringMLSGroupIDCallsCount += 1
        pullUserIDUUIDUserDomainStringMLSGroupIDReceivedArguments = (userID: userID, userDomain: userDomain)
        pullUserIDUUIDUserDomainStringMLSGroupIDReceivedInvocations.append((userID: userID, userDomain: userDomain))
        if let error = pullUserIDUUIDUserDomainStringMLSGroupIDThrowableError {
            throw error
        }
        if let pullUserIDUUIDUserDomainStringMLSGroupIDClosure = pullUserIDUUIDUserDomainStringMLSGroupIDClosure {
            return try await pullUserIDUUIDUserDomainStringMLSGroupIDClosure(userID, userDomain)
        } else {
            return pullUserIDUUIDUserDomainStringMLSGroupIDReturnValue
        }
    }


}
public class PullMLSStatusSyncProtocolMock: PullMLSStatusSyncProtocol {

    public init() {}



    //MARK: - pull

    public var pullVoidThrowableError: (any Error)?
    public var pullVoidCallsCount = 0
    public var pullVoidCalled: Bool {
        return pullVoidCallsCount > 0
    }
    public var pullVoidClosure: (() async throws -> Void)?

    public func pull() async throws {
        pullVoidCallsCount += 1
        if let error = pullVoidThrowableError {
            throw error
        }
        try await pullVoidClosure?()
    }


}
public class PullPendingUpdateEventsSyncProtocolMock: PullPendingUpdateEventsSyncProtocol {

    public init() {}



    //MARK: - pull

    public var pullAsyncStreamUpdateEventThrowableError: (any Error)?
    public var pullAsyncStreamUpdateEventCallsCount = 0
    public var pullAsyncStreamUpdateEventCalled: Bool {
        return pullAsyncStreamUpdateEventCallsCount > 0
    }
    public var pullAsyncStreamUpdateEventReturnValue: AsyncStream<[UpdateEvent]>!
    public var pullAsyncStreamUpdateEventClosure: (() async throws -> AsyncStream<[UpdateEvent]>)?

    @discardableResult
    public func pull() async throws -> AsyncStream<[UpdateEvent]> {
        pullAsyncStreamUpdateEventCallsCount += 1
        if let error = pullAsyncStreamUpdateEventThrowableError {
            throw error
        }
        if let pullAsyncStreamUpdateEventClosure = pullAsyncStreamUpdateEventClosure {
            return try await pullAsyncStreamUpdateEventClosure()
        } else {
            return pullAsyncStreamUpdateEventReturnValue
        }
    }


}
public class PullPendingUpdateEventsSyncV2ProtocolMock: PullPendingUpdateEventsSyncV2Protocol {

    public init() {}



    //MARK: - pull

    public var pullVoidThrowableError: (any Error)?
    public var pullVoidCallsCount = 0
    public var pullVoidCalled: Bool {
        return pullVoidCallsCount > 0
    }
    public var pullVoidClosure: (() async throws -> Void)?

    public func pull() async throws {
        pullVoidCallsCount += 1
        if let error = pullVoidThrowableError {
            throw error
        }
        try await pullVoidClosure?()
    }


}
public class PullResourcesSyncProtocolMock: PullResourcesSyncProtocol {

    public init() {}



    //MARK: - pull

    public var pullVoidThrowableError: (any Error)?
    public var pullVoidCallsCount = 0
    public var pullVoidCalled: Bool {
        return pullVoidCallsCount > 0
    }
    public var pullVoidClosure: (() async throws -> Void)?

    public func pull() async throws {
        pullVoidCallsCount += 1
        if let error = pullVoidThrowableError {
            throw error
        }
        try await pullVoidClosure?()
    }


}
class PullSelfLegalholdInfoSyncProtocolMock: PullSelfLegalholdInfoSyncProtocol {




    //MARK: - pull

    var pullSelfTeamIDUUIDVoidThrowableError: (any Error)?
    var pullSelfTeamIDUUIDVoidCallsCount = 0
    var pullSelfTeamIDUUIDVoidCalled: Bool {
        return pullSelfTeamIDUUIDVoidCallsCount > 0
    }
    var pullSelfTeamIDUUIDVoidReceivedSelfTeamID: (UUID)?
    var pullSelfTeamIDUUIDVoidReceivedInvocations: [(UUID)] = []
    var pullSelfTeamIDUUIDVoidClosure: ((UUID) async throws -> Void)?

    func pull(selfTeamID: UUID) async throws {
        pullSelfTeamIDUUIDVoidCallsCount += 1
        pullSelfTeamIDUUIDVoidReceivedSelfTeamID = selfTeamID
        pullSelfTeamIDUUIDVoidReceivedInvocations.append(selfTeamID)
        if let error = pullSelfTeamIDUUIDVoidThrowableError {
            throw error
        }
        try await pullSelfTeamIDUUIDVoidClosure?(selfTeamID)
    }


}
class PullSelfTeamMembersSyncProtocolMock: PullSelfTeamMembersSyncProtocol {




    //MARK: - pull

    var pullSelfTeamIDUUIDVoidThrowableError: (any Error)?
    var pullSelfTeamIDUUIDVoidCallsCount = 0
    var pullSelfTeamIDUUIDVoidCalled: Bool {
        return pullSelfTeamIDUUIDVoidCallsCount > 0
    }
    var pullSelfTeamIDUUIDVoidReceivedSelfTeamID: (UUID)?
    var pullSelfTeamIDUUIDVoidReceivedInvocations: [(UUID)] = []
    var pullSelfTeamIDUUIDVoidClosure: ((UUID) async throws -> Void)?

    func pull(selfTeamID: UUID) async throws {
        pullSelfTeamIDUUIDVoidCallsCount += 1
        pullSelfTeamIDUUIDVoidReceivedSelfTeamID = selfTeamID
        pullSelfTeamIDUUIDVoidReceivedInvocations.append(selfTeamID)
        if let error = pullSelfTeamIDUUIDVoidThrowableError {
            throw error
        }
        try await pullSelfTeamIDUUIDVoidClosure?(selfTeamID)
    }


}
class PullSelfTeamRolesSyncProtocolMock: PullSelfTeamRolesSyncProtocol {




    //MARK: - pull

    var pullSelfTeamIDUUIDVoidThrowableError: (any Error)?
    var pullSelfTeamIDUUIDVoidCallsCount = 0
    var pullSelfTeamIDUUIDVoidCalled: Bool {
        return pullSelfTeamIDUUIDVoidCallsCount > 0
    }
    var pullSelfTeamIDUUIDVoidReceivedSelfTeamID: (UUID)?
    var pullSelfTeamIDUUIDVoidReceivedInvocations: [(UUID)] = []
    var pullSelfTeamIDUUIDVoidClosure: ((UUID) async throws -> Void)?

    func pull(selfTeamID: UUID) async throws {
        pullSelfTeamIDUUIDVoidCallsCount += 1
        pullSelfTeamIDUUIDVoidReceivedSelfTeamID = selfTeamID
        pullSelfTeamIDUUIDVoidReceivedInvocations.append(selfTeamID)
        if let error = pullSelfTeamIDUUIDVoidThrowableError {
            throw error
        }
        try await pullSelfTeamIDUUIDVoidClosure?(selfTeamID)
    }


}
class PullSelfTeamSyncProtocolMock: PullSelfTeamSyncProtocol {




    //MARK: - pull

    var pullSelfTeamIDUUIDVoidThrowableError: (any Error)?
    var pullSelfTeamIDUUIDVoidCallsCount = 0
    var pullSelfTeamIDUUIDVoidCalled: Bool {
        return pullSelfTeamIDUUIDVoidCallsCount > 0
    }
    var pullSelfTeamIDUUIDVoidReceivedSelfTeamID: (UUID)?
    var pullSelfTeamIDUUIDVoidReceivedInvocations: [(UUID)] = []
    var pullSelfTeamIDUUIDVoidClosure: ((UUID) async throws -> Void)?

    func pull(selfTeamID: UUID) async throws {
        pullSelfTeamIDUUIDVoidCallsCount += 1
        pullSelfTeamIDUUIDVoidReceivedSelfTeamID = selfTeamID
        pullSelfTeamIDUUIDVoidReceivedInvocations.append(selfTeamID)
        if let error = pullSelfTeamIDUUIDVoidThrowableError {
            throw error
        }
        try await pullSelfTeamIDUUIDVoidClosure?(selfTeamID)
    }


}
public class PullSelfUserClientsSyncProtocolMock: PullSelfUserClientsSyncProtocol {

    public init() {}



    //MARK: - pull

    public var pullVoidThrowableError: (any Error)?
    public var pullVoidCallsCount = 0
    public var pullVoidCalled: Bool {
        return pullVoidCallsCount > 0
    }
    public var pullVoidClosure: (() async throws -> Void)?

    public func pull() async throws {
        pullVoidCallsCount += 1
        if let error = pullVoidThrowableError {
            throw error
        }
        try await pullVoidClosure?()
    }


}
class PullSelfUserSettingsSyncProtocolMock: PullSelfUserSettingsSyncProtocol {




    //MARK: - pull

    var pullVoidThrowableError: (any Error)?
    var pullVoidCallsCount = 0
    var pullVoidCalled: Bool {
        return pullVoidCallsCount > 0
    }
    var pullVoidClosure: (() async throws -> Void)?

    func pull() async throws {
        pullVoidCallsCount += 1
        if let error = pullVoidThrowableError {
            throw error
        }
        try await pullVoidClosure?()
    }


}
class PullSelfUserSyncProtocolMock: PullSelfUserSyncProtocol {




    //MARK: - pull

    var pull_IdUUIDDomainStringTeamIDUUIDThrowableError: (any Error)?
    var pull_IdUUIDDomainStringTeamIDUUIDCallsCount = 0
    var pull_IdUUIDDomainStringTeamIDUUIDCalled: Bool {
        return pull_IdUUIDDomainStringTeamIDUUIDCallsCount > 0
    }
    var pull_IdUUIDDomainStringTeamIDUUIDReturnValue: (id: UUID, domain: String?, teamID: UUID?)!
    var pull_IdUUIDDomainStringTeamIDUUIDClosure: (() async throws -> (id: UUID, domain: String?, teamID: UUID?))?

    @discardableResult
    func pull() async throws -> (id: UUID, domain: String?, teamID: UUID?) {
        pull_IdUUIDDomainStringTeamIDUUIDCallsCount += 1
        if let error = pull_IdUUIDDomainStringTeamIDUUIDThrowableError {
            throw error
        }
        if let pull_IdUUIDDomainStringTeamIDUUIDClosure = pull_IdUUIDDomainStringTeamIDUUIDClosure {
            return try await pull_IdUUIDDomainStringTeamIDUUIDClosure()
        } else {
            return pull_IdUUIDDomainStringTeamIDUUIDReturnValue
        }
    }


}
public class PullServerTimeSyncProtocolMock: PullServerTimeSyncProtocol {

    public init() {}



    //MARK: - pull

    public var pullVoidThrowableError: (any Error)?
    public var pullVoidCallsCount = 0
    public var pullVoidCalled: Bool {
        return pullVoidCallsCount > 0
    }
    public var pullVoidClosure: (() async throws -> Void)?

    public func pull() async throws {
        pullVoidCallsCount += 1
        if let error = pullVoidThrowableError {
            throw error
        }
        try await pullVoidClosure?()
    }


}
class PullUserConnectionsSyncProtocolMock: PullUserConnectionsSyncProtocol {




    //MARK: - pull

    var pullVoidThrowableError: (any Error)?
    var pullVoidCallsCount = 0
    var pullVoidCalled: Bool {
        return pullVoidCallsCount > 0
    }
    var pullVoidClosure: (() async throws -> Void)?

    func pull() async throws {
        pullVoidCallsCount += 1
        if let error = pullVoidThrowableError {
            throw error
        }
        try await pullVoidClosure?()
    }


}
public class PushSupportedProtocolsSyncProtocolMock: PushSupportedProtocolsSyncProtocol {

    public init() {}



    //MARK: - push

    public var pushSupportedProtocolsSetWireNetworkMessageProtocolVoidThrowableError: (any Error)?
    public var pushSupportedProtocolsSetWireNetworkMessageProtocolVoidCallsCount = 0
    public var pushSupportedProtocolsSetWireNetworkMessageProtocolVoidCalled: Bool {
        return pushSupportedProtocolsSetWireNetworkMessageProtocolVoidCallsCount > 0
    }
    public var pushSupportedProtocolsSetWireNetworkMessageProtocolVoidReceivedSupportedProtocols: (Set<WireNetwork.MessageProtocol>)?
    public var pushSupportedProtocolsSetWireNetworkMessageProtocolVoidReceivedInvocations: [(Set<WireNetwork.MessageProtocol>)] = []
    public var pushSupportedProtocolsSetWireNetworkMessageProtocolVoidClosure: ((Set<WireNetwork.MessageProtocol>) async throws -> Void)?

    public func push(supportedProtocols: Set<WireNetwork.MessageProtocol>) async throws {
        pushSupportedProtocolsSetWireNetworkMessageProtocolVoidCallsCount += 1
        pushSupportedProtocolsSetWireNetworkMessageProtocolVoidReceivedSupportedProtocols = supportedProtocols
        pushSupportedProtocolsSetWireNetworkMessageProtocolVoidReceivedInvocations.append(supportedProtocols)
        if let error = pushSupportedProtocolsSetWireNetworkMessageProtocolVoidThrowableError {
            throw error
        }
        try await pushSupportedProtocolsSetWireNetworkMessageProtocolVoidClosure?(supportedProtocols)
    }


}
public class PushSupportedProtocolsUseCaseProtocolMock: PushSupportedProtocolsUseCaseProtocol {

    public init() {}



    //MARK: - invoke

    public var invokeVoidThrowableError: (any Error)?
    public var invokeVoidCallsCount = 0
    public var invokeVoidCalled: Bool {
        return invokeVoidCallsCount > 0
    }
    public var invokeVoidClosure: (() async throws -> Void)?

    public func invoke() async throws {
        invokeVoidCallsCount += 1
        if let error = invokeVoidThrowableError {
            throw error
        }
        try await invokeVoidClosure?()
    }


}
public class SelfUserProviderProtocolMock: SelfUserProviderProtocol {

    public init() {}



    //MARK: - fetchSelfUser

    public var fetchSelfUserZMUserCallsCount = 0
    public var fetchSelfUserZMUserCalled: Bool {
        return fetchSelfUserZMUserCallsCount > 0
    }
    public var fetchSelfUserZMUserReturnValue: ZMUser!
    public var fetchSelfUserZMUserClosure: (() -> ZMUser)?

    public func fetchSelfUser() -> ZMUser {
        fetchSelfUserZMUserCallsCount += 1
        if let fetchSelfUserZMUserClosure = fetchSelfUserZMUserClosure {
            return fetchSelfUserZMUserClosure()
        } else {
            return fetchSelfUserZMUserReturnValue
        }
    }


}
class SyncEventsUseCaseProtocolMock: SyncEventsUseCaseProtocol {




    //MARK: - invoke

    var invokeVoidThrowableError: (any Error)?
    var invokeVoidCallsCount = 0
    var invokeVoidCalled: Bool {
        return invokeVoidCallsCount > 0
    }
    var invokeVoidClosure: (() async throws -> Void)?

    func invoke() async throws {
        invokeVoidCallsCount += 1
        if let error = invokeVoidThrowableError {
            throw error
        }
        try await invokeVoidClosure?()
    }


}
public class SyncMigratorProtocolMock: SyncMigratorProtocol {

    public init() {}



    //MARK: - migrateFromIncrementalSyncV1

    public var migrateFromIncrementalSyncV1VoidThrowableError: (any Error)?
    public var migrateFromIncrementalSyncV1VoidCallsCount = 0
    public var migrateFromIncrementalSyncV1VoidCalled: Bool {
        return migrateFromIncrementalSyncV1VoidCallsCount > 0
    }
    public var migrateFromIncrementalSyncV1VoidClosure: (() async throws -> Void)?

    public func migrateFromIncrementalSyncV1() async throws {
        migrateFromIncrementalSyncV1VoidCallsCount += 1
        if let error = migrateFromIncrementalSyncV1VoidThrowableError {
            throw error
        }
        try await migrateFromIncrementalSyncV1VoidClosure?()
    }


}
public class TeamLocalStoreProtocolMock: TeamLocalStoreProtocol {

    public init() {}



    //MARK: - fetchMember

    public var fetchMemberIdUUIDMemberCallsCount = 0
    public var fetchMemberIdUUIDMemberCalled: Bool {
        return fetchMemberIdUUIDMemberCallsCount > 0
    }
    public var fetchMemberIdUUIDMemberReceivedId: (UUID)?
    public var fetchMemberIdUUIDMemberReceivedInvocations: [(UUID)] = []
    public var fetchMemberIdUUIDMemberReturnValue: Member?
    public var fetchMemberIdUUIDMemberClosure: ((UUID) async -> Member?)?

    public func fetchMember(id: UUID) async -> Member? {
        fetchMemberIdUUIDMemberCallsCount += 1
        fetchMemberIdUUIDMemberReceivedId = id
        fetchMemberIdUUIDMemberReceivedInvocations.append(id)
        if let fetchMemberIdUUIDMemberClosure = fetchMemberIdUUIDMemberClosure {
            return await fetchMemberIdUUIDMemberClosure(id)
        } else {
            return fetchMemberIdUUIDMemberReturnValue
        }
    }

    //MARK: - selfUserID

    public var selfUserIDUuidCallsCount = 0
    public var selfUserIDUuidCalled: Bool {
        return selfUserIDUuidCallsCount > 0
    }
    public var selfUserIDUuidReturnValue: UUID!
    public var selfUserIDUuidClosure: (() async -> UUID)?

    public func selfUserID() async -> UUID {
        selfUserIDUuidCallsCount += 1
        if let selfUserIDUuidClosure = selfUserIDUuidClosure {
            return await selfUserIDUuidClosure()
        } else {
            return selfUserIDUuidReturnValue
        }
    }

    //MARK: - selfTeamID

    public var selfTeamIDUuidCallsCount = 0
    public var selfTeamIDUuidCalled: Bool {
        return selfTeamIDUuidCallsCount > 0
    }
    public var selfTeamIDUuidReturnValue: UUID?
    public var selfTeamIDUuidClosure: (() async -> UUID?)?

    public func selfTeamID() async -> UUID? {
        selfTeamIDUuidCallsCount += 1
        if let selfTeamIDUuidClosure = selfTeamIDUuidClosure {
            return await selfTeamIDUuidClosure()
        } else {
            return selfTeamIDUuidReturnValue
        }
    }

    //MARK: - userMembership

    public var userMembershipUserZMUserMemberCallsCount = 0
    public var userMembershipUserZMUserMemberCalled: Bool {
        return userMembershipUserZMUserMemberCallsCount > 0
    }
    public var userMembershipUserZMUserMemberReceivedUser: (ZMUser)?
    public var userMembershipUserZMUserMemberReceivedInvocations: [(ZMUser)] = []
    public var userMembershipUserZMUserMemberReturnValue: Member?
    public var userMembershipUserZMUserMemberClosure: ((ZMUser) async -> Member?)?

    public func userMembership(user: ZMUser) async -> Member? {
        userMembershipUserZMUserMemberCallsCount += 1
        userMembershipUserZMUserMemberReceivedUser = user
        userMembershipUserZMUserMemberReceivedInvocations.append(user)
        if let userMembershipUserZMUserMemberClosure = userMembershipUserZMUserMemberClosure {
            return await userMembershipUserZMUserMemberClosure(user)
        } else {
            return userMembershipUserZMUserMemberReturnValue
        }
    }

    //MARK: - userDomain

    public var userDomainUserZMUserStringCallsCount = 0
    public var userDomainUserZMUserStringCalled: Bool {
        return userDomainUserZMUserStringCallsCount > 0
    }
    public var userDomainUserZMUserStringReceivedUser: (ZMUser)?
    public var userDomainUserZMUserStringReceivedInvocations: [(ZMUser)] = []
    public var userDomainUserZMUserStringReturnValue: String?
    public var userDomainUserZMUserStringClosure: ((ZMUser) async -> String?)?

    public func userDomain(user: ZMUser) async -> String? {
        userDomainUserZMUserStringCallsCount += 1
        userDomainUserZMUserStringReceivedUser = user
        userDomainUserZMUserStringReceivedInvocations.append(user)
        if let userDomainUserZMUserStringClosure = userDomainUserZMUserStringClosure {
            return await userDomainUserZMUserStringClosure(user)
        } else {
            return userDomainUserZMUserStringReturnValue
        }
    }

    //MARK: - deleteMember

    public var deleteMemberMemberMemberVoidCallsCount = 0
    public var deleteMemberMemberMemberVoidCalled: Bool {
        return deleteMemberMemberMemberVoidCallsCount > 0
    }
    public var deleteMemberMemberMemberVoidReceivedMember: (Member)?
    public var deleteMemberMemberMemberVoidReceivedInvocations: [(Member)] = []
    public var deleteMemberMemberMemberVoidClosure: ((Member) async -> Void)?

    public func deleteMember(_ member: Member) async {
        deleteMemberMemberMemberVoidCallsCount += 1
        deleteMemberMemberMemberVoidReceivedMember = member
        deleteMemberMemberMemberVoidReceivedInvocations.append(member)
        await deleteMemberMemberMemberVoidClosure?(member)
    }

    //MARK: - storeMember

    public var storeMemberNeedsBackendUpdateBoolMemberMemberVoidCallsCount = 0
    public var storeMemberNeedsBackendUpdateBoolMemberMemberVoidCalled: Bool {
        return storeMemberNeedsBackendUpdateBoolMemberMemberVoidCallsCount > 0
    }
    public var storeMemberNeedsBackendUpdateBoolMemberMemberVoidReceivedArguments: (needsBackendUpdate: Bool, member: Member)?
    public var storeMemberNeedsBackendUpdateBoolMemberMemberVoidReceivedInvocations: [(needsBackendUpdate: Bool, member: Member)] = []
    public var storeMemberNeedsBackendUpdateBoolMemberMemberVoidClosure: ((Bool, Member) async -> Void)?

    public func storeMember(needsBackendUpdate: Bool, member: Member) async {
        storeMemberNeedsBackendUpdateBoolMemberMemberVoidCallsCount += 1
        storeMemberNeedsBackendUpdateBoolMemberMemberVoidReceivedArguments = (needsBackendUpdate: needsBackendUpdate, member: member)
        storeMemberNeedsBackendUpdateBoolMemberMemberVoidReceivedInvocations.append((needsBackendUpdate: needsBackendUpdate, member: member))
        await storeMemberNeedsBackendUpdateBoolMemberMemberVoidClosure?(needsBackendUpdate, member)
    }

    //MARK: - storeTeam

    public var storeTeamIdUUIDNameStringCreatorIDUUIDLogoIDStringLogoKeyStringVoidCallsCount = 0
    public var storeTeamIdUUIDNameStringCreatorIDUUIDLogoIDStringLogoKeyStringVoidCalled: Bool {
        return storeTeamIdUUIDNameStringCreatorIDUUIDLogoIDStringLogoKeyStringVoidCallsCount > 0
    }
    public var storeTeamIdUUIDNameStringCreatorIDUUIDLogoIDStringLogoKeyStringVoidReceivedArguments: (id: UUID, name: String, creatorID: UUID, logoID: String?, logoKey: String?)?
    public var storeTeamIdUUIDNameStringCreatorIDUUIDLogoIDStringLogoKeyStringVoidReceivedInvocations: [(id: UUID, name: String, creatorID: UUID, logoID: String?, logoKey: String?)] = []
    public var storeTeamIdUUIDNameStringCreatorIDUUIDLogoIDStringLogoKeyStringVoidClosure: ((UUID, String, UUID, String?, String?) async -> Void)?

    public func storeTeam(id: UUID, name: String, creatorID: UUID, logoID: String?, logoKey: String?) async {
        storeTeamIdUUIDNameStringCreatorIDUUIDLogoIDStringLogoKeyStringVoidCallsCount += 1
        storeTeamIdUUIDNameStringCreatorIDUUIDLogoIDStringLogoKeyStringVoidReceivedArguments = (id: id, name: name, creatorID: creatorID, logoID: logoID, logoKey: logoKey)
        storeTeamIdUUIDNameStringCreatorIDUUIDLogoIDStringLogoKeyStringVoidReceivedInvocations.append((id: id, name: name, creatorID: creatorID, logoID: logoID, logoKey: logoKey))
        await storeTeamIdUUIDNameStringCreatorIDUUIDLogoIDStringLogoKeyStringVoidClosure?(id, name, creatorID, logoID, logoKey)
    }

    //MARK: - storeTeamRoles

    public var storeTeamRolesSelfTeamIDUUIDTeamRolesInfoTeamRoleInfoVoidThrowableError: (any Error)?
    public var storeTeamRolesSelfTeamIDUUIDTeamRolesInfoTeamRoleInfoVoidCallsCount = 0
    public var storeTeamRolesSelfTeamIDUUIDTeamRolesInfoTeamRoleInfoVoidCalled: Bool {
        return storeTeamRolesSelfTeamIDUUIDTeamRolesInfoTeamRoleInfoVoidCallsCount > 0
    }
    public var storeTeamRolesSelfTeamIDUUIDTeamRolesInfoTeamRoleInfoVoidReceivedArguments: (selfTeamID: UUID, teamRolesInfo: [TeamRoleInfo])?
    public var storeTeamRolesSelfTeamIDUUIDTeamRolesInfoTeamRoleInfoVoidReceivedInvocations: [(selfTeamID: UUID, teamRolesInfo: [TeamRoleInfo])] = []
    public var storeTeamRolesSelfTeamIDUUIDTeamRolesInfoTeamRoleInfoVoidClosure: ((UUID, [TeamRoleInfo]) async throws -> Void)?

    public func storeTeamRoles(selfTeamID: UUID, teamRolesInfo: [TeamRoleInfo]) async throws {
        storeTeamRolesSelfTeamIDUUIDTeamRolesInfoTeamRoleInfoVoidCallsCount += 1
        storeTeamRolesSelfTeamIDUUIDTeamRolesInfoTeamRoleInfoVoidReceivedArguments = (selfTeamID: selfTeamID, teamRolesInfo: teamRolesInfo)
        storeTeamRolesSelfTeamIDUUIDTeamRolesInfoTeamRoleInfoVoidReceivedInvocations.append((selfTeamID: selfTeamID, teamRolesInfo: teamRolesInfo))
        if let error = storeTeamRolesSelfTeamIDUUIDTeamRolesInfoTeamRoleInfoVoidThrowableError {
            throw error
        }
        try await storeTeamRolesSelfTeamIDUUIDTeamRolesInfoTeamRoleInfoVoidClosure?(selfTeamID, teamRolesInfo)
    }

    //MARK: - storeTeamMembers

    public var storeTeamMembersSelfTeamIDUUIDTeamMembersInfoTeamMemberInfoVoidThrowableError: (any Error)?
    public var storeTeamMembersSelfTeamIDUUIDTeamMembersInfoTeamMemberInfoVoidCallsCount = 0
    public var storeTeamMembersSelfTeamIDUUIDTeamMembersInfoTeamMemberInfoVoidCalled: Bool {
        return storeTeamMembersSelfTeamIDUUIDTeamMembersInfoTeamMemberInfoVoidCallsCount > 0
    }
    public var storeTeamMembersSelfTeamIDUUIDTeamMembersInfoTeamMemberInfoVoidReceivedArguments: (selfTeamID: UUID, teamMembersInfo: [TeamMemberInfo])?
    public var storeTeamMembersSelfTeamIDUUIDTeamMembersInfoTeamMemberInfoVoidReceivedInvocations: [(selfTeamID: UUID, teamMembersInfo: [TeamMemberInfo])] = []
    public var storeTeamMembersSelfTeamIDUUIDTeamMembersInfoTeamMemberInfoVoidClosure: ((UUID, [TeamMemberInfo]) async throws -> Void)?

    public func storeTeamMembers(selfTeamID: UUID, teamMembersInfo: [TeamMemberInfo]) async throws {
        storeTeamMembersSelfTeamIDUUIDTeamMembersInfoTeamMemberInfoVoidCallsCount += 1
        storeTeamMembersSelfTeamIDUUIDTeamMembersInfoTeamMemberInfoVoidReceivedArguments = (selfTeamID: selfTeamID, teamMembersInfo: teamMembersInfo)
        storeTeamMembersSelfTeamIDUUIDTeamMembersInfoTeamMemberInfoVoidReceivedInvocations.append((selfTeamID: selfTeamID, teamMembersInfo: teamMembersInfo))
        if let error = storeTeamMembersSelfTeamIDUUIDTeamMembersInfoTeamMemberInfoVoidThrowableError {
            throw error
        }
        try await storeTeamMembersSelfTeamIDUUIDTeamMembersInfoTeamMemberInfoVoidClosure?(selfTeamID, teamMembersInfo)
    }

    //MARK: - selfUserInfo

    public var selfUserInfo_IdUUIDClientIdStringCallsCount = 0
    public var selfUserInfo_IdUUIDClientIdStringCalled: Bool {
        return selfUserInfo_IdUUIDClientIdStringCallsCount > 0
    }
    public var selfUserInfo_IdUUIDClientIdStringReturnValue: (id: UUID, clientId: String?)!
    public var selfUserInfo_IdUUIDClientIdStringClosure: (() async -> (id: UUID, clientId: String?))?

    public func selfUserInfo() async -> (id: UUID, clientId: String?) {
        selfUserInfo_IdUUIDClientIdStringCallsCount += 1
        if let selfUserInfo_IdUUIDClientIdStringClosure = selfUserInfo_IdUUIDClientIdStringClosure {
            return await selfUserInfo_IdUUIDClientIdStringClosure()
        } else {
            return selfUserInfo_IdUUIDClientIdStringReturnValue
        }
    }

    //MARK: - createOrUpdateTeam

    public var createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidCallsCount = 0
    public var createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidCalled: Bool {
        return createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidCallsCount > 0
    }
    public var createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidReceivedArguments: (identifier: UUID, name: String, creator: UUID, icon: String, iconKey: String?)?
    public var createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidReceivedInvocations: [(identifier: UUID, name: String, creator: UUID, icon: String, iconKey: String?)] = []
    public var createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidClosure: ((UUID, String, UUID, String, String?) async -> Void)?

    public func createOrUpdateTeam(identifier: UUID, name: String, creator: UUID, icon: String, iconKey: String?) async {
        createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidCallsCount += 1
        createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidReceivedArguments = (identifier: identifier, name: name, creator: creator, icon: icon, iconKey: iconKey)
        createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidReceivedInvocations.append((identifier: identifier, name: name, creator: creator, icon: icon, iconKey: iconKey))
        await createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidClosure?(identifier, name, creator, icon, iconKey)
    }


}
public class TeamRepositoryProtocolMock: TeamRepositoryProtocol {

    public init() {}



    //MARK: - pullSelfTeam

    public var pullSelfTeamVoidThrowableError: (any Error)?
    public var pullSelfTeamVoidCallsCount = 0
    public var pullSelfTeamVoidCalled: Bool {
        return pullSelfTeamVoidCallsCount > 0
    }
    public var pullSelfTeamVoidClosure: (() async throws -> Void)?

    public func pullSelfTeam() async throws {
        pullSelfTeamVoidCallsCount += 1
        if let error = pullSelfTeamVoidThrowableError {
            throw error
        }
        try await pullSelfTeamVoidClosure?()
    }

    //MARK: - pullSelfTeamRoles

    public var pullSelfTeamRolesVoidThrowableError: (any Error)?
    public var pullSelfTeamRolesVoidCallsCount = 0
    public var pullSelfTeamRolesVoidCalled: Bool {
        return pullSelfTeamRolesVoidCallsCount > 0
    }
    public var pullSelfTeamRolesVoidClosure: (() async throws -> Void)?

    public func pullSelfTeamRoles() async throws {
        pullSelfTeamRolesVoidCallsCount += 1
        if let error = pullSelfTeamRolesVoidThrowableError {
            throw error
        }
        try await pullSelfTeamRolesVoidClosure?()
    }

    //MARK: - pullSelfTeamMembers

    public var pullSelfTeamMembersVoidThrowableError: (any Error)?
    public var pullSelfTeamMembersVoidCallsCount = 0
    public var pullSelfTeamMembersVoidCalled: Bool {
        return pullSelfTeamMembersVoidCallsCount > 0
    }
    public var pullSelfTeamMembersVoidClosure: (() async throws -> Void)?

    public func pullSelfTeamMembers() async throws {
        pullSelfTeamMembersVoidCallsCount += 1
        if let error = pullSelfTeamMembersVoidThrowableError {
            throw error
        }
        try await pullSelfTeamMembersVoidClosure?()
    }

    //MARK: - fetchSelfLegalholdInfo

    public var fetchSelfLegalholdInfoTeamMemberLegalholdInfoThrowableError: (any Error)?
    public var fetchSelfLegalholdInfoTeamMemberLegalholdInfoCallsCount = 0
    public var fetchSelfLegalholdInfoTeamMemberLegalholdInfoCalled: Bool {
        return fetchSelfLegalholdInfoTeamMemberLegalholdInfoCallsCount > 0
    }
    public var fetchSelfLegalholdInfoTeamMemberLegalholdInfoReturnValue: TeamMemberLegalholdInfo!
    public var fetchSelfLegalholdInfoTeamMemberLegalholdInfoClosure: (() async throws -> TeamMemberLegalholdInfo)?

    public func fetchSelfLegalholdInfo() async throws -> TeamMemberLegalholdInfo {
        fetchSelfLegalholdInfoTeamMemberLegalholdInfoCallsCount += 1
        if let error = fetchSelfLegalholdInfoTeamMemberLegalholdInfoThrowableError {
            throw error
        }
        if let fetchSelfLegalholdInfoTeamMemberLegalholdInfoClosure = fetchSelfLegalholdInfoTeamMemberLegalholdInfoClosure {
            return try await fetchSelfLegalholdInfoTeamMemberLegalholdInfoClosure()
        } else {
            return fetchSelfLegalholdInfoTeamMemberLegalholdInfoReturnValue
        }
    }

    //MARK: - createOrUpdateTeam

    public var createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidCallsCount = 0
    public var createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidCalled: Bool {
        return createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidCallsCount > 0
    }
    public var createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidReceivedArguments: (identifier: UUID, name: String, creator: UUID, icon: String, iconKey: String?)?
    public var createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidReceivedInvocations: [(identifier: UUID, name: String, creator: UUID, icon: String, iconKey: String?)] = []
    public var createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidClosure: ((UUID, String, UUID, String, String?) async -> Void)?

    public func createOrUpdateTeam(identifier: UUID, name: String, creator: UUID, icon: String, iconKey: String?) async {
        createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidCallsCount += 1
        createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidReceivedArguments = (identifier: identifier, name: name, creator: creator, icon: icon, iconKey: iconKey)
        createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidReceivedInvocations.append((identifier: identifier, name: name, creator: creator, icon: icon, iconKey: iconKey))
        await createOrUpdateTeamIdentifierUUIDNameStringCreatorUUIDIconStringIconKeyStringVoidClosure?(identifier, name, creator, icon, iconKey)
    }

    //MARK: - deleteMembership

    public var deleteMembershipUserIDUUIDDomainStringDateDateVoidThrowableError: (any Error)?
    public var deleteMembershipUserIDUUIDDomainStringDateDateVoidCallsCount = 0
    public var deleteMembershipUserIDUUIDDomainStringDateDateVoidCalled: Bool {
        return deleteMembershipUserIDUUIDDomainStringDateDateVoidCallsCount > 0
    }
    public var deleteMembershipUserIDUUIDDomainStringDateDateVoidReceivedArguments: (userID: UUID, domain: String?, date: Date)?
    public var deleteMembershipUserIDUUIDDomainStringDateDateVoidReceivedInvocations: [(userID: UUID, domain: String?, date: Date)] = []
    public var deleteMembershipUserIDUUIDDomainStringDateDateVoidClosure: ((UUID, String?, Date) async throws -> Void)?

    public func deleteMembership(userID: UUID, domain: String?, date: Date) async throws {
        deleteMembershipUserIDUUIDDomainStringDateDateVoidCallsCount += 1
        deleteMembershipUserIDUUIDDomainStringDateDateVoidReceivedArguments = (userID: userID, domain: domain, date: date)
        deleteMembershipUserIDUUIDDomainStringDateDateVoidReceivedInvocations.append((userID: userID, domain: domain, date: date))
        if let error = deleteMembershipUserIDUUIDDomainStringDateDateVoidThrowableError {
            throw error
        }
        try await deleteMembershipUserIDUUIDDomainStringDateDateVoidClosure?(userID, domain, date)
    }

    //MARK: - storeTeamMemberNeedsBackendUpdate

    public var storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidThrowableError: (any Error)?
    public var storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidCallsCount = 0
    public var storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidCalled: Bool {
        return storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidCallsCount > 0
    }
    public var storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidReceivedMembershipID: (UUID)?
    public var storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidReceivedInvocations: [(UUID)] = []
    public var storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidClosure: ((UUID) async throws -> Void)?

    public func storeTeamMemberNeedsBackendUpdate(membershipID: UUID) async throws {
        storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidCallsCount += 1
        storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidReceivedMembershipID = membershipID
        storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidReceivedInvocations.append(membershipID)
        if let error = storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidThrowableError {
            throw error
        }
        try await storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidClosure?(membershipID)
    }

    //MARK: - pullSelfLegalholdInfo

    public var pullSelfLegalholdInfoVoidThrowableError: (any Error)?
    public var pullSelfLegalholdInfoVoidCallsCount = 0
    public var pullSelfLegalholdInfoVoidCalled: Bool {
        return pullSelfLegalholdInfoVoidCallsCount > 0
    }
    public var pullSelfLegalholdInfoVoidClosure: (() async throws -> Void)?

    public func pullSelfLegalholdInfo() async throws {
        pullSelfLegalholdInfoVoidCallsCount += 1
        if let error = pullSelfLegalholdInfoVoidThrowableError {
            throw error
        }
        try await pullSelfLegalholdInfoVoidClosure?()
    }


}
public class UpdateEventDecryptorProtocolMock: UpdateEventDecryptorProtocol {

    public init() {}



    //MARK: - decryptEvents

    public var decryptEventsInEventEnvelopeUpdateEventEnvelopeContextCoreCryptoContextProtocolEventDecryptorResultCallsCount = 0
    public var decryptEventsInEventEnvelopeUpdateEventEnvelopeContextCoreCryptoContextProtocolEventDecryptorResultCalled: Bool {
        return decryptEventsInEventEnvelopeUpdateEventEnvelopeContextCoreCryptoContextProtocolEventDecryptorResultCallsCount > 0
    }
    public var decryptEventsInEventEnvelopeUpdateEventEnvelopeContextCoreCryptoContextProtocolEventDecryptorResultReceivedArguments: (eventEnvelope: UpdateEventEnvelope, context: CoreCryptoContextProtocol?)?
    public var decryptEventsInEventEnvelopeUpdateEventEnvelopeContextCoreCryptoContextProtocolEventDecryptorResultReceivedInvocations: [(eventEnvelope: UpdateEventEnvelope, context: CoreCryptoContextProtocol?)] = []
    public var decryptEventsInEventEnvelopeUpdateEventEnvelopeContextCoreCryptoContextProtocolEventDecryptorResultReturnValue: EventDecryptorResult!
    public var decryptEventsInEventEnvelopeUpdateEventEnvelopeContextCoreCryptoContextProtocolEventDecryptorResultClosure: ((UpdateEventEnvelope, CoreCryptoContextProtocol?) async -> EventDecryptorResult)?

    public func decryptEvents(in eventEnvelope: UpdateEventEnvelope, context: CoreCryptoContextProtocol?) async -> EventDecryptorResult {
        decryptEventsInEventEnvelopeUpdateEventEnvelopeContextCoreCryptoContextProtocolEventDecryptorResultCallsCount += 1
        decryptEventsInEventEnvelopeUpdateEventEnvelopeContextCoreCryptoContextProtocolEventDecryptorResultReceivedArguments = (eventEnvelope: eventEnvelope, context: context)
        decryptEventsInEventEnvelopeUpdateEventEnvelopeContextCoreCryptoContextProtocolEventDecryptorResultReceivedInvocations.append((eventEnvelope: eventEnvelope, context: context))
        if let decryptEventsInEventEnvelopeUpdateEventEnvelopeContextCoreCryptoContextProtocolEventDecryptorResultClosure = decryptEventsInEventEnvelopeUpdateEventEnvelopeContextCoreCryptoContextProtocolEventDecryptorResultClosure {
            return await decryptEventsInEventEnvelopeUpdateEventEnvelopeContextCoreCryptoContextProtocolEventDecryptorResultClosure(eventEnvelope, context)
        } else {
            return decryptEventsInEventEnvelopeUpdateEventEnvelopeContextCoreCryptoContextProtocolEventDecryptorResultReturnValue
        }
    }


}
public class UpdateEventProcessorProtocolMock: UpdateEventProcessorProtocol {

    public init() {}



    //MARK: - processEvent

    public var processEventEventUpdateEventVoidThrowableError: (any Error)?
    public var processEventEventUpdateEventVoidCallsCount = 0
    public var processEventEventUpdateEventVoidCalled: Bool {
        return processEventEventUpdateEventVoidCallsCount > 0
    }
    public var processEventEventUpdateEventVoidReceivedEvent: (UpdateEvent)?
    public var processEventEventUpdateEventVoidReceivedInvocations: [(UpdateEvent)] = []
    public var processEventEventUpdateEventVoidClosure: ((UpdateEvent) async throws -> Void)?

    public func processEvent(_ event: UpdateEvent) async throws {
        processEventEventUpdateEventVoidCallsCount += 1
        processEventEventUpdateEventVoidReceivedEvent = event
        processEventEventUpdateEventVoidReceivedInvocations.append(event)
        if let error = processEventEventUpdateEventVoidThrowableError {
            throw error
        }
        try await processEventEventUpdateEventVoidClosure?(event)
    }


}
public class UpdateEventsLocalStoreProtocolMock: UpdateEventsLocalStoreProtocol {

    public init() {}



    //MARK: - lastEventID

    public var lastEventIDUuidCallsCount = 0
    public var lastEventIDUuidCalled: Bool {
        return lastEventIDUuidCallsCount > 0
    }
    public var lastEventIDUuidReturnValue: UUID?
    public var lastEventIDUuidClosure: (() -> UUID?)?

    public func lastEventID() -> UUID? {
        lastEventIDUuidCallsCount += 1
        if let lastEventIDUuidClosure = lastEventIDUuidClosure {
            return lastEventIDUuidClosure()
        } else {
            return lastEventIDUuidReturnValue
        }
    }

    //MARK: - storeLastEventID

    public var storeLastEventIDIdUUIDVoidCallsCount = 0
    public var storeLastEventIDIdUUIDVoidCalled: Bool {
        return storeLastEventIDIdUUIDVoidCallsCount > 0
    }
    public var storeLastEventIDIdUUIDVoidReceivedId: (UUID)?
    public var storeLastEventIDIdUUIDVoidReceivedInvocations: [(UUID)] = []
    public var storeLastEventIDIdUUIDVoidClosure: ((UUID) -> Void)?

    public func storeLastEventID(id: UUID) {
        storeLastEventIDIdUUIDVoidCallsCount += 1
        storeLastEventIDIdUUIDVoidReceivedId = id
        storeLastEventIDIdUUIDVoidReceivedInvocations.append(id)
        storeLastEventIDIdUUIDVoidClosure?(id)
    }

    //MARK: - resetLastEventID

    public var resetLastEventIDVoidCallsCount = 0
    public var resetLastEventIDVoidCalled: Bool {
        return resetLastEventIDVoidCallsCount > 0
    }
    public var resetLastEventIDVoidClosure: (() -> Void)?

    public func resetLastEventID() {
        resetLastEventIDVoidCallsCount += 1
        resetLastEventIDVoidClosure?()
    }

    //MARK: - indexOfLastEventEnvelope

    public var indexOfLastEventEnvelopeInt64ThrowableError: (any Error)?
    public var indexOfLastEventEnvelopeInt64CallsCount = 0
    public var indexOfLastEventEnvelopeInt64Called: Bool {
        return indexOfLastEventEnvelopeInt64CallsCount > 0
    }
    public var indexOfLastEventEnvelopeInt64ReturnValue: Int64!
    public var indexOfLastEventEnvelopeInt64Closure: (() async throws -> Int64)?

    public func indexOfLastEventEnvelope() async throws -> Int64 {
        indexOfLastEventEnvelopeInt64CallsCount += 1
        if let error = indexOfLastEventEnvelopeInt64ThrowableError {
            throw error
        }
        if let indexOfLastEventEnvelopeInt64Closure = indexOfLastEventEnvelopeInt64Closure {
            return try await indexOfLastEventEnvelopeInt64Closure()
        } else {
            return indexOfLastEventEnvelopeInt64ReturnValue
        }
    }

    //MARK: - persistEventEnvelope

    public var persistEventEnvelopeEventEnvelopeUpdateEventEnvelopeIndexInt64VoidThrowableError: (any Error)?
    public var persistEventEnvelopeEventEnvelopeUpdateEventEnvelopeIndexInt64VoidCallsCount = 0
    public var persistEventEnvelopeEventEnvelopeUpdateEventEnvelopeIndexInt64VoidCalled: Bool {
        return persistEventEnvelopeEventEnvelopeUpdateEventEnvelopeIndexInt64VoidCallsCount > 0
    }
    public var persistEventEnvelopeEventEnvelopeUpdateEventEnvelopeIndexInt64VoidReceivedArguments: (eventEnvelope: UpdateEventEnvelope, index: Int64)?
    public var persistEventEnvelopeEventEnvelopeUpdateEventEnvelopeIndexInt64VoidReceivedInvocations: [(eventEnvelope: UpdateEventEnvelope, index: Int64)] = []
    public var persistEventEnvelopeEventEnvelopeUpdateEventEnvelopeIndexInt64VoidClosure: ((UpdateEventEnvelope, Int64) async throws -> Void)?

    public func persistEventEnvelope(_ eventEnvelope: UpdateEventEnvelope, index: Int64) async throws {
        persistEventEnvelopeEventEnvelopeUpdateEventEnvelopeIndexInt64VoidCallsCount += 1
        persistEventEnvelopeEventEnvelopeUpdateEventEnvelopeIndexInt64VoidReceivedArguments = (eventEnvelope: eventEnvelope, index: index)
        persistEventEnvelopeEventEnvelopeUpdateEventEnvelopeIndexInt64VoidReceivedInvocations.append((eventEnvelope: eventEnvelope, index: index))
        if let error = persistEventEnvelopeEventEnvelopeUpdateEventEnvelopeIndexInt64VoidThrowableError {
            throw error
        }
        try await persistEventEnvelopeEventEnvelopeUpdateEventEnvelopeIndexInt64VoidClosure?(eventEnvelope, index)
    }

    //MARK: - persistEventEnvelopes

    public var persistEventEnvelopesEventEnvelopesUpdateEventEnvelopeIndexInt64VoidThrowableError: (any Error)?
    public var persistEventEnvelopesEventEnvelopesUpdateEventEnvelopeIndexInt64VoidCallsCount = 0
    public var persistEventEnvelopesEventEnvelopesUpdateEventEnvelopeIndexInt64VoidCalled: Bool {
        return persistEventEnvelopesEventEnvelopesUpdateEventEnvelopeIndexInt64VoidCallsCount > 0
    }
    public var persistEventEnvelopesEventEnvelopesUpdateEventEnvelopeIndexInt64VoidReceivedArguments: (eventEnvelopes: [UpdateEventEnvelope], index: Int64)?
    public var persistEventEnvelopesEventEnvelopesUpdateEventEnvelopeIndexInt64VoidReceivedInvocations: [(eventEnvelopes: [UpdateEventEnvelope], index: Int64)] = []
    public var persistEventEnvelopesEventEnvelopesUpdateEventEnvelopeIndexInt64VoidClosure: (([UpdateEventEnvelope], Int64) async throws -> Void)?

    public func persistEventEnvelopes(_ eventEnvelopes: [UpdateEventEnvelope], index: Int64) async throws {
        persistEventEnvelopesEventEnvelopesUpdateEventEnvelopeIndexInt64VoidCallsCount += 1
        persistEventEnvelopesEventEnvelopesUpdateEventEnvelopeIndexInt64VoidReceivedArguments = (eventEnvelopes: eventEnvelopes, index: index)
        persistEventEnvelopesEventEnvelopesUpdateEventEnvelopeIndexInt64VoidReceivedInvocations.append((eventEnvelopes: eventEnvelopes, index: index))
        if let error = persistEventEnvelopesEventEnvelopesUpdateEventEnvelopeIndexInt64VoidThrowableError {
            throw error
        }
        try await persistEventEnvelopesEventEnvelopesUpdateEventEnvelopeIndexInt64VoidClosure?(eventEnvelopes, index)
    }

    //MARK: - fetchStoredEventEnvelopes

    public var fetchStoredEventEnvelopesLimitUInt_EnvelopeUpdateEventEnvelopeObjectIDNSManagedObjectIDThrowableError: (any Error)?
    public var fetchStoredEventEnvelopesLimitUInt_EnvelopeUpdateEventEnvelopeObjectIDNSManagedObjectIDCallsCount = 0
    public var fetchStoredEventEnvelopesLimitUInt_EnvelopeUpdateEventEnvelopeObjectIDNSManagedObjectIDCalled: Bool {
        return fetchStoredEventEnvelopesLimitUInt_EnvelopeUpdateEventEnvelopeObjectIDNSManagedObjectIDCallsCount > 0
    }
    public var fetchStoredEventEnvelopesLimitUInt_EnvelopeUpdateEventEnvelopeObjectIDNSManagedObjectIDReceivedLimit: (UInt)?
    public var fetchStoredEventEnvelopesLimitUInt_EnvelopeUpdateEventEnvelopeObjectIDNSManagedObjectIDReceivedInvocations: [(UInt)] = []
    public var fetchStoredEventEnvelopesLimitUInt_EnvelopeUpdateEventEnvelopeObjectIDNSManagedObjectIDReturnValue: [(envelope: UpdateEventEnvelope, objectID: NSManagedObjectID)]!
    public var fetchStoredEventEnvelopesLimitUInt_EnvelopeUpdateEventEnvelopeObjectIDNSManagedObjectIDClosure: ((UInt) async throws -> [(envelope: UpdateEventEnvelope, objectID: NSManagedObjectID)])?

    public func fetchStoredEventEnvelopes(limit: UInt) async throws -> [(envelope: UpdateEventEnvelope, objectID: NSManagedObjectID)] {
        fetchStoredEventEnvelopesLimitUInt_EnvelopeUpdateEventEnvelopeObjectIDNSManagedObjectIDCallsCount += 1
        fetchStoredEventEnvelopesLimitUInt_EnvelopeUpdateEventEnvelopeObjectIDNSManagedObjectIDReceivedLimit = limit
        fetchStoredEventEnvelopesLimitUInt_EnvelopeUpdateEventEnvelopeObjectIDNSManagedObjectIDReceivedInvocations.append(limit)
        if let error = fetchStoredEventEnvelopesLimitUInt_EnvelopeUpdateEventEnvelopeObjectIDNSManagedObjectIDThrowableError {
            throw error
        }
        if let fetchStoredEventEnvelopesLimitUInt_EnvelopeUpdateEventEnvelopeObjectIDNSManagedObjectIDClosure = fetchStoredEventEnvelopesLimitUInt_EnvelopeUpdateEventEnvelopeObjectIDNSManagedObjectIDClosure {
            return try await fetchStoredEventEnvelopesLimitUInt_EnvelopeUpdateEventEnvelopeObjectIDNSManagedObjectIDClosure(limit)
        } else {
            return fetchStoredEventEnvelopesLimitUInt_EnvelopeUpdateEventEnvelopeObjectIDNSManagedObjectIDReturnValue
        }
    }

    //MARK: - deleteNextPendingEvents

    public var deleteNextPendingEventsWithObjectIDsNSManagedObjectIDVoidThrowableError: (any Error)?
    public var deleteNextPendingEventsWithObjectIDsNSManagedObjectIDVoidCallsCount = 0
    public var deleteNextPendingEventsWithObjectIDsNSManagedObjectIDVoidCalled: Bool {
        return deleteNextPendingEventsWithObjectIDsNSManagedObjectIDVoidCallsCount > 0
    }
    public var deleteNextPendingEventsWithObjectIDsNSManagedObjectIDVoidReceivedObjectIDs: ([NSManagedObjectID])?
    public var deleteNextPendingEventsWithObjectIDsNSManagedObjectIDVoidReceivedInvocations: [([NSManagedObjectID])] = []
    public var deleteNextPendingEventsWithObjectIDsNSManagedObjectIDVoidClosure: (([NSManagedObjectID]) async throws -> Void)?

    public func deleteNextPendingEvents(with objectIDs: [NSManagedObjectID]) async throws {
        deleteNextPendingEventsWithObjectIDsNSManagedObjectIDVoidCallsCount += 1
        deleteNextPendingEventsWithObjectIDsNSManagedObjectIDVoidReceivedObjectIDs = objectIDs
        deleteNextPendingEventsWithObjectIDsNSManagedObjectIDVoidReceivedInvocations.append(objectIDs)
        if let error = deleteNextPendingEventsWithObjectIDsNSManagedObjectIDVoidThrowableError {
            throw error
        }
        try await deleteNextPendingEventsWithObjectIDsNSManagedObjectIDVoidClosure?(objectIDs)
    }

    //MARK: - deleteEventEnvelopes

    public var deleteEventEnvelopesAtIndexesInt64VoidThrowableError: (any Error)?
    public var deleteEventEnvelopesAtIndexesInt64VoidCallsCount = 0
    public var deleteEventEnvelopesAtIndexesInt64VoidCalled: Bool {
        return deleteEventEnvelopesAtIndexesInt64VoidCallsCount > 0
    }
    public var deleteEventEnvelopesAtIndexesInt64VoidReceivedIndexes: ([Int64])?
    public var deleteEventEnvelopesAtIndexesInt64VoidReceivedInvocations: [([Int64])] = []
    public var deleteEventEnvelopesAtIndexesInt64VoidClosure: (([Int64]) async throws -> Void)?

    public func deleteEventEnvelopes(at indexes: [Int64]) async throws {
        deleteEventEnvelopesAtIndexesInt64VoidCallsCount += 1
        deleteEventEnvelopesAtIndexesInt64VoidReceivedIndexes = indexes
        deleteEventEnvelopesAtIndexesInt64VoidReceivedInvocations.append(indexes)
        if let error = deleteEventEnvelopesAtIndexesInt64VoidThrowableError {
            throw error
        }
        try await deleteEventEnvelopesAtIndexesInt64VoidClosure?(indexes)
    }

    //MARK: - deleteEventEnvelope

    public var deleteEventEnvelopeAtIndexIndexInt64VoidThrowableError: (any Error)?
    public var deleteEventEnvelopeAtIndexIndexInt64VoidCallsCount = 0
    public var deleteEventEnvelopeAtIndexIndexInt64VoidCalled: Bool {
        return deleteEventEnvelopeAtIndexIndexInt64VoidCallsCount > 0
    }
    public var deleteEventEnvelopeAtIndexIndexInt64VoidReceivedIndex: (Int64)?
    public var deleteEventEnvelopeAtIndexIndexInt64VoidReceivedInvocations: [(Int64)] = []
    public var deleteEventEnvelopeAtIndexIndexInt64VoidClosure: ((Int64) async throws -> Void)?

    public func deleteEventEnvelope(atIndex index: Int64) async throws {
        deleteEventEnvelopeAtIndexIndexInt64VoidCallsCount += 1
        deleteEventEnvelopeAtIndexIndexInt64VoidReceivedIndex = index
        deleteEventEnvelopeAtIndexIndexInt64VoidReceivedInvocations.append(index)
        if let error = deleteEventEnvelopeAtIndexIndexInt64VoidThrowableError {
            throw error
        }
        try await deleteEventEnvelopeAtIndexIndexInt64VoidClosure?(index)
    }

    //MARK: - calculateLastUnreadMessages

    public var calculateLastUnreadMessagesVoidCallsCount = 0
    public var calculateLastUnreadMessagesVoidCalled: Bool {
        return calculateLastUnreadMessagesVoidCallsCount > 0
    }
    public var calculateLastUnreadMessagesVoidClosure: (() async -> Void)?

    public func calculateLastUnreadMessages() async {
        calculateLastUnreadMessagesVoidCallsCount += 1
        await calculateLastUnreadMessagesVoidClosure?()
    }

    //MARK: - storeServerTimeDelta

    public var storeServerTimeDeltaServerTimeDeltaTimeIntervalVoidCallsCount = 0
    public var storeServerTimeDeltaServerTimeDeltaTimeIntervalVoidCalled: Bool {
        return storeServerTimeDeltaServerTimeDeltaTimeIntervalVoidCallsCount > 0
    }
    public var storeServerTimeDeltaServerTimeDeltaTimeIntervalVoidReceivedServerTimeDelta: (TimeInterval)?
    public var storeServerTimeDeltaServerTimeDeltaTimeIntervalVoidReceivedInvocations: [(TimeInterval)] = []
    public var storeServerTimeDeltaServerTimeDeltaTimeIntervalVoidClosure: ((TimeInterval) async -> Void)?

    public func storeServerTimeDelta(_ serverTimeDelta: TimeInterval) async {
        storeServerTimeDeltaServerTimeDeltaTimeIntervalVoidCallsCount += 1
        storeServerTimeDeltaServerTimeDeltaTimeIntervalVoidReceivedServerTimeDelta = serverTimeDelta
        storeServerTimeDeltaServerTimeDeltaTimeIntervalVoidReceivedInvocations.append(serverTimeDelta)
        await storeServerTimeDeltaServerTimeDeltaTimeIntervalVoidClosure?(serverTimeDelta)
    }


}
public class UserClientsLocalStoreProtocolMock: UserClientsLocalStoreProtocol {

    public init() {}



    //MARK: - fetchOrCreateClient

    public var fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolCallsCount = 0
    public var fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolCalled: Bool {
        return fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolCallsCount > 0
    }
    public var fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolReceivedId: (String)?
    public var fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolReceivedInvocations: [(String)] = []
    public var fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolReturnValue: (client: WireDataModel.UserClient, isNew: Bool)!
    public var fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolClosure: ((String) async -> (client: WireDataModel.UserClient, isNew: Bool))?

    public func fetchOrCreateClient(id: String) async -> (client: WireDataModel.UserClient, isNew: Bool) {
        fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolCallsCount += 1
        fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolReceivedId = id
        fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolReceivedInvocations.append(id)
        if let fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolClosure = fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolClosure {
            return await fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolClosure(id)
        } else {
            return fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolReturnValue
        }
    }

    //MARK: - deletedSelfClients

    public var deletedSelfClientsNewClientsStringStringCallsCount = 0
    public var deletedSelfClientsNewClientsStringStringCalled: Bool {
        return deletedSelfClientsNewClientsStringStringCallsCount > 0
    }
    public var deletedSelfClientsNewClientsStringStringReceivedNewClients: ([String])?
    public var deletedSelfClientsNewClientsStringStringReceivedInvocations: [([String])] = []
    public var deletedSelfClientsNewClientsStringStringReturnValue: [String]!
    public var deletedSelfClientsNewClientsStringStringClosure: (([String]) async -> [String])?

    public func deletedSelfClients(newClients: [String]) async -> [String] {
        deletedSelfClientsNewClientsStringStringCallsCount += 1
        deletedSelfClientsNewClientsStringStringReceivedNewClients = newClients
        deletedSelfClientsNewClientsStringStringReceivedInvocations.append(newClients)
        if let deletedSelfClientsNewClientsStringStringClosure = deletedSelfClientsNewClientsStringStringClosure {
            return await deletedSelfClientsNewClientsStringStringClosure(newClients)
        } else {
            return deletedSelfClientsNewClientsStringStringReturnValue
        }
    }

    //MARK: - deleteClient

    public var deleteClientIdStringVoidCallsCount = 0
    public var deleteClientIdStringVoidCalled: Bool {
        return deleteClientIdStringVoidCallsCount > 0
    }
    public var deleteClientIdStringVoidReceivedId: (String)?
    public var deleteClientIdStringVoidReceivedInvocations: [(String)] = []
    public var deleteClientIdStringVoidClosure: ((String) async -> Void)?

    public func deleteClient(id: String) async {
        deleteClientIdStringVoidCallsCount += 1
        deleteClientIdStringVoidReceivedId = id
        deleteClientIdStringVoidReceivedInvocations.append(id)
        await deleteClientIdStringVoidClosure?(id)
    }

    //MARK: - invalidateSelfClient

    public var invalidateSelfClientVoidCallsCount = 0
    public var invalidateSelfClientVoidCalled: Bool {
        return invalidateSelfClientVoidCallsCount > 0
    }
    public var invalidateSelfClientVoidClosure: (() async -> Void)?

    public func invalidateSelfClient() async {
        invalidateSelfClientVoidCallsCount += 1
        await invalidateSelfClientVoidClosure?()
    }

    //MARK: - updateClient

    public var updateClientIdStringIsNewClientBoolUserClientInfoUserClientInfoVoidCallsCount = 0
    public var updateClientIdStringIsNewClientBoolUserClientInfoUserClientInfoVoidCalled: Bool {
        return updateClientIdStringIsNewClientBoolUserClientInfoUserClientInfoVoidCallsCount > 0
    }
    public var updateClientIdStringIsNewClientBoolUserClientInfoUserClientInfoVoidReceivedArguments: (id: String, isNewClient: Bool, userClientInfo: UserClientInfo)?
    public var updateClientIdStringIsNewClientBoolUserClientInfoUserClientInfoVoidReceivedInvocations: [(id: String, isNewClient: Bool, userClientInfo: UserClientInfo)] = []
    public var updateClientIdStringIsNewClientBoolUserClientInfoUserClientInfoVoidClosure: ((String, Bool, UserClientInfo) async -> Void)?

    public func updateClient(id: String, isNewClient: Bool, userClientInfo: UserClientInfo) async {
        updateClientIdStringIsNewClientBoolUserClientInfoUserClientInfoVoidCallsCount += 1
        updateClientIdStringIsNewClientBoolUserClientInfoUserClientInfoVoidReceivedArguments = (id: id, isNewClient: isNewClient, userClientInfo: userClientInfo)
        updateClientIdStringIsNewClientBoolUserClientInfoUserClientInfoVoidReceivedInvocations.append((id: id, isNewClient: isNewClient, userClientInfo: userClientInfo))
        await updateClientIdStringIsNewClientBoolUserClientInfoUserClientInfoVoidClosure?(id, isNewClient, userClientInfo)
    }

    //MARK: - allSelfUserClientsAreActiveMLSClients

    public var allSelfUserClientsAreActiveMLSClientsBoolCallsCount = 0
    public var allSelfUserClientsAreActiveMLSClientsBoolCalled: Bool {
        return allSelfUserClientsAreActiveMLSClientsBoolCallsCount > 0
    }
    public var allSelfUserClientsAreActiveMLSClientsBoolReturnValue: Bool!
    public var allSelfUserClientsAreActiveMLSClientsBoolClosure: (() async -> Bool)?

    public func allSelfUserClientsAreActiveMLSClients() async -> Bool {
        allSelfUserClientsAreActiveMLSClientsBoolCallsCount += 1
        if let allSelfUserClientsAreActiveMLSClientsBoolClosure = allSelfUserClientsAreActiveMLSClientsBoolClosure {
            return await allSelfUserClientsAreActiveMLSClientsBoolClosure()
        } else {
            return allSelfUserClientsAreActiveMLSClientsBoolReturnValue
        }
    }

    //MARK: - storeClient

    public var storeClientDiscoveryDateDateClientWireDataModelUserClientVoidCallsCount = 0
    public var storeClientDiscoveryDateDateClientWireDataModelUserClientVoidCalled: Bool {
        return storeClientDiscoveryDateDateClientWireDataModelUserClientVoidCallsCount > 0
    }
    public var storeClientDiscoveryDateDateClientWireDataModelUserClientVoidReceivedArguments: (discoveryDate: Date, client: WireDataModel.UserClient)?
    public var storeClientDiscoveryDateDateClientWireDataModelUserClientVoidReceivedInvocations: [(discoveryDate: Date, client: WireDataModel.UserClient)] = []
    public var storeClientDiscoveryDateDateClientWireDataModelUserClientVoidClosure: ((Date, WireDataModel.UserClient) async -> Void)?

    public func storeClient(discoveryDate: Date, client: WireDataModel.UserClient) async {
        storeClientDiscoveryDateDateClientWireDataModelUserClientVoidCallsCount += 1
        storeClientDiscoveryDateDateClientWireDataModelUserClientVoidReceivedArguments = (discoveryDate: discoveryDate, client: client)
        storeClientDiscoveryDateDateClientWireDataModelUserClientVoidReceivedInvocations.append((discoveryDate: discoveryDate, client: client))
        await storeClientDiscoveryDateDateClientWireDataModelUserClientVoidClosure?(discoveryDate, client)
    }

    //MARK: - addNewClientToIgnored

    public var addNewClientToIgnoredSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidCallsCount = 0
    public var addNewClientToIgnoredSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidCalled: Bool {
        return addNewClientToIgnoredSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidCallsCount > 0
    }
    public var addNewClientToIgnoredSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidReceivedArguments: (selfClient: WireDataModel.UserClient, newClient: WireDataModel.UserClient)?
    public var addNewClientToIgnoredSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidReceivedInvocations: [(selfClient: WireDataModel.UserClient, newClient: WireDataModel.UserClient)] = []
    public var addNewClientToIgnoredSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidClosure: ((WireDataModel.UserClient, WireDataModel.UserClient) async -> Void)?

    public func addNewClientToIgnored(selfClient: WireDataModel.UserClient, newClient: WireDataModel.UserClient) async {
        addNewClientToIgnoredSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidCallsCount += 1
        addNewClientToIgnoredSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidReceivedArguments = (selfClient: selfClient, newClient: newClient)
        addNewClientToIgnoredSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidReceivedInvocations.append((selfClient: selfClient, newClient: newClient))
        await addNewClientToIgnoredSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidClosure?(selfClient, newClient)
    }

    //MARK: - proteusSessionID

    public var proteusSessionIDForClientWireDataModelUserClientProteusSessionIDCallsCount = 0
    public var proteusSessionIDForClientWireDataModelUserClientProteusSessionIDCalled: Bool {
        return proteusSessionIDForClientWireDataModelUserClientProteusSessionIDCallsCount > 0
    }
    public var proteusSessionIDForClientWireDataModelUserClientProteusSessionIDReceivedClient: (WireDataModel.UserClient)?
    public var proteusSessionIDForClientWireDataModelUserClientProteusSessionIDReceivedInvocations: [(WireDataModel.UserClient)] = []
    public var proteusSessionIDForClientWireDataModelUserClientProteusSessionIDReturnValue: ProteusSessionID?
    public var proteusSessionIDForClientWireDataModelUserClientProteusSessionIDClosure: ((WireDataModel.UserClient) async -> ProteusSessionID?)?

    public func proteusSessionID(for client: WireDataModel.UserClient) async -> ProteusSessionID? {
        proteusSessionIDForClientWireDataModelUserClientProteusSessionIDCallsCount += 1
        proteusSessionIDForClientWireDataModelUserClientProteusSessionIDReceivedClient = client
        proteusSessionIDForClientWireDataModelUserClientProteusSessionIDReceivedInvocations.append(client)
        if let proteusSessionIDForClientWireDataModelUserClientProteusSessionIDClosure = proteusSessionIDForClientWireDataModelUserClientProteusSessionIDClosure {
            return await proteusSessionIDForClientWireDataModelUserClientProteusSessionIDClosure(client)
        } else {
            return proteusSessionIDForClientWireDataModelUserClientProteusSessionIDReturnValue
        }
    }

    //MARK: - clientSessionCreated

    public var clientSessionCreatedSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidCallsCount = 0
    public var clientSessionCreatedSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidCalled: Bool {
        return clientSessionCreatedSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidCallsCount > 0
    }
    public var clientSessionCreatedSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidReceivedArguments: (selfClient: WireDataModel.UserClient, newClient: WireDataModel.UserClient)?
    public var clientSessionCreatedSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidReceivedInvocations: [(selfClient: WireDataModel.UserClient, newClient: WireDataModel.UserClient)] = []
    public var clientSessionCreatedSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidClosure: ((WireDataModel.UserClient, WireDataModel.UserClient) async -> Void)?

    public func clientSessionCreated(selfClient: WireDataModel.UserClient, newClient: WireDataModel.UserClient) async {
        clientSessionCreatedSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidCallsCount += 1
        clientSessionCreatedSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidReceivedArguments = (selfClient: selfClient, newClient: newClient)
        clientSessionCreatedSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidReceivedInvocations.append((selfClient: selfClient, newClient: newClient))
        await clientSessionCreatedSelfClientWireDataModelUserClientNewClientWireDataModelUserClientVoidClosure?(selfClient, newClient)
    }

    //MARK: - fetchSelfClient

    public var fetchSelfClientWireDataModelUserClientCallsCount = 0
    public var fetchSelfClientWireDataModelUserClientCalled: Bool {
        return fetchSelfClientWireDataModelUserClientCallsCount > 0
    }
    public var fetchSelfClientWireDataModelUserClientReturnValue: WireDataModel.UserClient?
    public var fetchSelfClientWireDataModelUserClientClosure: (() async -> WireDataModel.UserClient?)?

    public func fetchSelfClient() async -> WireDataModel.UserClient? {
        fetchSelfClientWireDataModelUserClientCallsCount += 1
        if let fetchSelfClientWireDataModelUserClientClosure = fetchSelfClientWireDataModelUserClientClosure {
            return await fetchSelfClientWireDataModelUserClientClosure()
        } else {
            return fetchSelfClientWireDataModelUserClientReturnValue
        }
    }

    //MARK: - fetchClient

    public var fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientCallsCount = 0
    public var fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientCalled: Bool {
        return fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientCallsCount > 0
    }
    public var fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientReceivedArguments: (id: String, user: ZMUser, createIfNeeded: Bool)?
    public var fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientReceivedInvocations: [(id: String, user: ZMUser, createIfNeeded: Bool)] = []
    public var fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientReturnValue: WireDataModel.UserClient?
    public var fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientClosure: ((String, ZMUser, Bool) async -> WireDataModel.UserClient?)?

    public func fetchClient(id: String, forUser user: ZMUser, createIfNeeded: Bool) async -> WireDataModel.UserClient? {
        fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientCallsCount += 1
        fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientReceivedArguments = (id: id, user: user, createIfNeeded: createIfNeeded)
        fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientReceivedInvocations.append((id: id, user: user, createIfNeeded: createIfNeeded))
        if let fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientClosure = fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientClosure {
            return await fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientClosure(id, user, createIfNeeded)
        } else {
            return fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientReturnValue
        }
    }

    //MARK: - fetchSelfClientID

    public var fetchSelfClientIDStringCallsCount = 0
    public var fetchSelfClientIDStringCalled: Bool {
        return fetchSelfClientIDStringCallsCount > 0
    }
    public var fetchSelfClientIDStringReturnValue: String?
    public var fetchSelfClientIDStringClosure: (() async -> String?)?

    public func fetchSelfClientID() async -> String? {
        fetchSelfClientIDStringCallsCount += 1
        if let fetchSelfClientIDStringClosure = fetchSelfClientIDStringClosure {
            return await fetchSelfClientIDStringClosure()
        } else {
            return fetchSelfClientIDStringReturnValue
        }
    }

    //MARK: - hasRegisteredConsumableNotificationsCapable

    public var hasRegisteredConsumableNotificationsCapableBoolCallsCount = 0
    public var hasRegisteredConsumableNotificationsCapableBoolCalled: Bool {
        return hasRegisteredConsumableNotificationsCapableBoolCallsCount > 0
    }
    public var hasRegisteredConsumableNotificationsCapableBoolReturnValue: Bool!
    public var hasRegisteredConsumableNotificationsCapableBoolClosure: (() async -> Bool)?

    public func hasRegisteredConsumableNotificationsCapable() async -> Bool {
        hasRegisteredConsumableNotificationsCapableBoolCallsCount += 1
        if let hasRegisteredConsumableNotificationsCapableBoolClosure = hasRegisteredConsumableNotificationsCapableBoolClosure {
            return await hasRegisteredConsumableNotificationsCapableBoolClosure()
        } else {
            return hasRegisteredConsumableNotificationsCapableBoolReturnValue
        }
    }


}
public class UserClientsRepositoryProtocolMock: UserClientsRepositoryProtocol {

    public init() {}



    //MARK: - fetchSelfClient

    public var fetchSelfClientWireDataModelUserClientCallsCount = 0
    public var fetchSelfClientWireDataModelUserClientCalled: Bool {
        return fetchSelfClientWireDataModelUserClientCallsCount > 0
    }
    public var fetchSelfClientWireDataModelUserClientReturnValue: WireDataModel.UserClient?
    public var fetchSelfClientWireDataModelUserClientClosure: (() async -> WireDataModel.UserClient?)?

    public func fetchSelfClient() async -> WireDataModel.UserClient? {
        fetchSelfClientWireDataModelUserClientCallsCount += 1
        if let fetchSelfClientWireDataModelUserClientClosure = fetchSelfClientWireDataModelUserClientClosure {
            return await fetchSelfClientWireDataModelUserClientClosure()
        } else {
            return fetchSelfClientWireDataModelUserClientReturnValue
        }
    }

    //MARK: - pullSelfClients

    public var pullSelfClientsVoidThrowableError: (any Error)?
    public var pullSelfClientsVoidCallsCount = 0
    public var pullSelfClientsVoidCalled: Bool {
        return pullSelfClientsVoidCallsCount > 0
    }
    public var pullSelfClientsVoidClosure: (() async throws -> Void)?

    public func pullSelfClients() async throws {
        pullSelfClientsVoidCallsCount += 1
        if let error = pullSelfClientsVoidThrowableError {
            throw error
        }
        try await pullSelfClientsVoidClosure?()
    }

    //MARK: - fetchOrCreateClient

    public var fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolCallsCount = 0
    public var fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolCalled: Bool {
        return fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolCallsCount > 0
    }
    public var fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolReceivedId: (String)?
    public var fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolReceivedInvocations: [(String)] = []
    public var fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolReturnValue: (client: WireDataModel.UserClient, isNew: Bool)!
    public var fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolClosure: ((String) async -> (client: WireDataModel.UserClient, isNew: Bool))?

    public func fetchOrCreateClient(id: String) async -> (client: WireDataModel.UserClient, isNew: Bool) {
        fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolCallsCount += 1
        fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolReceivedId = id
        fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolReceivedInvocations.append(id)
        if let fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolClosure = fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolClosure {
            return await fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolClosure(id)
        } else {
            return fetchOrCreateClientIdString_ClientWireDataModelUserClientIsNewBoolReturnValue
        }
    }

    //MARK: - updateClient

    public var updateClientIdStringFromRemoteClientWireNetworkSelfUserClientIsNewClientBoolVoidCallsCount = 0
    public var updateClientIdStringFromRemoteClientWireNetworkSelfUserClientIsNewClientBoolVoidCalled: Bool {
        return updateClientIdStringFromRemoteClientWireNetworkSelfUserClientIsNewClientBoolVoidCallsCount > 0
    }
    public var updateClientIdStringFromRemoteClientWireNetworkSelfUserClientIsNewClientBoolVoidReceivedArguments: (id: String, remoteClient: WireNetwork.SelfUserClient, isNewClient: Bool)?
    public var updateClientIdStringFromRemoteClientWireNetworkSelfUserClientIsNewClientBoolVoidReceivedInvocations: [(id: String, remoteClient: WireNetwork.SelfUserClient, isNewClient: Bool)] = []
    public var updateClientIdStringFromRemoteClientWireNetworkSelfUserClientIsNewClientBoolVoidClosure: ((String, WireNetwork.SelfUserClient, Bool) async -> Void)?

    public func updateClient(id: String, from remoteClient: WireNetwork.SelfUserClient, isNewClient: Bool) async {
        updateClientIdStringFromRemoteClientWireNetworkSelfUserClientIsNewClientBoolVoidCallsCount += 1
        updateClientIdStringFromRemoteClientWireNetworkSelfUserClientIsNewClientBoolVoidReceivedArguments = (id: id, remoteClient: remoteClient, isNewClient: isNewClient)
        updateClientIdStringFromRemoteClientWireNetworkSelfUserClientIsNewClientBoolVoidReceivedInvocations.append((id: id, remoteClient: remoteClient, isNewClient: isNewClient))
        await updateClientIdStringFromRemoteClientWireNetworkSelfUserClientIsNewClientBoolVoidClosure?(id, remoteClient, isNewClient)
    }

    //MARK: - deleteClient

    public var deleteClientIdStringVoidCallsCount = 0
    public var deleteClientIdStringVoidCalled: Bool {
        return deleteClientIdStringVoidCallsCount > 0
    }
    public var deleteClientIdStringVoidReceivedId: (String)?
    public var deleteClientIdStringVoidReceivedInvocations: [(String)] = []
    public var deleteClientIdStringVoidClosure: ((String) async -> Void)?

    public func deleteClient(id: String) async {
        deleteClientIdStringVoidCallsCount += 1
        deleteClientIdStringVoidReceivedId = id
        deleteClientIdStringVoidReceivedInvocations.append(id)
        await deleteClientIdStringVoidClosure?(id)
    }

    //MARK: - invalidateSelfClient

    public var invalidateSelfClientVoidCallsCount = 0
    public var invalidateSelfClientVoidCalled: Bool {
        return invalidateSelfClientVoidCallsCount > 0
    }
    public var invalidateSelfClientVoidClosure: (() async -> Void)?

    public func invalidateSelfClient() async {
        invalidateSelfClientVoidCallsCount += 1
        await invalidateSelfClientVoidClosure?()
    }

    //MARK: - allSelfUserClientsAreActiveMLSClients

    public var allSelfUserClientsAreActiveMLSClientsBoolCallsCount = 0
    public var allSelfUserClientsAreActiveMLSClientsBoolCalled: Bool {
        return allSelfUserClientsAreActiveMLSClientsBoolCallsCount > 0
    }
    public var allSelfUserClientsAreActiveMLSClientsBoolReturnValue: Bool!
    public var allSelfUserClientsAreActiveMLSClientsBoolClosure: (() async -> Bool)?

    public func allSelfUserClientsAreActiveMLSClients() async -> Bool {
        allSelfUserClientsAreActiveMLSClientsBoolCallsCount += 1
        if let allSelfUserClientsAreActiveMLSClientsBoolClosure = allSelfUserClientsAreActiveMLSClientsBoolClosure {
            return await allSelfUserClientsAreActiveMLSClientsBoolClosure()
        } else {
            return allSelfUserClientsAreActiveMLSClientsBoolReturnValue
        }
    }

    //MARK: - fetchClient

    public var fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientCallsCount = 0
    public var fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientCalled: Bool {
        return fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientCallsCount > 0
    }
    public var fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientReceivedArguments: (id: String, user: ZMUser, createIfNeeded: Bool)?
    public var fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientReceivedInvocations: [(id: String, user: ZMUser, createIfNeeded: Bool)] = []
    public var fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientReturnValue: WireDataModel.UserClient?
    public var fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientClosure: ((String, ZMUser, Bool) async -> WireDataModel.UserClient?)?

    public func fetchClient(id: String, forUser user: ZMUser, createIfNeeded: Bool) async -> WireDataModel.UserClient? {
        fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientCallsCount += 1
        fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientReceivedArguments = (id: id, user: user, createIfNeeded: createIfNeeded)
        fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientReceivedInvocations.append((id: id, user: user, createIfNeeded: createIfNeeded))
        if let fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientClosure = fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientClosure {
            return await fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientClosure(id, user, createIfNeeded)
        } else {
            return fetchClientIdStringForUserUserZMUserCreateIfNeededBoolWireDataModelUserClientReturnValue
        }
    }


}
class UserEventNotificationBuilderProtocolMock: UserEventNotificationBuilderProtocol {




    //MARK: - buildContent

    var buildContentEventUserEventUserNotificationCallsCount = 0
    var buildContentEventUserEventUserNotificationCalled: Bool {
        return buildContentEventUserEventUserNotificationCallsCount > 0
    }
    var buildContentEventUserEventUserNotificationReceivedEvent: (UserEvent)?
    var buildContentEventUserEventUserNotificationReceivedInvocations: [(UserEvent)] = []
    var buildContentEventUserEventUserNotificationReturnValue: UserNotification?
    var buildContentEventUserEventUserNotificationClosure: ((UserEvent) async -> UserNotification?)?

    func buildContent(event: UserEvent) async -> UserNotification? {
        buildContentEventUserEventUserNotificationCallsCount += 1
        buildContentEventUserEventUserNotificationReceivedEvent = event
        buildContentEventUserEventUserNotificationReceivedInvocations.append(event)
        if let buildContentEventUserEventUserNotificationClosure = buildContentEventUserEventUserNotificationClosure {
            return await buildContentEventUserEventUserNotificationClosure(event)
        } else {
            return buildContentEventUserEventUserNotificationReturnValue
        }
    }


}
public class UserLocalStoreProtocolMock: UserLocalStoreProtocol {

    public init() {}



    //MARK: - fetchSelfUser

    public var fetchSelfUserZMUserCallsCount = 0
    public var fetchSelfUserZMUserCalled: Bool {
        return fetchSelfUserZMUserCallsCount > 0
    }
    public var fetchSelfUserZMUserReturnValue: ZMUser!
    public var fetchSelfUserZMUserClosure: (() async -> ZMUser)?

    public func fetchSelfUser() async -> ZMUser {
        fetchSelfUserZMUserCallsCount += 1
        if let fetchSelfUserZMUserClosure = fetchSelfUserZMUserClosure {
            return await fetchSelfUserZMUserClosure()
        } else {
            return fetchSelfUserZMUserReturnValue
        }
    }

    //MARK: - fetchUser

    public var fetchUserIdUUIDDomainStringZMUserThrowableError: (any Error)?
    public var fetchUserIdUUIDDomainStringZMUserCallsCount = 0
    public var fetchUserIdUUIDDomainStringZMUserCalled: Bool {
        return fetchUserIdUUIDDomainStringZMUserCallsCount > 0
    }
    public var fetchUserIdUUIDDomainStringZMUserReceivedArguments: (id: UUID, domain: String?)?
    public var fetchUserIdUUIDDomainStringZMUserReceivedInvocations: [(id: UUID, domain: String?)] = []
    public var fetchUserIdUUIDDomainStringZMUserReturnValue: ZMUser!
    public var fetchUserIdUUIDDomainStringZMUserClosure: ((UUID, String?) async throws -> ZMUser)?

    public func fetchUser(id: UUID, domain: String?) async throws -> ZMUser {
        fetchUserIdUUIDDomainStringZMUserCallsCount += 1
        fetchUserIdUUIDDomainStringZMUserReceivedArguments = (id: id, domain: domain)
        fetchUserIdUUIDDomainStringZMUserReceivedInvocations.append((id: id, domain: domain))
        if let error = fetchUserIdUUIDDomainStringZMUserThrowableError {
            throw error
        }
        if let fetchUserIdUUIDDomainStringZMUserClosure = fetchUserIdUUIDDomainStringZMUserClosure {
            return try await fetchUserIdUUIDDomainStringZMUserClosure(id, domain)
        } else {
            return fetchUserIdUUIDDomainStringZMUserReturnValue
        }
    }

    //MARK: - fetchOrCreateUser

    public var fetchOrCreateUserIdUUIDDomainStringZMUserCallsCount = 0
    public var fetchOrCreateUserIdUUIDDomainStringZMUserCalled: Bool {
        return fetchOrCreateUserIdUUIDDomainStringZMUserCallsCount > 0
    }
    public var fetchOrCreateUserIdUUIDDomainStringZMUserReceivedArguments: (id: UUID, domain: String?)?
    public var fetchOrCreateUserIdUUIDDomainStringZMUserReceivedInvocations: [(id: UUID, domain: String?)] = []
    public var fetchOrCreateUserIdUUIDDomainStringZMUserReturnValue: ZMUser!
    public var fetchOrCreateUserIdUUIDDomainStringZMUserClosure: ((UUID, String?) async -> ZMUser)?

    public func fetchOrCreateUser(id: UUID, domain: String?) async -> ZMUser {
        fetchOrCreateUserIdUUIDDomainStringZMUserCallsCount += 1
        fetchOrCreateUserIdUUIDDomainStringZMUserReceivedArguments = (id: id, domain: domain)
        fetchOrCreateUserIdUUIDDomainStringZMUserReceivedInvocations.append((id: id, domain: domain))
        if let fetchOrCreateUserIdUUIDDomainStringZMUserClosure = fetchOrCreateUserIdUUIDDomainStringZMUserClosure {
            return await fetchOrCreateUserIdUUIDDomainStringZMUserClosure(id, domain)
        } else {
            return fetchOrCreateUserIdUUIDDomainStringZMUserReturnValue
        }
    }

    //MARK: - fetchOrCreateUsers

    public var fetchOrCreateUsersUserIDsIdUUIDDomainStringSetZMUserCallsCount = 0
    public var fetchOrCreateUsersUserIDsIdUUIDDomainStringSetZMUserCalled: Bool {
        return fetchOrCreateUsersUserIDsIdUUIDDomainStringSetZMUserCallsCount > 0
    }
    public var fetchOrCreateUsersUserIDsIdUUIDDomainStringSetZMUserReceivedUserIDs: ([(id: UUID, domain: String?)])?
    public var fetchOrCreateUsersUserIDsIdUUIDDomainStringSetZMUserReceivedInvocations: [([(id: UUID, domain: String?)])] = []
    public var fetchOrCreateUsersUserIDsIdUUIDDomainStringSetZMUserReturnValue: Set<ZMUser>!
    public var fetchOrCreateUsersUserIDsIdUUIDDomainStringSetZMUserClosure: (([(id: UUID, domain: String?)]) async -> Set<ZMUser>)?

    public func fetchOrCreateUsers(userIDs: [(id: UUID, domain: String?)]) async -> Set<ZMUser> {
        fetchOrCreateUsersUserIDsIdUUIDDomainStringSetZMUserCallsCount += 1
        fetchOrCreateUsersUserIDsIdUUIDDomainStringSetZMUserReceivedUserIDs = userIDs
        fetchOrCreateUsersUserIDsIdUUIDDomainStringSetZMUserReceivedInvocations.append(userIDs)
        if let fetchOrCreateUsersUserIDsIdUUIDDomainStringSetZMUserClosure = fetchOrCreateUsersUserIDsIdUUIDDomainStringSetZMUserClosure {
            return await fetchOrCreateUsersUserIDsIdUUIDDomainStringSetZMUserClosure(userIDs)
        } else {
            return fetchOrCreateUsersUserIDsIdUUIDDomainStringSetZMUserReturnValue
        }
    }

    //MARK: - deletePushToken

    public var deletePushTokenVoidCallsCount = 0
    public var deletePushTokenVoidCalled: Bool {
        return deletePushTokenVoidCallsCount > 0
    }
    public var deletePushTokenVoidClosure: (() -> Void)?

    public func deletePushToken() {
        deletePushTokenVoidCallsCount += 1
        deletePushTokenVoidClosure?()
    }

    //MARK: - removeUserFromAllConversations

    public var removeUserFromAllConversationsIdUUIDDomainStringDateDateVoidCallsCount = 0
    public var removeUserFromAllConversationsIdUUIDDomainStringDateDateVoidCalled: Bool {
        return removeUserFromAllConversationsIdUUIDDomainStringDateDateVoidCallsCount > 0
    }
    public var removeUserFromAllConversationsIdUUIDDomainStringDateDateVoidReceivedArguments: (id: UUID, domain: String?, date: Date)?
    public var removeUserFromAllConversationsIdUUIDDomainStringDateDateVoidReceivedInvocations: [(id: UUID, domain: String?, date: Date)] = []
    public var removeUserFromAllConversationsIdUUIDDomainStringDateDateVoidClosure: ((UUID, String?, Date) async -> Void)?

    public func removeUserFromAllConversations(id: UUID, domain: String?, date: Date) async {
        removeUserFromAllConversationsIdUUIDDomainStringDateDateVoidCallsCount += 1
        removeUserFromAllConversationsIdUUIDDomainStringDateDateVoidReceivedArguments = (id: id, domain: domain, date: date)
        removeUserFromAllConversationsIdUUIDDomainStringDateDateVoidReceivedInvocations.append((id: id, domain: domain, date: date))
        await removeUserFromAllConversationsIdUUIDDomainStringDateDateVoidClosure?(id, domain, date)
    }

    //MARK: - addSelfLegalHoldRequest

    public var addSelfLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyWireDataModelLegalHoldRequestPrekeyVoidCallsCount = 0
    public var addSelfLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyWireDataModelLegalHoldRequestPrekeyVoidCalled: Bool {
        return addSelfLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyWireDataModelLegalHoldRequestPrekeyVoidCallsCount > 0
    }
    public var addSelfLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyWireDataModelLegalHoldRequestPrekeyVoidReceivedArguments: (userID: UUID, clientID: String, lastPrekey: WireDataModel.LegalHoldRequest.Prekey)?
    public var addSelfLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyWireDataModelLegalHoldRequestPrekeyVoidReceivedInvocations: [(userID: UUID, clientID: String, lastPrekey: WireDataModel.LegalHoldRequest.Prekey)] = []
    public var addSelfLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyWireDataModelLegalHoldRequestPrekeyVoidClosure: ((UUID, String, WireDataModel.LegalHoldRequest.Prekey) async -> Void)?

    public func addSelfLegalHoldRequest(userID: UUID, clientID: String, lastPrekey: WireDataModel.LegalHoldRequest.Prekey) async {
        addSelfLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyWireDataModelLegalHoldRequestPrekeyVoidCallsCount += 1
        addSelfLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyWireDataModelLegalHoldRequestPrekeyVoidReceivedArguments = (userID: userID, clientID: clientID, lastPrekey: lastPrekey)
        addSelfLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyWireDataModelLegalHoldRequestPrekeyVoidReceivedInvocations.append((userID: userID, clientID: clientID, lastPrekey: lastPrekey))
        await addSelfLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyWireDataModelLegalHoldRequestPrekeyVoidClosure?(userID, clientID, lastPrekey)
    }

    //MARK: - cancelSelfUserLegalholdRequest

    public var cancelSelfUserLegalholdRequestVoidCallsCount = 0
    public var cancelSelfUserLegalholdRequestVoidCalled: Bool {
        return cancelSelfUserLegalholdRequestVoidCallsCount > 0
    }
    public var cancelSelfUserLegalholdRequestVoidClosure: (() async -> Void)?

    public func cancelSelfUserLegalholdRequest() async {
        cancelSelfUserLegalholdRequestVoidCallsCount += 1
        await cancelSelfUserLegalholdRequestVoidClosure?()
    }

    //MARK: - updateSelfUserReadReceipts

    public var updateSelfUserReadReceiptsIsReadReceiptsEnabledBoolIsReadReceiptsEnabledChangedRemotelyBoolVoidCallsCount = 0
    public var updateSelfUserReadReceiptsIsReadReceiptsEnabledBoolIsReadReceiptsEnabledChangedRemotelyBoolVoidCalled: Bool {
        return updateSelfUserReadReceiptsIsReadReceiptsEnabledBoolIsReadReceiptsEnabledChangedRemotelyBoolVoidCallsCount > 0
    }
    public var updateSelfUserReadReceiptsIsReadReceiptsEnabledBoolIsReadReceiptsEnabledChangedRemotelyBoolVoidReceivedArguments: (isReadReceiptsEnabled: Bool, isReadReceiptsEnabledChangedRemotely: Bool)?
    public var updateSelfUserReadReceiptsIsReadReceiptsEnabledBoolIsReadReceiptsEnabledChangedRemotelyBoolVoidReceivedInvocations: [(isReadReceiptsEnabled: Bool, isReadReceiptsEnabledChangedRemotely: Bool)] = []
    public var updateSelfUserReadReceiptsIsReadReceiptsEnabledBoolIsReadReceiptsEnabledChangedRemotelyBoolVoidClosure: ((Bool, Bool) async -> Void)?

    public func updateSelfUserReadReceipts(isReadReceiptsEnabled: Bool, isReadReceiptsEnabledChangedRemotely: Bool) async {
        updateSelfUserReadReceiptsIsReadReceiptsEnabledBoolIsReadReceiptsEnabledChangedRemotelyBoolVoidCallsCount += 1
        updateSelfUserReadReceiptsIsReadReceiptsEnabledBoolIsReadReceiptsEnabledChangedRemotelyBoolVoidReceivedArguments = (isReadReceiptsEnabled: isReadReceiptsEnabled, isReadReceiptsEnabledChangedRemotely: isReadReceiptsEnabledChangedRemotely)
        updateSelfUserReadReceiptsIsReadReceiptsEnabledBoolIsReadReceiptsEnabledChangedRemotelyBoolVoidReceivedInvocations.append((isReadReceiptsEnabled: isReadReceiptsEnabled, isReadReceiptsEnabledChangedRemotely: isReadReceiptsEnabledChangedRemotely))
        await updateSelfUserReadReceiptsIsReadReceiptsEnabledBoolIsReadReceiptsEnabledChangedRemotelyBoolVoidClosure?(isReadReceiptsEnabled, isReadReceiptsEnabledChangedRemotely)
    }

    //MARK: - updateSelfUserSupportedProtocols

    public var updateSelfUserSupportedProtocolsSupportedProtocolsSetWireDataModelMessageProtocolVoidCallsCount = 0
    public var updateSelfUserSupportedProtocolsSupportedProtocolsSetWireDataModelMessageProtocolVoidCalled: Bool {
        return updateSelfUserSupportedProtocolsSupportedProtocolsSetWireDataModelMessageProtocolVoidCallsCount > 0
    }
    public var updateSelfUserSupportedProtocolsSupportedProtocolsSetWireDataModelMessageProtocolVoidReceivedSupportedProtocols: (Set<WireDataModel.MessageProtocol>)?
    public var updateSelfUserSupportedProtocolsSupportedProtocolsSetWireDataModelMessageProtocolVoidReceivedInvocations: [(Set<WireDataModel.MessageProtocol>)] = []
    public var updateSelfUserSupportedProtocolsSupportedProtocolsSetWireDataModelMessageProtocolVoidClosure: ((Set<WireDataModel.MessageProtocol>) async -> Void)?

    public func updateSelfUserSupportedProtocols(supportedProtocols: Set<WireDataModel.MessageProtocol>) async {
        updateSelfUserSupportedProtocolsSupportedProtocolsSetWireDataModelMessageProtocolVoidCallsCount += 1
        updateSelfUserSupportedProtocolsSupportedProtocolsSetWireDataModelMessageProtocolVoidReceivedSupportedProtocols = supportedProtocols
        updateSelfUserSupportedProtocolsSupportedProtocolsSetWireDataModelMessageProtocolVoidReceivedInvocations.append(supportedProtocols)
        await updateSelfUserSupportedProtocolsSupportedProtocolsSetWireDataModelMessageProtocolVoidClosure?(supportedProtocols)
    }

    //MARK: - fetchUsersQualifiedIDs

    public var fetchUsersQualifiedIDsWireDataModelQualifiedIDThrowableError: (any Error)?
    public var fetchUsersQualifiedIDsWireDataModelQualifiedIDCallsCount = 0
    public var fetchUsersQualifiedIDsWireDataModelQualifiedIDCalled: Bool {
        return fetchUsersQualifiedIDsWireDataModelQualifiedIDCallsCount > 0
    }
    public var fetchUsersQualifiedIDsWireDataModelQualifiedIDReturnValue: [WireDataModel.QualifiedID]!
    public var fetchUsersQualifiedIDsWireDataModelQualifiedIDClosure: (() async throws -> [WireDataModel.QualifiedID])?

    public func fetchUsersQualifiedIDs() async throws -> [WireDataModel.QualifiedID] {
        fetchUsersQualifiedIDsWireDataModelQualifiedIDCallsCount += 1
        if let error = fetchUsersQualifiedIDsWireDataModelQualifiedIDThrowableError {
            throw error
        }
        if let fetchUsersQualifiedIDsWireDataModelQualifiedIDClosure = fetchUsersQualifiedIDsWireDataModelQualifiedIDClosure {
            return try await fetchUsersQualifiedIDsWireDataModelQualifiedIDClosure()
        } else {
            return fetchUsersQualifiedIDsWireDataModelQualifiedIDReturnValue
        }
    }

    //MARK: - isSelfUser

    public var isSelfUserIdUUIDDomainString_UserZMUserIsSelfUserBoolThrowableError: (any Error)?
    public var isSelfUserIdUUIDDomainString_UserZMUserIsSelfUserBoolCallsCount = 0
    public var isSelfUserIdUUIDDomainString_UserZMUserIsSelfUserBoolCalled: Bool {
        return isSelfUserIdUUIDDomainString_UserZMUserIsSelfUserBoolCallsCount > 0
    }
    public var isSelfUserIdUUIDDomainString_UserZMUserIsSelfUserBoolReceivedArguments: (id: UUID, domain: String?)?
    public var isSelfUserIdUUIDDomainString_UserZMUserIsSelfUserBoolReceivedInvocations: [(id: UUID, domain: String?)] = []
    public var isSelfUserIdUUIDDomainString_UserZMUserIsSelfUserBoolReturnValue: (user: ZMUser, isSelfUser: Bool)!
    public var isSelfUserIdUUIDDomainString_UserZMUserIsSelfUserBoolClosure: ((UUID, String?) async throws -> (user: ZMUser, isSelfUser: Bool))?

    public func isSelfUser(id: UUID, domain: String?) async throws -> (user: ZMUser, isSelfUser: Bool) {
        isSelfUserIdUUIDDomainString_UserZMUserIsSelfUserBoolCallsCount += 1
        isSelfUserIdUUIDDomainString_UserZMUserIsSelfUserBoolReceivedArguments = (id: id, domain: domain)
        isSelfUserIdUUIDDomainString_UserZMUserIsSelfUserBoolReceivedInvocations.append((id: id, domain: domain))
        if let error = isSelfUserIdUUIDDomainString_UserZMUserIsSelfUserBoolThrowableError {
            throw error
        }
        if let isSelfUserIdUUIDDomainString_UserZMUserIsSelfUserBoolClosure = isSelfUserIdUUIDDomainString_UserZMUserIsSelfUserBoolClosure {
            return try await isSelfUserIdUUIDDomainString_UserZMUserIsSelfUserBoolClosure(id, domain)
        } else {
            return isSelfUserIdUUIDDomainString_UserZMUserIsSelfUserBoolReturnValue
        }
    }

    //MARK: - postAccountDeletedNotification

    public var postAccountDeletedNotificationVoidCallsCount = 0
    public var postAccountDeletedNotificationVoidCalled: Bool {
        return postAccountDeletedNotificationVoidCallsCount > 0
    }
    public var postAccountDeletedNotificationVoidClosure: (() -> Void)?

    public func postAccountDeletedNotification() {
        postAccountDeletedNotificationVoidCallsCount += 1
        postAccountDeletedNotificationVoidClosure?()
    }

    //MARK: - markAccountAsDeleted

    public var markAccountAsDeletedForUserZMUserVoidCallsCount = 0
    public var markAccountAsDeletedForUserZMUserVoidCalled: Bool {
        return markAccountAsDeletedForUserZMUserVoidCallsCount > 0
    }
    public var markAccountAsDeletedForUserZMUserVoidReceivedUser: (ZMUser)?
    public var markAccountAsDeletedForUserZMUserVoidReceivedInvocations: [(ZMUser)] = []
    public var markAccountAsDeletedForUserZMUserVoidClosure: ((ZMUser) async -> Void)?

    public func markAccountAsDeleted(for user: ZMUser) async {
        markAccountAsDeletedForUserZMUserVoidCallsCount += 1
        markAccountAsDeletedForUserZMUserVoidReceivedUser = user
        markAccountAsDeletedForUserZMUserVoidReceivedInvocations.append(user)
        await markAccountAsDeletedForUserZMUserVoidClosure?(user)
    }

    //MARK: - updateSelfUserTrackingID

    public var updateSelfUserTrackingIDTrackingIDUUIDConversationZMConversationVoidCallsCount = 0
    public var updateSelfUserTrackingIDTrackingIDUUIDConversationZMConversationVoidCalled: Bool {
        return updateSelfUserTrackingIDTrackingIDUUIDConversationZMConversationVoidCallsCount > 0
    }
    public var updateSelfUserTrackingIDTrackingIDUUIDConversationZMConversationVoidReceivedArguments: (trackingID: UUID, conversation: ZMConversation)?
    public var updateSelfUserTrackingIDTrackingIDUUIDConversationZMConversationVoidReceivedInvocations: [(trackingID: UUID, conversation: ZMConversation)] = []
    public var updateSelfUserTrackingIDTrackingIDUUIDConversationZMConversationVoidClosure: ((UUID, ZMConversation) async -> Void)?

    public func updateSelfUserTrackingID(trackingID: UUID, conversation: ZMConversation) async {
        updateSelfUserTrackingIDTrackingIDUUIDConversationZMConversationVoidCallsCount += 1
        updateSelfUserTrackingIDTrackingIDUUIDConversationZMConversationVoidReceivedArguments = (trackingID: trackingID, conversation: conversation)
        updateSelfUserTrackingIDTrackingIDUUIDConversationZMConversationVoidReceivedInvocations.append((trackingID: trackingID, conversation: conversation))
        await updateSelfUserTrackingIDTrackingIDUUIDConversationZMConversationVoidClosure?(trackingID, conversation)
    }

    //MARK: - persistUser

    public var persistUserUserInfoNewUserInfoVoidCallsCount = 0
    public var persistUserUserInfoNewUserInfoVoidCalled: Bool {
        return persistUserUserInfoNewUserInfoVoidCallsCount > 0
    }
    public var persistUserUserInfoNewUserInfoVoidReceivedUserInfo: (NewUserInfo)?
    public var persistUserUserInfoNewUserInfoVoidReceivedInvocations: [(NewUserInfo)] = []
    public var persistUserUserInfoNewUserInfoVoidClosure: ((NewUserInfo) async -> Void)?

    public func persistUser(userInfo: NewUserInfo) async {
        persistUserUserInfoNewUserInfoVoidCallsCount += 1
        persistUserUserInfoNewUserInfoVoidReceivedUserInfo = userInfo
        persistUserUserInfoNewUserInfoVoidReceivedInvocations.append(userInfo)
        await persistUserUserInfoNewUserInfoVoidClosure?(userInfo)
    }

    //MARK: - updateUser

    public var updateUserUserUpdateInfoUserUpdateInfoVoidCallsCount = 0
    public var updateUserUserUpdateInfoUserUpdateInfoVoidCalled: Bool {
        return updateUserUserUpdateInfoUserUpdateInfoVoidCallsCount > 0
    }
    public var updateUserUserUpdateInfoUserUpdateInfoVoidReceivedUserUpdateInfo: (UserUpdateInfo)?
    public var updateUserUserUpdateInfoUserUpdateInfoVoidReceivedInvocations: [(UserUpdateInfo)] = []
    public var updateUserUserUpdateInfoUserUpdateInfoVoidClosure: ((UserUpdateInfo) async -> Void)?

    public func updateUser(userUpdateInfo: UserUpdateInfo) async {
        updateUserUserUpdateInfoUserUpdateInfoVoidCallsCount += 1
        updateUserUserUpdateInfoUserUpdateInfoVoidReceivedUserUpdateInfo = userUpdateInfo
        updateUserUserUpdateInfoUserUpdateInfoVoidReceivedInvocations.append(userUpdateInfo)
        await updateUserUserUpdateInfoUserUpdateInfoVoidClosure?(userUpdateInfo)
    }

    //MARK: - fetchAllUserIDsWithOneOnOneConversation

    public var fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDThrowableError: (any Error)?
    public var fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDCallsCount = 0
    public var fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDCalled: Bool {
        return fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDCallsCount > 0
    }
    public var fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDReturnValue: [WireDataModel.QualifiedID]!
    public var fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDClosure: (() async throws -> [WireDataModel.QualifiedID])?

    public func fetchAllUserIDsWithOneOnOneConversation() async throws -> [WireDataModel.QualifiedID] {
        fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDCallsCount += 1
        if let error = fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDThrowableError {
            throw error
        }
        if let fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDClosure = fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDClosure {
            return try await fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDClosure()
        } else {
            return fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDReturnValue
        }
    }

    //MARK: - fetchSelfUserSupportedProtocols

    public var fetchSelfUserSupportedProtocolsSetWireDataModelMessageProtocolCallsCount = 0
    public var fetchSelfUserSupportedProtocolsSetWireDataModelMessageProtocolCalled: Bool {
        return fetchSelfUserSupportedProtocolsSetWireDataModelMessageProtocolCallsCount > 0
    }
    public var fetchSelfUserSupportedProtocolsSetWireDataModelMessageProtocolReturnValue: Set<WireDataModel.MessageProtocol>!
    public var fetchSelfUserSupportedProtocolsSetWireDataModelMessageProtocolClosure: (() async -> Set<WireDataModel.MessageProtocol>)?

    public func fetchSelfUserSupportedProtocols() async -> Set<WireDataModel.MessageProtocol> {
        fetchSelfUserSupportedProtocolsSetWireDataModelMessageProtocolCallsCount += 1
        if let fetchSelfUserSupportedProtocolsSetWireDataModelMessageProtocolClosure = fetchSelfUserSupportedProtocolsSetWireDataModelMessageProtocolClosure {
            return await fetchSelfUserSupportedProtocolsSetWireDataModelMessageProtocolClosure()
        } else {
            return fetchSelfUserSupportedProtocolsSetWireDataModelMessageProtocolReturnValue
        }
    }

    //MARK: - selfUserInfo

    public var selfUserInfo_IdUUIDClientIdStringCallsCount = 0
    public var selfUserInfo_IdUUIDClientIdStringCalled: Bool {
        return selfUserInfo_IdUUIDClientIdStringCallsCount > 0
    }
    public var selfUserInfo_IdUUIDClientIdStringReturnValue: (id: UUID, clientId: String?)!
    public var selfUserInfo_IdUUIDClientIdStringClosure: (() async -> (id: UUID, clientId: String?))?

    public func selfUserInfo() async -> (id: UUID, clientId: String?) {
        selfUserInfo_IdUUIDClientIdStringCallsCount += 1
        if let selfUserInfo_IdUUIDClientIdStringClosure = selfUserInfo_IdUUIDClientIdStringClosure {
            return await selfUserInfo_IdUUIDClientIdStringClosure()
        } else {
            return selfUserInfo_IdUUIDClientIdStringReturnValue
        }
    }

    //MARK: - name

    public var nameForUserZMUserStringCallsCount = 0
    public var nameForUserZMUserStringCalled: Bool {
        return nameForUserZMUserStringCallsCount > 0
    }
    public var nameForUserZMUserStringReceivedUser: (ZMUser)?
    public var nameForUserZMUserStringReceivedInvocations: [(ZMUser)] = []
    public var nameForUserZMUserStringReturnValue: String?
    public var nameForUserZMUserStringClosure: ((ZMUser) async -> String?)?

    public func name(for user: ZMUser) async -> String? {
        nameForUserZMUserStringCallsCount += 1
        nameForUserZMUserStringReceivedUser = user
        nameForUserZMUserStringReceivedInvocations.append(user)
        if let nameForUserZMUserStringClosure = nameForUserZMUserStringClosure {
            return await nameForUserZMUserStringClosure(user)
        } else {
            return nameForUserZMUserStringReturnValue
        }
    }

    //MARK: - teamName

    public var teamNameForUserZMUserStringCallsCount = 0
    public var teamNameForUserZMUserStringCalled: Bool {
        return teamNameForUserZMUserStringCallsCount > 0
    }
    public var teamNameForUserZMUserStringReceivedUser: (ZMUser)?
    public var teamNameForUserZMUserStringReceivedInvocations: [(ZMUser)] = []
    public var teamNameForUserZMUserStringReturnValue: String?
    public var teamNameForUserZMUserStringClosure: ((ZMUser) async -> String?)?

    public func teamName(for user: ZMUser) async -> String? {
        teamNameForUserZMUserStringCallsCount += 1
        teamNameForUserZMUserStringReceivedUser = user
        teamNameForUserZMUserStringReceivedInvocations.append(user)
        if let teamNameForUserZMUserStringClosure = teamNameForUserZMUserStringClosure {
            return await teamNameForUserZMUserStringClosure(user)
        } else {
            return teamNameForUserZMUserStringReturnValue
        }
    }

    //MARK: - id

    public var idForUserZMUserUuidCallsCount = 0
    public var idForUserZMUserUuidCalled: Bool {
        return idForUserZMUserUuidCallsCount > 0
    }
    public var idForUserZMUserUuidReceivedUser: (ZMUser)?
    public var idForUserZMUserUuidReceivedInvocations: [(ZMUser)] = []
    public var idForUserZMUserUuidReturnValue: UUID!
    public var idForUserZMUserUuidClosure: ((ZMUser) async -> UUID)?

    public func id(for user: ZMUser) async -> UUID {
        idForUserZMUserUuidCallsCount += 1
        idForUserZMUserUuidReceivedUser = user
        idForUserZMUserUuidReceivedInvocations.append(user)
        if let idForUserZMUserUuidClosure = idForUserZMUserUuidClosure {
            return await idForUserZMUserUuidClosure(user)
        } else {
            return idForUserZMUserUuidReturnValue
        }
    }

    //MARK: - fetchSelfUserAvailability

    public var fetchSelfUserAvailabilityAvailabilityCallsCount = 0
    public var fetchSelfUserAvailabilityAvailabilityCalled: Bool {
        return fetchSelfUserAvailabilityAvailabilityCallsCount > 0
    }
    public var fetchSelfUserAvailabilityAvailabilityReturnValue: Availability!
    public var fetchSelfUserAvailabilityAvailabilityClosure: (() async -> Availability)?

    public func fetchSelfUserAvailability() async -> Availability {
        fetchSelfUserAvailabilityAvailabilityCallsCount += 1
        if let fetchSelfUserAvailabilityAvailabilityClosure = fetchSelfUserAvailabilityAvailabilityClosure {
            return await fetchSelfUserAvailabilityAvailabilityClosure()
        } else {
            return fetchSelfUserAvailabilityAvailabilityReturnValue
        }
    }

    //MARK: - updateUser

    public var updateUserWithUserIDWireDataModelQualifiedIDAvailabilityAvailabilityVoidCallsCount = 0
    public var updateUserWithUserIDWireDataModelQualifiedIDAvailabilityAvailabilityVoidCalled: Bool {
        return updateUserWithUserIDWireDataModelQualifiedIDAvailabilityAvailabilityVoidCallsCount > 0
    }
    public var updateUserWithUserIDWireDataModelQualifiedIDAvailabilityAvailabilityVoidReceivedArguments: (userID: WireDataModel.QualifiedID, availability: Availability)?
    public var updateUserWithUserIDWireDataModelQualifiedIDAvailabilityAvailabilityVoidReceivedInvocations: [(userID: WireDataModel.QualifiedID, availability: Availability)] = []
    public var updateUserWithUserIDWireDataModelQualifiedIDAvailabilityAvailabilityVoidClosure: ((WireDataModel.QualifiedID, Availability) async -> Void)?

    public func updateUser(with userID: WireDataModel.QualifiedID, availability: Availability) async {
        updateUserWithUserIDWireDataModelQualifiedIDAvailabilityAvailabilityVoidCallsCount += 1
        updateUserWithUserIDWireDataModelQualifiedIDAvailabilityAvailabilityVoidReceivedArguments = (userID: userID, availability: availability)
        updateUserWithUserIDWireDataModelQualifiedIDAvailabilityAvailabilityVoidReceivedInvocations.append((userID: userID, availability: availability))
        await updateUserWithUserIDWireDataModelQualifiedIDAvailabilityAvailabilityVoidClosure?(userID, availability)
    }


}
public class UserRepositoryProtocolMock: UserRepositoryProtocol {

    public init() {}



    //MARK: - pullSelfUser

    public var pullSelfUserVoidThrowableError: (any Error)?
    public var pullSelfUserVoidCallsCount = 0
    public var pullSelfUserVoidCalled: Bool {
        return pullSelfUserVoidCallsCount > 0
    }
    public var pullSelfUserVoidClosure: (() async throws -> Void)?

    public func pullSelfUser() async throws {
        pullSelfUserVoidCallsCount += 1
        if let error = pullSelfUserVoidThrowableError {
            throw error
        }
        try await pullSelfUserVoidClosure?()
    }

    //MARK: - fetchSelfUser

    public var fetchSelfUserZMUserCallsCount = 0
    public var fetchSelfUserZMUserCalled: Bool {
        return fetchSelfUserZMUserCallsCount > 0
    }
    public var fetchSelfUserZMUserReturnValue: ZMUser!
    public var fetchSelfUserZMUserClosure: (() async -> ZMUser)?

    public func fetchSelfUser() async -> ZMUser {
        fetchSelfUserZMUserCallsCount += 1
        if let fetchSelfUserZMUserClosure = fetchSelfUserZMUserClosure {
            return await fetchSelfUserZMUserClosure()
        } else {
            return fetchSelfUserZMUserReturnValue
        }
    }

    //MARK: - fetchUser

    public var fetchUserIdUUIDDomainStringZMUserThrowableError: (any Error)?
    public var fetchUserIdUUIDDomainStringZMUserCallsCount = 0
    public var fetchUserIdUUIDDomainStringZMUserCalled: Bool {
        return fetchUserIdUUIDDomainStringZMUserCallsCount > 0
    }
    public var fetchUserIdUUIDDomainStringZMUserReceivedArguments: (id: UUID, domain: String?)?
    public var fetchUserIdUUIDDomainStringZMUserReceivedInvocations: [(id: UUID, domain: String?)] = []
    public var fetchUserIdUUIDDomainStringZMUserReturnValue: ZMUser!
    public var fetchUserIdUUIDDomainStringZMUserClosure: ((UUID, String?) async throws -> ZMUser)?

    public func fetchUser(id: UUID, domain: String?) async throws -> ZMUser {
        fetchUserIdUUIDDomainStringZMUserCallsCount += 1
        fetchUserIdUUIDDomainStringZMUserReceivedArguments = (id: id, domain: domain)
        fetchUserIdUUIDDomainStringZMUserReceivedInvocations.append((id: id, domain: domain))
        if let error = fetchUserIdUUIDDomainStringZMUserThrowableError {
            throw error
        }
        if let fetchUserIdUUIDDomainStringZMUserClosure = fetchUserIdUUIDDomainStringZMUserClosure {
            return try await fetchUserIdUUIDDomainStringZMUserClosure(id, domain)
        } else {
            return fetchUserIdUUIDDomainStringZMUserReturnValue
        }
    }

    //MARK: - pullKnownUsers

    public var pullKnownUsersVoidThrowableError: (any Error)?
    public var pullKnownUsersVoidCallsCount = 0
    public var pullKnownUsersVoidCalled: Bool {
        return pullKnownUsersVoidCallsCount > 0
    }
    public var pullKnownUsersVoidClosure: (() async throws -> Void)?

    public func pullKnownUsers() async throws {
        pullKnownUsersVoidCallsCount += 1
        if let error = pullKnownUsersVoidThrowableError {
            throw error
        }
        try await pullKnownUsersVoidClosure?()
    }

    //MARK: - pullUsers

    public var pullUsersUserIDsWireDataModelQualifiedIDVoidThrowableError: (any Error)?
    public var pullUsersUserIDsWireDataModelQualifiedIDVoidCallsCount = 0
    public var pullUsersUserIDsWireDataModelQualifiedIDVoidCalled: Bool {
        return pullUsersUserIDsWireDataModelQualifiedIDVoidCallsCount > 0
    }
    public var pullUsersUserIDsWireDataModelQualifiedIDVoidReceivedUserIDs: ([WireDataModel.QualifiedID])?
    public var pullUsersUserIDsWireDataModelQualifiedIDVoidReceivedInvocations: [([WireDataModel.QualifiedID])] = []
    public var pullUsersUserIDsWireDataModelQualifiedIDVoidClosure: (([WireDataModel.QualifiedID]) async throws -> Void)?

    public func pullUsers(userIDs: [WireDataModel.QualifiedID]) async throws {
        pullUsersUserIDsWireDataModelQualifiedIDVoidCallsCount += 1
        pullUsersUserIDsWireDataModelQualifiedIDVoidReceivedUserIDs = userIDs
        pullUsersUserIDsWireDataModelQualifiedIDVoidReceivedInvocations.append(userIDs)
        if let error = pullUsersUserIDsWireDataModelQualifiedIDVoidThrowableError {
            throw error
        }
        try await pullUsersUserIDsWireDataModelQualifiedIDVoidClosure?(userIDs)
    }

    //MARK: - updateUser

    public var updateUserFromEventUserUpdateEventVoidCallsCount = 0
    public var updateUserFromEventUserUpdateEventVoidCalled: Bool {
        return updateUserFromEventUserUpdateEventVoidCallsCount > 0
    }
    public var updateUserFromEventUserUpdateEventVoidReceivedEvent: (UserUpdateEvent)?
    public var updateUserFromEventUserUpdateEventVoidReceivedInvocations: [(UserUpdateEvent)] = []
    public var updateUserFromEventUserUpdateEventVoidClosure: ((UserUpdateEvent) async -> Void)?

    public func updateUser(from event: UserUpdateEvent) async {
        updateUserFromEventUserUpdateEventVoidCallsCount += 1
        updateUserFromEventUserUpdateEventVoidReceivedEvent = event
        updateUserFromEventUserUpdateEventVoidReceivedInvocations.append(event)
        await updateUserFromEventUserUpdateEventVoidClosure?(event)
    }

    //MARK: - fetchOrCreateUser

    public var fetchOrCreateUserIdUUIDDomainStringZMUserCallsCount = 0
    public var fetchOrCreateUserIdUUIDDomainStringZMUserCalled: Bool {
        return fetchOrCreateUserIdUUIDDomainStringZMUserCallsCount > 0
    }
    public var fetchOrCreateUserIdUUIDDomainStringZMUserReceivedArguments: (id: UUID, domain: String?)?
    public var fetchOrCreateUserIdUUIDDomainStringZMUserReceivedInvocations: [(id: UUID, domain: String?)] = []
    public var fetchOrCreateUserIdUUIDDomainStringZMUserReturnValue: ZMUser!
    public var fetchOrCreateUserIdUUIDDomainStringZMUserClosure: ((UUID, String?) async -> ZMUser)?

    public func fetchOrCreateUser(id: UUID, domain: String?) async -> ZMUser {
        fetchOrCreateUserIdUUIDDomainStringZMUserCallsCount += 1
        fetchOrCreateUserIdUUIDDomainStringZMUserReceivedArguments = (id: id, domain: domain)
        fetchOrCreateUserIdUUIDDomainStringZMUserReceivedInvocations.append((id: id, domain: domain))
        if let fetchOrCreateUserIdUUIDDomainStringZMUserClosure = fetchOrCreateUserIdUUIDDomainStringZMUserClosure {
            return await fetchOrCreateUserIdUUIDDomainStringZMUserClosure(id, domain)
        } else {
            return fetchOrCreateUserIdUUIDDomainStringZMUserReturnValue
        }
    }

    //MARK: - removePushToken

    public var removePushTokenVoidCallsCount = 0
    public var removePushTokenVoidCalled: Bool {
        return removePushTokenVoidCallsCount > 0
    }
    public var removePushTokenVoidClosure: (() -> Void)?

    public func removePushToken() {
        removePushTokenVoidCallsCount += 1
        removePushTokenVoidClosure?()
    }

    //MARK: - addLegalHoldRequest

    public var addLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyPrekeyVoidCallsCount = 0
    public var addLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyPrekeyVoidCalled: Bool {
        return addLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyPrekeyVoidCallsCount > 0
    }
    public var addLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyPrekeyVoidReceivedArguments: (userID: UUID, clientID: String, lastPrekey: Prekey)?
    public var addLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyPrekeyVoidReceivedInvocations: [(userID: UUID, clientID: String, lastPrekey: Prekey)] = []
    public var addLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyPrekeyVoidClosure: ((UUID, String, Prekey) async -> Void)?

    public func addLegalHoldRequest(userID: UUID, clientID: String, lastPrekey: Prekey) async {
        addLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyPrekeyVoidCallsCount += 1
        addLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyPrekeyVoidReceivedArguments = (userID: userID, clientID: clientID, lastPrekey: lastPrekey)
        addLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyPrekeyVoidReceivedInvocations.append((userID: userID, clientID: clientID, lastPrekey: lastPrekey))
        await addLegalHoldRequestUserIDUUIDClientIDStringLastPrekeyPrekeyVoidClosure?(userID, clientID, lastPrekey)
    }

    //MARK: - disableUserLegalHold

    public var disableUserLegalHoldVoidCallsCount = 0
    public var disableUserLegalHoldVoidCalled: Bool {
        return disableUserLegalHoldVoidCallsCount > 0
    }
    public var disableUserLegalHoldVoidClosure: (() async -> Void)?

    public func disableUserLegalHold() async {
        disableUserLegalHoldVoidCallsCount += 1
        await disableUserLegalHoldVoidClosure?()
    }

    //MARK: - updateUserProperty

    public var updateUserPropertyUserPropertyWireNetworkUserPropertyVoidThrowableError: (any Error)?
    public var updateUserPropertyUserPropertyWireNetworkUserPropertyVoidCallsCount = 0
    public var updateUserPropertyUserPropertyWireNetworkUserPropertyVoidCalled: Bool {
        return updateUserPropertyUserPropertyWireNetworkUserPropertyVoidCallsCount > 0
    }
    public var updateUserPropertyUserPropertyWireNetworkUserPropertyVoidReceivedUserProperty: (WireNetwork.UserProperty)?
    public var updateUserPropertyUserPropertyWireNetworkUserPropertyVoidReceivedInvocations: [(WireNetwork.UserProperty)] = []
    public var updateUserPropertyUserPropertyWireNetworkUserPropertyVoidClosure: ((WireNetwork.UserProperty) async throws -> Void)?

    public func updateUserProperty(_ userProperty: WireNetwork.UserProperty) async throws {
        updateUserPropertyUserPropertyWireNetworkUserPropertyVoidCallsCount += 1
        updateUserPropertyUserPropertyWireNetworkUserPropertyVoidReceivedUserProperty = userProperty
        updateUserPropertyUserPropertyWireNetworkUserPropertyVoidReceivedInvocations.append(userProperty)
        if let error = updateUserPropertyUserPropertyWireNetworkUserPropertyVoidThrowableError {
            throw error
        }
        try await updateUserPropertyUserPropertyWireNetworkUserPropertyVoidClosure?(userProperty)
    }

    //MARK: - deleteUserProperty

    public var deleteUserPropertyWithKeyKeyUserPropertyKeyVoidCallsCount = 0
    public var deleteUserPropertyWithKeyKeyUserPropertyKeyVoidCalled: Bool {
        return deleteUserPropertyWithKeyKeyUserPropertyKeyVoidCallsCount > 0
    }
    public var deleteUserPropertyWithKeyKeyUserPropertyKeyVoidReceivedKey: (UserProperty.Key)?
    public var deleteUserPropertyWithKeyKeyUserPropertyKeyVoidReceivedInvocations: [(UserProperty.Key)] = []
    public var deleteUserPropertyWithKeyKeyUserPropertyKeyVoidClosure: ((UserProperty.Key) async -> Void)?

    public func deleteUserProperty(withKey key: UserProperty.Key) async {
        deleteUserPropertyWithKeyKeyUserPropertyKeyVoidCallsCount += 1
        deleteUserPropertyWithKeyKeyUserPropertyKeyVoidReceivedKey = key
        deleteUserPropertyWithKeyKeyUserPropertyKeyVoidReceivedInvocations.append(key)
        await deleteUserPropertyWithKeyKeyUserPropertyKeyVoidClosure?(key)
    }

    //MARK: - deleteUserAccount

    public var deleteUserAccountIdUUIDDomainStringAtDateDateVoidThrowableError: (any Error)?
    public var deleteUserAccountIdUUIDDomainStringAtDateDateVoidCallsCount = 0
    public var deleteUserAccountIdUUIDDomainStringAtDateDateVoidCalled: Bool {
        return deleteUserAccountIdUUIDDomainStringAtDateDateVoidCallsCount > 0
    }
    public var deleteUserAccountIdUUIDDomainStringAtDateDateVoidReceivedArguments: (id: UUID, domain: String?, date: Date)?
    public var deleteUserAccountIdUUIDDomainStringAtDateDateVoidReceivedInvocations: [(id: UUID, domain: String?, date: Date)] = []
    public var deleteUserAccountIdUUIDDomainStringAtDateDateVoidClosure: ((UUID, String?, Date) async throws -> Void)?

    public func deleteUserAccount(id: UUID, domain: String?, at date: Date) async throws {
        deleteUserAccountIdUUIDDomainStringAtDateDateVoidCallsCount += 1
        deleteUserAccountIdUUIDDomainStringAtDateDateVoidReceivedArguments = (id: id, domain: domain, date: date)
        deleteUserAccountIdUUIDDomainStringAtDateDateVoidReceivedInvocations.append((id: id, domain: domain, date: date))
        if let error = deleteUserAccountIdUUIDDomainStringAtDateDateVoidThrowableError {
            throw error
        }
        try await deleteUserAccountIdUUIDDomainStringAtDateDateVoidClosure?(id, domain, date)
    }

    //MARK: - isSelfUser

    public var isSelfUserIdUUIDDomainStringBoolThrowableError: (any Error)?
    public var isSelfUserIdUUIDDomainStringBoolCallsCount = 0
    public var isSelfUserIdUUIDDomainStringBoolCalled: Bool {
        return isSelfUserIdUUIDDomainStringBoolCallsCount > 0
    }
    public var isSelfUserIdUUIDDomainStringBoolReceivedArguments: (id: UUID, domain: String?)?
    public var isSelfUserIdUUIDDomainStringBoolReceivedInvocations: [(id: UUID, domain: String?)] = []
    public var isSelfUserIdUUIDDomainStringBoolReturnValue: Bool!
    public var isSelfUserIdUUIDDomainStringBoolClosure: ((UUID, String?) async throws -> Bool)?

    public func isSelfUser(id: UUID, domain: String?) async throws -> Bool {
        isSelfUserIdUUIDDomainStringBoolCallsCount += 1
        isSelfUserIdUUIDDomainStringBoolReceivedArguments = (id: id, domain: domain)
        isSelfUserIdUUIDDomainStringBoolReceivedInvocations.append((id: id, domain: domain))
        if let error = isSelfUserIdUUIDDomainStringBoolThrowableError {
            throw error
        }
        if let isSelfUserIdUUIDDomainStringBoolClosure = isSelfUserIdUUIDDomainStringBoolClosure {
            return try await isSelfUserIdUUIDDomainStringBoolClosure(id, domain)
        } else {
            return isSelfUserIdUUIDDomainStringBoolReturnValue
        }
    }

    //MARK: - fetchAllUserIDsWithOneOnOneConversation

    public var fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDThrowableError: (any Error)?
    public var fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDCallsCount = 0
    public var fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDCalled: Bool {
        return fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDCallsCount > 0
    }
    public var fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDReturnValue: [WireDataModel.QualifiedID]!
    public var fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDClosure: (() async throws -> [WireDataModel.QualifiedID])?

    public func fetchAllUserIDsWithOneOnOneConversation() async throws -> [WireDataModel.QualifiedID] {
        fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDCallsCount += 1
        if let error = fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDThrowableError {
            throw error
        }
        if let fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDClosure = fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDClosure {
            return try await fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDClosure()
        } else {
            return fetchAllUserIDsWithOneOnOneConversationWireDataModelQualifiedIDReturnValue
        }
    }


}
public class WireCellsMessageAttachmentsDraftsLocalStoreProtocolMock: WireCellsMessageAttachmentsDraftsLocalStoreProtocol {

    public init() {}




}
