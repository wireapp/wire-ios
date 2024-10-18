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

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

import WireAPI
import WireDataModel

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

    public var fetchOrCreateConversationWithDomain_Invocations: [(id: UUID, domain: String?)] = []
    public var fetchOrCreateConversationWithDomain_MockMethod: ((UUID, String?) async -> ZMConversation)?
    public var fetchOrCreateConversationWithDomain_MockValue: ZMConversation?

    public func fetchOrCreateConversation(with id: UUID, domain: String?) async -> ZMConversation {
        fetchOrCreateConversationWithDomain_Invocations.append((id: id, domain: domain))

        if let mock = fetchOrCreateConversationWithDomain_MockMethod {
            return await mock(id, domain)
        } else if let mock = fetchOrCreateConversationWithDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateConversationWithDomain`")
        }
    }

    // MARK: - storeConversation

    public var storeConversationIsFederationEnabled_Invocations: [(conversation: WireAPI.Conversation, isFederationEnabled: Bool)] = []
    public var storeConversationIsFederationEnabled_MockMethod: ((WireAPI.Conversation, Bool) async -> Void)?

    public func storeConversation(_ conversation: WireAPI.Conversation, isFederationEnabled: Bool) async {
        storeConversationIsFederationEnabled_Invocations.append((conversation: conversation, isFederationEnabled: isFederationEnabled))

        guard let mock = storeConversationIsFederationEnabled_MockMethod else {
            fatalError("no mock for `storeConversationIsFederationEnabled`")
        }

        await mock(conversation, isFederationEnabled)
    }

    // MARK: - storeConversationNeedsBackendUpdate

    public var storeConversationNeedsBackendUpdateQualifiedId_Invocations: [(needsUpdate: Bool, qualifiedId: WireAPI.QualifiedID)] = []
    public var storeConversationNeedsBackendUpdateQualifiedId_MockMethod: ((Bool, WireAPI.QualifiedID) async -> Void)?

    public func storeConversationNeedsBackendUpdate(_ needsUpdate: Bool, qualifiedId: WireAPI.QualifiedID) async {
        storeConversationNeedsBackendUpdateQualifiedId_Invocations.append((needsUpdate: needsUpdate, qualifiedId: qualifiedId))

        guard let mock = storeConversationNeedsBackendUpdateQualifiedId_MockMethod else {
            fatalError("no mock for `storeConversationNeedsBackendUpdateQualifiedId`")
        }

        await mock(needsUpdate, qualifiedId)
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

    public var fetchMLSConversationWith_Invocations: [WireDataModel.MLSGroupID] = []
    public var fetchMLSConversationWith_MockMethod: ((WireDataModel.MLSGroupID) async -> ZMConversation?)?
    public var fetchMLSConversationWith_MockValue: ZMConversation??

    public func fetchMLSConversation(with groupID: WireDataModel.MLSGroupID) async -> ZMConversation? {
        fetchMLSConversationWith_Invocations.append(groupID)

        if let mock = fetchMLSConversationWith_MockMethod {
            return await mock(groupID)
        } else if let mock = fetchMLSConversationWith_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchMLSConversationWith`")
        }
    }

    // MARK: - removeUserFromAllGroupConversations

    public var removeUserFromAllGroupConversationsUserRemovalDate_Invocations: [(user: ZMUser, removalDate: Date)] = []
    public var removeUserFromAllGroupConversationsUserRemovalDate_MockMethod: ((ZMUser, Date) async -> Void)?

    public func removeUserFromAllGroupConversations(user: ZMUser, removalDate: Date) async {
        removeUserFromAllGroupConversationsUserRemovalDate_Invocations.append((user: user, removalDate: removalDate))

        guard let mock = removeUserFromAllGroupConversationsUserRemovalDate_MockMethod else {
            fatalError("no mock for `removeUserFromAllGroupConversationsUserRemovalDate`")
        }

        await mock(user, removalDate)
    }

    // MARK: - getParticipants

    public var getParticipantsFrom_Invocations: [ZMConversation] = []
    public var getParticipantsFrom_MockMethod: ((ZMConversation) async -> Set<ZMUser>)?
    public var getParticipantsFrom_MockValue: Set<ZMUser>?

    public func getParticipants(from conversation: ZMConversation) async -> Set<ZMUser> {
        getParticipantsFrom_Invocations.append(conversation)

        if let mock = getParticipantsFrom_MockMethod {
            return await mock(conversation)
        } else if let mock = getParticipantsFrom_MockValue {
            return mock
        } else {
            fatalError("no mock for `getParticipantsFrom`")
        }
    }

    // MARK: - getMessageProtocol

    public var getMessageProtocolFrom_Invocations: [ZMConversation] = []
    public var getMessageProtocolFrom_MockMethod: ((ZMConversation) async -> WireDataModel.MessageProtocol)?
    public var getMessageProtocolFrom_MockValue: WireDataModel.MessageProtocol?

    public func getMessageProtocol(from conversation: ZMConversation) async -> WireDataModel.MessageProtocol {
        getMessageProtocolFrom_Invocations.append(conversation)

        if let mock = getMessageProtocolFrom_MockMethod {
            return await mock(conversation)
        } else if let mock = getMessageProtocolFrom_MockValue {
            return mock
        } else {
            fatalError("no mock for `getMessageProtocolFrom`")
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

    // MARK: - fetchMLSGroupID

    public var fetchMLSGroupIDFor_Invocations: [ZMConversation] = []
    public var fetchMLSGroupIDFor_MockMethod: ((ZMConversation) async -> MLSGroupID?)?
    public var fetchMLSGroupIDFor_MockValue: MLSGroupID??

    public func fetchMLSGroupID(for conversation: ZMConversation) async -> MLSGroupID? {
        fetchMLSGroupIDFor_Invocations.append(conversation)

        if let mock = fetchMLSGroupIDFor_MockMethod {
            return await mock(conversation)
        } else if let mock = fetchMLSGroupIDFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchMLSGroupIDFor`")
        }
    }

}

public class MockConversationRepositoryProtocol: ConversationRepositoryProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - fetchOrCreateConversation

    public var fetchOrCreateConversationWithDomain_Invocations: [(id: UUID, domain: String?)] = []
    public var fetchOrCreateConversationWithDomain_MockMethod: ((UUID, String?) async -> ZMConversation)?
    public var fetchOrCreateConversationWithDomain_MockValue: ZMConversation?

    public func fetchOrCreateConversation(with id: UUID, domain: String?) async -> ZMConversation {
        fetchOrCreateConversationWithDomain_Invocations.append((id: id, domain: domain))

        if let mock = fetchOrCreateConversationWithDomain_MockMethod {
            return await mock(id, domain)
        } else if let mock = fetchOrCreateConversationWithDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateConversationWithDomain`")
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

    public var pullMLSOneToOneConversationUserIDDomain_Invocations: [(userID: String, domain: String)] = []
    public var pullMLSOneToOneConversationUserIDDomain_MockError: Error?
    public var pullMLSOneToOneConversationUserIDDomain_MockMethod: ((String, String) async throws -> String)?
    public var pullMLSOneToOneConversationUserIDDomain_MockValue: String?

    public func pullMLSOneToOneConversation(userID: String, domain: String) async throws -> String {
        pullMLSOneToOneConversationUserIDDomain_Invocations.append((userID: userID, domain: domain))

        if let error = pullMLSOneToOneConversationUserIDDomain_MockError {
            throw error
        }

        if let mock = pullMLSOneToOneConversationUserIDDomain_MockMethod {
            return try await mock(userID, domain)
        } else if let mock = pullMLSOneToOneConversationUserIDDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `pullMLSOneToOneConversationUserIDDomain`")
        }
    }

    // MARK: - fetchMLSConversation

    public var fetchMLSConversationWith_Invocations: [String] = []
    public var fetchMLSConversationWith_MockMethod: ((String) async -> ZMConversation?)?
    public var fetchMLSConversationWith_MockValue: ZMConversation??

    public func fetchMLSConversation(with groupID: String) async -> ZMConversation? {
        fetchMLSConversationWith_Invocations.append(groupID)

        if let mock = fetchMLSConversationWith_MockMethod {
            return await mock(groupID)
        } else if let mock = fetchMLSConversationWith_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchMLSConversationWith`")
        }
    }

    // MARK: - removeUserFromAllGroupConversations

    public var removeUserFromAllGroupConversationsUserRemovalDate_Invocations: [(user: ZMUser, removalDate: Date)] = []
    public var removeUserFromAllGroupConversationsUserRemovalDate_MockMethod: ((ZMUser, Date) async -> Void)?

    public func removeUserFromAllGroupConversations(user: ZMUser, removalDate: Date) async {
        removeUserFromAllGroupConversationsUserRemovalDate_Invocations.append((user: user, removalDate: removalDate))

        guard let mock = removeUserFromAllGroupConversationsUserRemovalDate_MockMethod else {
            fatalError("no mock for `removeUserFromAllGroupConversationsUserRemovalDate`")
        }

        await mock(user, removalDate)
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

public class MockUserLocalStoreProtocol: UserLocalStoreProtocol {

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

    // MARK: - fetchUser

    public var fetchUserWithDomain_Invocations: [(id: UUID, domain: String?)] = []
    public var fetchUserWithDomain_MockError: Error?
    public var fetchUserWithDomain_MockMethod: ((UUID, String?) async throws -> ZMUser)?
    public var fetchUserWithDomain_MockValue: ZMUser?

    public func fetchUser(with id: UUID, domain: String?) async throws -> ZMUser {
        fetchUserWithDomain_Invocations.append((id: id, domain: domain))

        if let error = fetchUserWithDomain_MockError {
            throw error
        }

        if let mock = fetchUserWithDomain_MockMethod {
            return try await mock(id, domain)
        } else if let mock = fetchUserWithDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchUserWithDomain`")
        }
    }

    // MARK: - fetchOrCreateUser

    public var fetchOrCreateUserWithDomain_Invocations: [(uuid: UUID, domain: String?)] = []
    public var fetchOrCreateUserWithDomain_MockMethod: ((UUID, String?) -> ZMUser)?
    public var fetchOrCreateUserWithDomain_MockValue: ZMUser?

    public func fetchOrCreateUser(with uuid: UUID, domain: String?) -> ZMUser {
        fetchOrCreateUserWithDomain_Invocations.append((uuid: uuid, domain: domain))

        if let mock = fetchOrCreateUserWithDomain_MockMethod {
            return mock(uuid, domain)
        } else if let mock = fetchOrCreateUserWithDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateUserWithDomain`")
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

    public var fetchOrCreateUserClientWith_Invocations: [String] = []
    public var fetchOrCreateUserClientWith_MockMethod: ((String) async -> (client: WireDataModel.UserClient, isNew: Bool))?
    public var fetchOrCreateUserClientWith_MockValue: (client: WireDataModel.UserClient, isNew: Bool)?

    public func fetchOrCreateUserClient(with id: String) async -> (client: WireDataModel.UserClient, isNew: Bool) {
        fetchOrCreateUserClientWith_Invocations.append(id)

        if let mock = fetchOrCreateUserClientWith_MockMethod {
            return await mock(id)
        } else if let mock = fetchOrCreateUserClientWith_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateUserClientWith`")
        }
    }

    // MARK: - updateUserClient

    public var updateUserClientFromIsNewClient_Invocations: [(localClient: WireDataModel.UserClient, remoteClient: WireAPI.UserClient, isNewClient: Bool)] = []
    public var updateUserClientFromIsNewClient_MockError: Error?
    public var updateUserClientFromIsNewClient_MockMethod: ((WireDataModel.UserClient, WireAPI.UserClient, Bool) async throws -> Void)?

    public func updateUserClient(_ localClient: WireDataModel.UserClient, from remoteClient: WireAPI.UserClient, isNewClient: Bool) async throws {
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

    public var addSelfLegalHoldRequestForClientIDLastPrekey_Invocations: [(userID: UUID, clientID: String, lastPrekey: WireDataModel.LegalHoldRequest.Prekey)] = []
    public var addSelfLegalHoldRequestForClientIDLastPrekey_MockMethod: ((UUID, String, WireDataModel.LegalHoldRequest.Prekey) async -> Void)?

    public func addSelfLegalHoldRequest(for userID: UUID, clientID: String, lastPrekey: WireDataModel.LegalHoldRequest.Prekey) async {
        addSelfLegalHoldRequestForClientIDLastPrekey_Invocations.append((userID: userID, clientID: clientID, lastPrekey: lastPrekey))

        guard let mock = addSelfLegalHoldRequestForClientIDLastPrekey_MockMethod else {
            fatalError("no mock for `addSelfLegalHoldRequestForClientIDLastPrekey`")
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

    // MARK: - fetchUser

    public var fetchUserWithDomain_Invocations: [(id: UUID, domain: String?)] = []
    public var fetchUserWithDomain_MockError: Error?
    public var fetchUserWithDomain_MockMethod: ((UUID, String?) async throws -> ZMUser)?
    public var fetchUserWithDomain_MockValue: ZMUser?

    public func fetchUser(with id: UUID, domain: String?) async throws -> ZMUser {
        fetchUserWithDomain_Invocations.append((id: id, domain: domain))

        if let error = fetchUserWithDomain_MockError {
            throw error
        }

        if let mock = fetchUserWithDomain_MockMethod {
            return try await mock(id, domain)
        } else if let mock = fetchUserWithDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchUserWithDomain`")
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

    public var fetchOrCreateUserWithDomain_Invocations: [(uuid: UUID, domain: String?)] = []
    public var fetchOrCreateUserWithDomain_MockMethod: ((UUID, String?) -> ZMUser)?
    public var fetchOrCreateUserWithDomain_MockValue: ZMUser?

    public func fetchOrCreateUser(with uuid: UUID, domain: String?) -> ZMUser {
        fetchOrCreateUserWithDomain_Invocations.append((uuid: uuid, domain: domain))

        if let mock = fetchOrCreateUserWithDomain_MockMethod {
            return mock(uuid, domain)
        } else if let mock = fetchOrCreateUserWithDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateUserWithDomain`")
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

    // MARK: - fetchOrCreateUserClient

    public var fetchOrCreateUserClientWith_Invocations: [String] = []
    public var fetchOrCreateUserClientWith_MockMethod: ((String) async -> (client: WireDataModel.UserClient, isNew: Bool))?
    public var fetchOrCreateUserClientWith_MockValue: (client: WireDataModel.UserClient, isNew: Bool)?

    public func fetchOrCreateUserClient(with id: String) async -> (client: WireDataModel.UserClient, isNew: Bool) {
        fetchOrCreateUserClientWith_Invocations.append(id)

        if let mock = fetchOrCreateUserClientWith_MockMethod {
            return await mock(id)
        } else if let mock = fetchOrCreateUserClientWith_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchOrCreateUserClientWith`")
        }
    }

    // MARK: - updateUserClient

    public var updateUserClientFromIsNewClient_Invocations: [(localClient: WireDataModel.UserClient, remoteClient: WireAPI.UserClient, isNewClient: Bool)] = []
    public var updateUserClientFromIsNewClient_MockError: Error?
    public var updateUserClientFromIsNewClient_MockMethod: ((WireDataModel.UserClient, WireAPI.UserClient, Bool) async throws -> Void)?

    public func updateUserClient(_ localClient: WireDataModel.UserClient, from remoteClient: WireAPI.UserClient, isNewClient: Bool) async throws {
        updateUserClientFromIsNewClient_Invocations.append((localClient: localClient, remoteClient: remoteClient, isNewClient: isNewClient))

        if let error = updateUserClientFromIsNewClient_MockError {
            throw error
        }

        guard let mock = updateUserClientFromIsNewClient_MockMethod else {
            fatalError("no mock for `updateUserClientFromIsNewClient`")
        }

        try await mock(localClient, remoteClient, isNewClient)
    }

    // MARK: - addLegalHoldRequest

    public var addLegalHoldRequestForClientIDLastPrekey_Invocations: [(userID: UUID, clientID: String, lastPrekey: Prekey)] = []
    public var addLegalHoldRequestForClientIDLastPrekey_MockMethod: ((UUID, String, Prekey) async -> Void)?

    public func addLegalHoldRequest(for userID: UUID, clientID: String, lastPrekey: Prekey) async {
        addLegalHoldRequestForClientIDLastPrekey_Invocations.append((userID: userID, clientID: clientID, lastPrekey: lastPrekey))

        guard let mock = addLegalHoldRequestForClientIDLastPrekey_MockMethod else {
            fatalError("no mock for `addLegalHoldRequestForClientIDLastPrekey`")
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

    public var deleteUserAccountWithDomainAt_Invocations: [(id: UUID, domain: String?, date: Date)] = []
    public var deleteUserAccountWithDomainAt_MockError: Error?
    public var deleteUserAccountWithDomainAt_MockMethod: ((UUID, String?, Date) async throws -> Void)?

    public func deleteUserAccount(with id: UUID, domain: String?, at date: Date) async throws {
        deleteUserAccountWithDomainAt_Invocations.append((id: id, domain: domain, date: date))

        if let error = deleteUserAccountWithDomainAt_MockError {
            throw error
        }

        guard let mock = deleteUserAccountWithDomainAt_MockMethod else {
            fatalError("no mock for `deleteUserAccountWithDomainAt`")
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
