// Generated using Sourcery 2.2.4 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

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

// swiftlint:disable superfluous_disable_command
// swiftlint:disable vertical_whitespace
// swiftlint:disable line_length
// swiftlint:disable variable_name

public import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
public import UIKit
#elseif os(OSX)
public import AppKit
#endif

public import WireAPI
public import WireDataModel

@testable import WireDomain





















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

    public var storeConversationTimestampIsFederationEnabled_Invocations: [(conversation: WireAPI.Conversation, timestamp: Date, isFederationEnabled: Bool)] = []
    public var storeConversationTimestampIsFederationEnabled_MockMethod: ((WireAPI.Conversation, Date, Bool) async -> Void)?

    public func storeConversation(_ conversation: WireAPI.Conversation, timestamp: Date, isFederationEnabled: Bool) async {
        storeConversationTimestampIsFederationEnabled_Invocations.append((conversation: conversation, timestamp: timestamp, isFederationEnabled: isFederationEnabled))

        guard let mock = storeConversationTimestampIsFederationEnabled_MockMethod else {
            fatalError("no mock for `storeConversationTimestampIsFederationEnabled`")
        }

        await mock(conversation, timestamp, isFederationEnabled)
    }

    // MARK: - storeConversation

    public var storeConversationNeedsBackendUpdateQualifiedId_Invocations: [(needsBackendUpdate: Bool, qualifiedId: WireAPI.QualifiedID)] = []
    public var storeConversationNeedsBackendUpdateQualifiedId_MockMethod: ((Bool, WireAPI.QualifiedID) async -> Void)?

    public func storeConversation(needsBackendUpdate: Bool, qualifiedId: WireAPI.QualifiedID) async {
        storeConversationNeedsBackendUpdateQualifiedId_Invocations.append((needsBackendUpdate: needsBackendUpdate, qualifiedId: qualifiedId))

        guard let mock = storeConversationNeedsBackendUpdateQualifiedId_MockMethod else {
            fatalError("no mock for `storeConversationNeedsBackendUpdateQualifiedId`")
        }

        await mock(needsBackendUpdate, qualifiedId)
    }

    // MARK: - storeFailedConversation

    public var storeFailedConversationWithQualifiedId_Invocations: [WireAPI.QualifiedID] = []
    public var storeFailedConversationWithQualifiedId_MockMethod: ((WireAPI.QualifiedID) async -> Void)?

    public func storeFailedConversation(withQualifiedId qualifiedId: WireAPI.QualifiedID) async {
        storeFailedConversationWithQualifiedId_Invocations.append(qualifiedId)

        guard let mock = storeFailedConversationWithQualifiedId_MockMethod else {
            fatalError("no mock for `storeFailedConversationWithQualifiedId`")
        }

        await mock(qualifiedId)
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

    public var removeParticipantFromAllGroupConversationsUserDate_Invocations: [(user: ZMUser, date: Date)] = []
    public var removeParticipantFromAllGroupConversationsUserDate_MockMethod: ((ZMUser, Date) async -> Void)?

    public func removeParticipantFromAllGroupConversations(user: ZMUser, date: Date) async {
        removeParticipantFromAllGroupConversationsUserDate_Invocations.append((user: user, date: date))

        guard let mock = removeParticipantFromAllGroupConversationsUserDate_MockMethod else {
            fatalError("no mock for `removeParticipantFromAllGroupConversationsUserDate`")
        }

        await mock(user, date)
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

    public var addParticipantsAddedByAtDateTo_Invocations: [(participants: [(id: UUID, domain: String?, role: String?)], sender: (id: UUID, domain: String?), date: Date, conversation: ZMConversation)] = []
    public var addParticipantsAddedByAtDateTo_MockError: Error?
    public var addParticipantsAddedByAtDateTo_MockMethod: (([(id: UUID, domain: String?, role: String?)], (id: UUID, domain: String?), Date, ZMConversation) async throws -> Void)?

    public func addParticipants(_ participants: [(id: UUID, domain: String?, role: String?)], addedBy sender: (id: UUID, domain: String?), atDate date: Date, to conversation: ZMConversation) async throws {
        addParticipantsAddedByAtDateTo_Invocations.append((participants: participants, sender: sender, date: date, conversation: conversation))

        if let error = addParticipantsAddedByAtDateTo_MockError {
            throw error
        }

        guard let mock = addParticipantsAddedByAtDateTo_MockMethod else {
            fatalError("no mock for `addParticipantsAddedByAtDateTo`")
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

    // MARK: - addSystemMessage

    public var addSystemMessageTo_Invocations: [(message: SystemMessage, conversation: ZMConversation)] = []
    public var addSystemMessageTo_MockMethod: ((SystemMessage, ZMConversation) async -> Void)?

    public func addSystemMessage(_ message: SystemMessage, to conversation: ZMConversation) async {
        addSystemMessageTo_Invocations.append((message: message, conversation: conversation))

        guard let mock = addSystemMessageTo_MockMethod else {
            fatalError("no mock for `addSystemMessageTo`")
        }

        await mock(message, conversation)
    }

    // MARK: - conversationMutedMessageTypes

    public var conversationMutedMessageTypes_Invocations: [ZMConversation] = []
    public var conversationMutedMessageTypes_MockMethod: ((ZMConversation) async -> MutedMessageTypes)?
    public var conversationMutedMessageTypes_MockValue: MutedMessageTypes?

    public func conversationMutedMessageTypes(_ conversation: ZMConversation) async -> MutedMessageTypes {
        conversationMutedMessageTypes_Invocations.append(conversation)

        if let mock = conversationMutedMessageTypes_MockMethod {
            return await mock(conversation)
        } else if let mock = conversationMutedMessageTypes_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationMutedMessageTypes`")
        }
    }

    // MARK: - storeConversation

    public var storeConversationIsArchivedFor_Invocations: [(isArchived: Bool, conversation: ZMConversation)] = []
    public var storeConversationIsArchivedFor_MockMethod: ((Bool, ZMConversation) async -> Void)?

    public func storeConversation(isArchived: Bool, for conversation: ZMConversation) async {
        storeConversationIsArchivedFor_Invocations.append((isArchived: isArchived, conversation: conversation))

        guard let mock = storeConversationIsArchivedFor_MockMethod else {
            fatalError("no mock for `storeConversationIsArchivedFor`")
        }

        await mock(isArchived, conversation)
    }

    // MARK: - isConversationArchived

    public var isConversationArchived_Invocations: [ZMConversation] = []
    public var isConversationArchived_MockMethod: ((ZMConversation) async -> Bool)?
    public var isConversationArchived_MockValue: Bool?

    public func isConversationArchived(_ conversation: ZMConversation) async -> Bool {
        isConversationArchived_Invocations.append(conversation)

        if let mock = isConversationArchived_MockMethod {
            return await mock(conversation)
        } else if let mock = isConversationArchived_MockValue {
            return mock
        } else {
            fatalError("no mock for `isConversationArchived`")
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

    // MARK: - isMLSConversation

    public var isMLSConversation_Invocations: [ZMConversation] = []
    public var isMLSConversation_MockMethod: ((ZMConversation) async -> Bool)?
    public var isMLSConversation_MockValue: Bool?

    public func isMLSConversation(_ conversation: ZMConversation) async -> Bool {
        isMLSConversation_Invocations.append(conversation)

        if let mock = isMLSConversation_MockMethod {
            return await mock(conversation)
        } else if let mock = isMLSConversation_MockValue {
            return mock
        } else {
            fatalError("no mock for `isMLSConversation`")
        }
    }

    // MARK: - mlsGroupID

    public var mlsGroupIDFor_Invocations: [ZMConversation] = []
    public var mlsGroupIDFor_MockMethod: ((ZMConversation) async -> MLSGroupID?)?
    public var mlsGroupIDFor_MockValue: MLSGroupID??

    public func mlsGroupID(for conversation: ZMConversation) async -> MLSGroupID? {
        mlsGroupIDFor_Invocations.append(conversation)

        if let mock = mlsGroupIDFor_MockMethod {
            return await mock(conversation)
        } else if let mock = mlsGroupIDFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `mlsGroupIDFor`")
        }
    }

    // MARK: - updateTypingUsers

    public var updateTypingUsersConversationIDUsersID_Invocations: [(conversationID: NSManagedObjectID, usersID: Set<NSManagedObjectID>)] = []
    public var updateTypingUsersConversationIDUsersID_MockMethod: ((NSManagedObjectID, Set<NSManagedObjectID>) async -> Void)?

    public func updateTypingUsers(conversationID: NSManagedObjectID, usersID: Set<NSManagedObjectID>) async {
        updateTypingUsersConversationIDUsersID_Invocations.append((conversationID: conversationID, usersID: usersID))

        guard let mock = updateTypingUsersConversationIDUsersID_MockMethod else {
            fatalError("no mock for `updateTypingUsersConversationIDUsersID`")
        }

        await mock(conversationID, usersID)
    }

    // MARK: - obtainPermanentIDs

    public var obtainPermanentIDsUserConversation_Invocations: [(user: ZMUser, conversation: ZMConversation)] = []
    public var obtainPermanentIDsUserConversation_MockMethod: ((ZMUser, ZMConversation) -> Void)?

    public func obtainPermanentIDs(user: ZMUser, conversation: ZMConversation) {
        obtainPermanentIDsUserConversation_Invocations.append((user: user, conversation: conversation))

        guard let mock = obtainPermanentIDsUserConversation_MockMethod else {
            fatalError("no mock for `obtainPermanentIDsUserConversation`")
        }

        mock(user, conversation)
    }

}

public class MockConversationRepositoryProtocol: ConversationRepositoryProtocol {

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

    public var storeConversationTimestamp_Invocations: [(conversation: WireAPI.Conversation, timestamp: Date)] = []
    public var storeConversationTimestamp_MockMethod: ((WireAPI.Conversation, Date) async -> Void)?

    public func storeConversation(_ conversation: WireAPI.Conversation, timestamp: Date) async {
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

    // MARK: - pullConversations

    public var pullConversations_Invocations: [Void] = []
    public var pullConversations_MockError: Error?
    public var pullConversations_MockMethod: (() async throws -> Void)?

    public func pullConversations() async throws {
        pullConversations_Invocations.append(())

        if let error = pullConversations_MockError {
            throw error
        }

        guard let mock = pullConversations_MockMethod else {
            fatalError("no mock for `pullConversations`")
        }

        try await mock()
    }

    // MARK: - pullMLSOneToOneConversation

    public var pullMLSOneToOneConversationUserIDUserDomain_Invocations: [(userID: String, userDomain: String)] = []
    public var pullMLSOneToOneConversationUserIDUserDomain_MockError: Error?
    public var pullMLSOneToOneConversationUserIDUserDomain_MockMethod: ((String, String) async throws -> String)?
    public var pullMLSOneToOneConversationUserIDUserDomain_MockValue: String?

    public func pullMLSOneToOneConversation(userID: String, userDomain: String) async throws -> String {
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

    // MARK: - addSystemMessage

    public var addSystemMessageTo_Invocations: [(message: SystemMessage, conversation: ZMConversation)] = []
    public var addSystemMessageTo_MockMethod: ((SystemMessage, ZMConversation) async -> Void)?

    public func addSystemMessage(_ message: SystemMessage, to conversation: ZMConversation) async {
        addSystemMessageTo_Invocations.append((message: message, conversation: conversation))

        guard let mock = addSystemMessageTo_MockMethod else {
            fatalError("no mock for `addSystemMessageTo`")
        }

        await mock(message, conversation)
    }

    // MARK: - updateTypingUsers

    public var updateTypingUsers_Invocations: [[ConversationTypingUsersInfo]] = []
    public var updateTypingUsers_MockMethod: (([ConversationTypingUsersInfo]) async -> Void)?

    public func updateTypingUsers(_ typingUsersInfo: [ConversationTypingUsersInfo]) async {
        updateTypingUsers_Invocations.append(typingUsersInfo)

        guard let mock = updateTypingUsers_MockMethod else {
            fatalError("no mock for `updateTypingUsers`")
        }

        await mock(typingUsersInfo)
    }

}

public class MockMessageLocalStoreProtocol: MessageLocalStoreProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - addSystemMessageToConversation

    public var addSystemMessageToConversationMessageTypeConversationIDConversationDomain_Invocations: [(messageType: MessageType, conversationID: UUID, conversationDomain: String?)] = []
    public var addSystemMessageToConversationMessageTypeConversationIDConversationDomain_MockMethod: ((MessageType, UUID, String?) async -> Void)?

    public func addSystemMessageToConversation(messageType: MessageType, conversationID: UUID, conversationDomain: String?) async {
        addSystemMessageToConversationMessageTypeConversationIDConversationDomain_Invocations.append((messageType: messageType, conversationID: conversationID, conversationDomain: conversationDomain))

        guard let mock = addSystemMessageToConversationMessageTypeConversationIDConversationDomain_MockMethod else {
            fatalError("no mock for `addSystemMessageToConversationMessageTypeConversationIDConversationDomain`")
        }

        await mock(messageType, conversationID, conversationDomain)
    }

}

public class MockMessageRepositoryProtocol: MessageRepositoryProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - addMessageToConversation

    public var addMessageToConversationMessageTypeConversationIDConversationDomain_Invocations: [(messageType: MessageType, conversationID: UUID, conversationDomain: String?)] = []
    public var addMessageToConversationMessageTypeConversationIDConversationDomain_MockMethod: ((MessageType, UUID, String?) async -> Void)?

    public func addMessageToConversation(messageType: MessageType, conversationID: UUID, conversationDomain: String?) async {
        addMessageToConversationMessageTypeConversationIDConversationDomain_Invocations.append((messageType: messageType, conversationID: conversationID, conversationDomain: conversationDomain))

        guard let mock = addMessageToConversationMessageTypeConversationIDConversationDomain_MockMethod else {
            fatalError("no mock for `addMessageToConversationMessageTypeConversationIDConversationDomain`")
        }

        await mock(messageType, conversationID, conversationDomain)
    }

}

public class MockOneOnOneResolverProtocol: OneOnOneResolverProtocol {

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

class MockProteusMessageDecryptorProtocol: ProteusMessageDecryptorProtocol {

    // MARK: - Life cycle



    // MARK: - decryptedEventData

    var decryptedEventDataFrom_Invocations: [ConversationProteusMessageAddEvent] = []
    var decryptedEventDataFrom_MockError: Error?
    var decryptedEventDataFrom_MockMethod: ((ConversationProteusMessageAddEvent) async throws -> ConversationProteusMessageAddEvent)?
    var decryptedEventDataFrom_MockValue: ConversationProteusMessageAddEvent?

    func decryptedEventData(from eventData: ConversationProteusMessageAddEvent) async throws -> ConversationProteusMessageAddEvent {
        decryptedEventDataFrom_Invocations.append(eventData)

        if let error = decryptedEventDataFrom_MockError {
            throw error
        }

        if let mock = decryptedEventDataFrom_MockMethod {
            return try await mock(eventData)
        } else if let mock = decryptedEventDataFrom_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptedEventDataFrom`")
        }
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

    // MARK: - fetchSelfLegalholdStatus

    public var fetchSelfLegalholdStatus_Invocations: [Void] = []
    public var fetchSelfLegalholdStatus_MockError: Error?
    public var fetchSelfLegalholdStatus_MockMethod: (() async throws -> LegalholdStatus)?
    public var fetchSelfLegalholdStatus_MockValue: LegalholdStatus?

    public func fetchSelfLegalholdStatus() async throws -> LegalholdStatus {
        fetchSelfLegalholdStatus_Invocations.append(())

        if let error = fetchSelfLegalholdStatus_MockError {
            throw error
        }

        if let mock = fetchSelfLegalholdStatus_MockMethod {
            return try await mock()
        } else if let mock = fetchSelfLegalholdStatus_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfLegalholdStatus`")
        }
    }

    // MARK: - deleteMembership

    public var deleteMembershipForDomainAt_Invocations: [(userID: UUID, domain: String?, time: Date)] = []
    public var deleteMembershipForDomainAt_MockError: Error?
    public var deleteMembershipForDomainAt_MockMethod: ((UUID, String?, Date) async throws -> Void)?

    public func deleteMembership(for userID: UUID, domain: String?, at time: Date) async throws {
        deleteMembershipForDomainAt_Invocations.append((userID: userID, domain: domain, time: time))

        if let error = deleteMembershipForDomainAt_MockError {
            throw error
        }

        guard let mock = deleteMembershipForDomainAt_MockMethod else {
            fatalError("no mock for `deleteMembershipForDomainAt`")
        }

        try await mock(userID, domain, time)
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

}

class MockUpdateEventDecryptorProtocol: UpdateEventDecryptorProtocol {

    // MARK: - Life cycle



    // MARK: - decryptEvents

    var decryptEventsIn_Invocations: [UpdateEventEnvelope] = []
    var decryptEventsIn_MockError: Error?
    var decryptEventsIn_MockMethod: ((UpdateEventEnvelope) async throws -> [UpdateEvent])?
    var decryptEventsIn_MockValue: [UpdateEvent]?

    func decryptEvents(in eventEnvelope: UpdateEventEnvelope) async throws -> [UpdateEvent] {
        decryptEventsIn_Invocations.append(eventEnvelope)

        if let error = decryptEventsIn_MockError {
            throw error
        }

        if let mock = decryptEventsIn_MockMethod {
            return try await mock(eventEnvelope)
        } else if let mock = decryptEventsIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptEventsIn`")
        }
    }

}

class MockUpdateEventProcessorProtocol: UpdateEventProcessorProtocol {

    // MARK: - Life cycle



    // MARK: - processEvent

    var processEvent_Invocations: [UpdateEvent] = []
    var processEvent_MockError: Error?
    var processEvent_MockMethod: ((UpdateEvent) async throws -> Void)?

    func processEvent(_ event: UpdateEvent) async throws {
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

class MockUpdateEventsRepositoryProtocol: UpdateEventsRepositoryProtocol {

    // MARK: - Life cycle



    // MARK: - pullPendingEvents

    var pullPendingEvents_Invocations: [Void] = []
    var pullPendingEvents_MockError: Error?
    var pullPendingEvents_MockMethod: (() async throws -> Void)?

    func pullPendingEvents() async throws {
        pullPendingEvents_Invocations.append(())

        if let error = pullPendingEvents_MockError {
            throw error
        }

        guard let mock = pullPendingEvents_MockMethod else {
            fatalError("no mock for `pullPendingEvents`")
        }

        try await mock()
    }

    // MARK: - fetchNextPendingEvents

    var fetchNextPendingEventsLimit_Invocations: [UInt] = []
    var fetchNextPendingEventsLimit_MockError: Error?
    var fetchNextPendingEventsLimit_MockMethod: ((UInt) async throws -> [UpdateEventEnvelope])?
    var fetchNextPendingEventsLimit_MockValue: [UpdateEventEnvelope]?

    func fetchNextPendingEvents(limit: UInt) async throws -> [UpdateEventEnvelope] {
        fetchNextPendingEventsLimit_Invocations.append(limit)

        if let error = fetchNextPendingEventsLimit_MockError {
            throw error
        }

        if let mock = fetchNextPendingEventsLimit_MockMethod {
            return try await mock(limit)
        } else if let mock = fetchNextPendingEventsLimit_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchNextPendingEventsLimit`")
        }
    }

    // MARK: - deleteNextPendingEvents

    var deleteNextPendingEventsLimit_Invocations: [UInt] = []
    var deleteNextPendingEventsLimit_MockError: Error?
    var deleteNextPendingEventsLimit_MockMethod: ((UInt) async throws -> Void)?

    func deleteNextPendingEvents(limit: UInt) async throws {
        deleteNextPendingEventsLimit_Invocations.append(limit)

        if let error = deleteNextPendingEventsLimit_MockError {
            throw error
        }

        guard let mock = deleteNextPendingEventsLimit_MockMethod else {
            fatalError("no mock for `deleteNextPendingEventsLimit`")
        }

        try await mock(limit)
    }

    // MARK: - startBufferingLiveEvents

    var startBufferingLiveEvents_Invocations: [Void] = []
    var startBufferingLiveEvents_MockError: Error?
    var startBufferingLiveEvents_MockMethod: (() async throws -> AsyncThrowingStream<UpdateEventEnvelope, Error>)?
    var startBufferingLiveEvents_MockValue: AsyncThrowingStream<UpdateEventEnvelope, Error>?

    func startBufferingLiveEvents() async throws -> AsyncThrowingStream<UpdateEventEnvelope, Error> {
        startBufferingLiveEvents_Invocations.append(())

        if let error = startBufferingLiveEvents_MockError {
            throw error
        }

        if let mock = startBufferingLiveEvents_MockMethod {
            return try await mock()
        } else if let mock = startBufferingLiveEvents_MockValue {
            return mock
        } else {
            fatalError("no mock for `startBufferingLiveEvents`")
        }
    }

    // MARK: - stopReceivingLiveEvents

    var stopReceivingLiveEvents_Invocations: [Void] = []
    var stopReceivingLiveEvents_MockMethod: (() async -> Void)?

    func stopReceivingLiveEvents() async {
        stopReceivingLiveEvents_Invocations.append(())

        guard let mock = stopReceivingLiveEvents_MockMethod else {
            fatalError("no mock for `stopReceivingLiveEvents`")
        }

        await mock()
    }

    // MARK: - storeLastEventEnvelopeID

    var storeLastEventEnvelopeID_Invocations: [UUID] = []
    var storeLastEventEnvelopeID_MockMethod: ((UUID) -> Void)?

    func storeLastEventEnvelopeID(_ id: UUID) {
        storeLastEventEnvelopeID_Invocations.append(id)

        guard let mock = storeLastEventEnvelopeID_MockMethod else {
            fatalError("no mock for `storeLastEventEnvelopeID`")
        }

        mock(id)
    }

    // MARK: - pullLastEventID

    var pullLastEventID_Invocations: [Void] = []
    var pullLastEventID_MockError: Error?
    var pullLastEventID_MockMethod: (() async throws -> Void)?

    func pullLastEventID() async throws {
        pullLastEventID_Invocations.append(())

        if let error = pullLastEventID_MockError {
            throw error
        }

        guard let mock = pullLastEventID_MockMethod else {
            fatalError("no mock for `pullLastEventID`")
        }

        try await mock()
    }

}

public class MockUserClientsRepositoryProtocol: UserClientsRepositoryProtocol {

    // MARK: - Life cycle

    public init() {}


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

    public var fetchOrCreateClientWith_Invocations: [String] = []
    public var fetchOrCreateClientWith_MockError: Error?
    public var fetchOrCreateClientWith_MockMethod: ((String) async throws -> (client: WireDataModel.UserClient, isNew: Bool))?
    public var fetchOrCreateClientWith_MockValue: (client: WireDataModel.UserClient, isNew: Bool)?

    public func fetchOrCreateClient(with id: String) async throws -> (client: WireDataModel.UserClient, isNew: Bool) {
        fetchOrCreateClientWith_Invocations.append(id)

        if let error = fetchOrCreateClientWith_MockError {
            throw error
        }

        if let mock = fetchOrCreateClientWith_MockMethod {
            return try await mock(id)
        } else if let mock = fetchOrCreateClientWith_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateClientWith`")
        }
    }

    // MARK: - updateClient

    public var updateClientWithFromIsNewClient_Invocations: [(id: String, remoteClient: WireAPI.SelfUserClient, isNewClient: Bool)] = []
    public var updateClientWithFromIsNewClient_MockError: Error?
    public var updateClientWithFromIsNewClient_MockMethod: ((String, WireAPI.SelfUserClient, Bool) async throws -> Void)?

    public func updateClient(with id: String, from remoteClient: WireAPI.SelfUserClient, isNewClient: Bool) async throws {
        updateClientWithFromIsNewClient_Invocations.append((id: id, remoteClient: remoteClient, isNewClient: isNewClient))

        if let error = updateClientWithFromIsNewClient_MockError {
            throw error
        }

        guard let mock = updateClientWithFromIsNewClient_MockMethod else {
            fatalError("no mock for `updateClientWithFromIsNewClient`")
        }

        try await mock(id, remoteClient, isNewClient)
    }

    // MARK: - deleteClient

    public var deleteClientWith_Invocations: [String] = []
    public var deleteClientWith_MockMethod: ((String) async -> Void)?

    public func deleteClient(with id: String) async {
        deleteClientWith_Invocations.append(id)

        guard let mock = deleteClientWith_MockMethod else {
            fatalError("no mock for `deleteClientWith`")
        }

        await mock(id)
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

    // MARK: - fetchOrCreateUserClient

    public var fetchOrCreateUserClientId_Invocations: [String] = []
    public var fetchOrCreateUserClientId_MockMethod: ((String) async -> (client: WireDataModel.UserClient, isNew: Bool))?
    public var fetchOrCreateUserClientId_MockValue: (client: WireDataModel.UserClient, isNew: Bool)?

    public func fetchOrCreateUserClient(id: String) async -> (client: WireDataModel.UserClient, isNew: Bool) {
        fetchOrCreateUserClientId_Invocations.append(id)

        if let mock = fetchOrCreateUserClientId_MockMethod {
            return await mock(id)
        } else if let mock = fetchOrCreateUserClientId_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateUserClientId`")
        }
    }

    // MARK: - updateUserClient

    public var updateUserClientFromIsNewClient_Invocations: [(localClient: WireDataModel.UserClient, remoteClient: WireAPI.SelfUserClient, isNewClient: Bool)] = []
    public var updateUserClientFromIsNewClient_MockError: Error?
    public var updateUserClientFromIsNewClient_MockMethod: ((WireDataModel.UserClient, WireAPI.SelfUserClient, Bool) async throws -> Void)?

    public func updateUserClient(_ localClient: WireDataModel.UserClient, from remoteClient: WireAPI.SelfUserClient, isNewClient: Bool) async throws {
        updateUserClientFromIsNewClient_Invocations.append((localClient: localClient, remoteClient: remoteClient, isNewClient: isNewClient))

        if let error = updateUserClientFromIsNewClient_MockError {
            throw error
        }

        guard let mock = updateUserClientFromIsNewClient_MockMethod else {
            fatalError("no mock for `updateUserClientFromIsNewClient`")
        }

        try await mock(localClient, remoteClient, isNewClient)
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

    // MARK: - persistUser

    public var persistUserFrom_Invocations: [WireAPI.User] = []
    public var persistUserFrom_MockMethod: ((WireAPI.User) async -> Void)?

    public func persistUser(from user: WireAPI.User) async {
        persistUserFrom_Invocations.append(user)

        guard let mock = persistUserFrom_MockMethod else {
            fatalError("no mock for `persistUserFrom`")
        }

        await mock(user)
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

}

public class MockUserRepositoryProtocol: UserRepositoryProtocol {

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

    // MARK: - pushSelfSupportedProtocols

    public var pushSelfSupportedProtocols_Invocations: [Set<WireAPI.MessageProtocol>] = []
    public var pushSelfSupportedProtocols_MockError: Error?
    public var pushSelfSupportedProtocols_MockMethod: ((Set<WireAPI.MessageProtocol>) async throws -> Void)?

    public func pushSelfSupportedProtocols(_ supportedProtocols: Set<WireAPI.MessageProtocol>) async throws {
        pushSelfSupportedProtocols_Invocations.append(supportedProtocols)

        if let error = pushSelfSupportedProtocols_MockError {
            throw error
        }

        guard let mock = pushSelfSupportedProtocols_MockMethod else {
            fatalError("no mock for `pushSelfSupportedProtocols`")
        }

        try await mock(supportedProtocols)
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

    public var updateUserProperty_Invocations: [WireAPI.UserProperty] = []
    public var updateUserProperty_MockError: Error?
    public var updateUserProperty_MockMethod: ((WireAPI.UserProperty) async throws -> Void)?

    public func updateUserProperty(_ userProperty: WireAPI.UserProperty) async throws {
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

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
