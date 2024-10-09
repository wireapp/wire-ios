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

}

class MockConversationLabelsRepositoryProtocol: ConversationLabelsRepositoryProtocol {

    // MARK: - Life cycle



    // MARK: - pullConversationLabels

    var pullConversationLabels_Invocations: [Void] = []
    var pullConversationLabels_MockError: Error?
    var pullConversationLabels_MockMethod: (() async throws -> Void)?

    func pullConversationLabels() async throws {
        pullConversationLabels_Invocations.append(())

        if let error = pullConversationLabels_MockError {
            throw error
        }

        guard let mock = pullConversationLabels_MockMethod else {
            fatalError("no mock for `pullConversationLabels`")
        }

        try await mock()
    }

}

public class MockConversationLocalStoreProtocol: ConversationLocalStoreProtocol {

    // MARK: - Life cycle

    public init() {}


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

    // MARK: - removeFromConversations

    public var removeFromConversationsUserRemovalDate_Invocations: [(user: ZMUser, removalDate: Date)] = []
    public var removeFromConversationsUserRemovalDate_MockMethod: ((ZMUser, Date) async -> Void)?

    public func removeFromConversations(user: ZMUser, removalDate: Date) async {
        removeFromConversationsUserRemovalDate_Invocations.append((user: user, removalDate: removalDate))

        guard let mock = removeFromConversationsUserRemovalDate_MockMethod else {
            fatalError("no mock for `removeFromConversationsUserRemovalDate`")
        }

        await mock(user, removalDate)
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

}

public class MockConversationRepositoryProtocol: ConversationRepositoryProtocol {

    // MARK: - Life cycle

    public init() {}


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

    // MARK: - removeFromConversations

    public var removeFromConversationsUserRemovalDate_Invocations: [(user: ZMUser, removalDate: Date)] = []
    public var removeFromConversationsUserRemovalDate_MockMethod: ((ZMUser, Date) async -> Void)?

    public func removeFromConversations(user: ZMUser, removalDate: Date) async {
        removeFromConversationsUserRemovalDate_Invocations.append((user: user, removalDate: removalDate))

        guard let mock = removeFromConversationsUserRemovalDate_MockMethod else {
            fatalError("no mock for `removeFromConversationsUserRemovalDate`")
        }

        await mock(user, removalDate)
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

}

class MockOneOnOneResolverProtocol: OneOnOneResolverProtocol {

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

    // MARK: - fetchSelfLegalhold

    public var fetchSelfLegalhold_Invocations: [Void] = []
    public var fetchSelfLegalhold_MockError: Error?
    public var fetchSelfLegalhold_MockMethod: (() async throws -> TeamMemberLegalHold)?
    public var fetchSelfLegalhold_MockValue: TeamMemberLegalHold?

    public func fetchSelfLegalhold() async throws -> TeamMemberLegalHold {
        fetchSelfLegalhold_Invocations.append(())

        if let error = fetchSelfLegalhold_MockError {
            throw error
        }

        if let mock = fetchSelfLegalhold_MockMethod {
            return try await mock()
        } else if let mock = fetchSelfLegalhold_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfLegalhold`")
        }
    }

    // MARK: - deleteMembership

    public var deleteMembershipForUserFromTeamAt_Invocations: [(userID: UUID, teamID: UUID, time: Date)] = []
    public var deleteMembershipForUserFromTeamAt_MockError: Error?
    public var deleteMembershipForUserFromTeamAt_MockMethod: ((UUID, UUID, Date) async throws -> Void)?

    public func deleteMembership(forUser userID: UUID, fromTeam teamID: UUID, at time: Date) async throws {
        deleteMembershipForUserFromTeamAt_Invocations.append((userID: userID, teamID: teamID, time: time))

        if let error = deleteMembershipForUserFromTeamAt_MockError {
            throw error
        }

        guard let mock = deleteMembershipForUserFromTeamAt_MockMethod else {
            fatalError("no mock for `deleteMembershipForUserFromTeamAt`")
        }

        try await mock(userID, teamID, time)
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

    // MARK: - pullSelfLegalHoldStatus

    public var pullSelfLegalHoldStatus_Invocations: [Void] = []
    public var pullSelfLegalHoldStatus_MockError: Error?
    public var pullSelfLegalHoldStatus_MockMethod: (() async throws -> Void)?

    public func pullSelfLegalHoldStatus() async throws {
        pullSelfLegalHoldStatus_Invocations.append(())

        if let error = pullSelfLegalHoldStatus_MockError {
            throw error
        }

        guard let mock = pullSelfLegalHoldStatus_MockMethod else {
            fatalError("no mock for `pullSelfLegalHoldStatus`")
        }

        try await mock()
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

    // MARK: - fetchOrCreateUserClient

    public var fetchOrCreateUserClientWith_Invocations: [String] = []
    public var fetchOrCreateUserClientWith_MockError: Error?
    public var fetchOrCreateUserClientWith_MockMethod: ((String) async throws -> (client: WireDataModel.UserClient, isNew: Bool))?
    public var fetchOrCreateUserClientWith_MockValue: (client: WireDataModel.UserClient, isNew: Bool)?

    public func fetchOrCreateUserClient(with id: String) async throws -> (client: WireDataModel.UserClient, isNew: Bool) {
        fetchOrCreateUserClientWith_Invocations.append(id)

        if let error = fetchOrCreateUserClientWith_MockError {
            throw error
        }

        if let mock = fetchOrCreateUserClientWith_MockMethod {
            return try await mock(id)
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
    public var disableUserLegalHold_MockError: Error?
    public var disableUserLegalHold_MockMethod: (() async throws -> Void)?

    public func disableUserLegalHold() async throws {
        disableUserLegalHold_Invocations.append(())

        if let error = disableUserLegalHold_MockError {
            throw error
        }

        guard let mock = disableUserLegalHold_MockMethod else {
            fatalError("no mock for `disableUserLegalHold`")
        }

        try await mock()
    }

    // MARK: - deleteUserAccount

    public var deleteUserAccountForAt_Invocations: [(user: ZMUser, date: Date)] = []
    public var deleteUserAccountForAt_MockMethod: ((ZMUser, Date) async -> Void)?

    public func deleteUserAccount(for user: ZMUser, at date: Date) async {
        deleteUserAccountForAt_Invocations.append((user: user, date: date))

        guard let mock = deleteUserAccountForAt_MockMethod else {
            fatalError("no mock for `deleteUserAccountForAt`")
        }

        await mock(user, date)
    }

    // MARK: - fetchAllUserIdsWithOneOnOneConversation

    public var fetchAllUserIdsWithOneOnOneConversation_Invocations: [Void] = []
    public var fetchAllUserIdsWithOneOnOneConversation_MockError: Error?
    public var fetchAllUserIdsWithOneOnOneConversation_MockMethod: (() async throws -> [WireDataModel.QualifiedID])?
    public var fetchAllUserIdsWithOneOnOneConversation_MockValue: [WireDataModel.QualifiedID]?

    public func fetchAllUserIdsWithOneOnOneConversation() async throws -> [WireDataModel.QualifiedID] {
        fetchAllUserIdsWithOneOnOneConversation_Invocations.append(())

        if let error = fetchAllUserIdsWithOneOnOneConversation_MockError {
            throw error
        }

        if let mock = fetchAllUserIdsWithOneOnOneConversation_MockMethod {
            return try await mock()
        } else if let mock = fetchAllUserIdsWithOneOnOneConversation_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchAllUserIdsWithOneOnOneConversation`")
        }
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
