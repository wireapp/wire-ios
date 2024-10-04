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





















class MockConnectionsLocalStoreProtocol: ConnectionsLocalStoreProtocol {

    // MARK: - Life cycle



    // MARK: - storeConnection

    var storeConnection_Invocations: [Connection] = []
    var storeConnection_MockError: Error?
    var storeConnection_MockMethod: ((Connection) async throws -> Void)?

    func storeConnection(_ connectionPayload: Connection) async throws {
        storeConnection_Invocations.append(connectionPayload)

        if let error = storeConnection_MockError {
            throw error
        }

        guard let mock = storeConnection_MockMethod else {
            fatalError("no mock for `storeConnection`")
        }

        try await mock(connectionPayload)
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

    // MARK: - fetchUser

    public var fetchUserWith_Invocations: [UUID] = []
    public var fetchUserWith_MockError: Error?
    public var fetchUserWith_MockMethod: ((UUID) async throws -> ZMUser)?
    public var fetchUserWith_MockValue: ZMUser?

    public func fetchUser(with id: UUID) async throws -> ZMUser {
        fetchUserWith_Invocations.append(id)

        if let error = fetchUserWith_MockError {
            throw error
        }

        if let mock = fetchUserWith_MockMethod {
            return try await mock(id)
        } else if let mock = fetchUserWith_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchUserWith`")
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

    public var deleteUserAccountForAt_Invocations: [(user: ZMUser, date: Date)] = []
    public var deleteUserAccountForAt_MockMethod: ((ZMUser, Date) async -> Void)?

    public func deleteUserAccount(for user: ZMUser, at date: Date) async {
        deleteUserAccountForAt_Invocations.append((user: user, date: date))

        guard let mock = deleteUserAccountForAt_MockMethod else {
            fatalError("no mock for `deleteUserAccountForAt`")
        }

        await mock(user, date)
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
