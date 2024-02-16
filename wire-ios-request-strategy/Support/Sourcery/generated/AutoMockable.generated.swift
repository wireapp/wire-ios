// Generated using Sourcery 2.1.7 — https://github.com/krzysztofzablocki/Sourcery
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

import WireCoreCrypto
import Combine

@testable import WireRequestStrategy





















public class MockAPIProviderInterface: APIProviderInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - prekeyAPI

    public var prekeyAPIApiVersion_Invocations: [APIVersion] = []
    public var prekeyAPIApiVersion_MockMethod: ((APIVersion) -> PrekeyAPI)?
    public var prekeyAPIApiVersion_MockValue: PrekeyAPI?

    public func prekeyAPI(apiVersion: APIVersion) -> PrekeyAPI {
        prekeyAPIApiVersion_Invocations.append(apiVersion)

        if let mock = prekeyAPIApiVersion_MockMethod {
            return mock(apiVersion)
        } else if let mock = prekeyAPIApiVersion_MockValue {
            return mock
        } else {
            fatalError("no mock for `prekeyAPIApiVersion`")
        }
    }

    // MARK: - messageAPI

    public var messageAPIApiVersion_Invocations: [APIVersion] = []
    public var messageAPIApiVersion_MockMethod: ((APIVersion) -> MessageAPI)?
    public var messageAPIApiVersion_MockValue: MessageAPI?

    public func messageAPI(apiVersion: APIVersion) -> MessageAPI {
        messageAPIApiVersion_Invocations.append(apiVersion)

        if let mock = messageAPIApiVersion_MockMethod {
            return mock(apiVersion)
        } else if let mock = messageAPIApiVersion_MockValue {
            return mock
        } else {
            fatalError("no mock for `messageAPIApiVersion`")
        }
    }

    // MARK: - e2eIAPI

    public var e2eIAPIApiVersion_Invocations: [APIVersion] = []
    public var e2eIAPIApiVersion_MockMethod: ((APIVersion) -> E2eIAPI?)?
    public var e2eIAPIApiVersion_MockValue: E2eIAPI??

    public func e2eIAPI(apiVersion: APIVersion) -> E2eIAPI? {
        e2eIAPIApiVersion_Invocations.append(apiVersion)

        if let mock = e2eIAPIApiVersion_MockMethod {
            return mock(apiVersion)
        } else if let mock = e2eIAPIApiVersion_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eIAPIApiVersion`")
        }
    }

}
public class MockConversationParticipantsServiceInterface: ConversationParticipantsServiceInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - addParticipants

    public var addParticipantsTo_Invocations: [(users: [ZMUser], conversation: ZMConversation)] = []
    public var addParticipantsTo_MockError: Error?
    public var addParticipantsTo_MockMethod: (([ZMUser], ZMConversation) async throws -> Void)?

    public func addParticipants(_ users: [ZMUser], to conversation: ZMConversation) async throws {
        addParticipantsTo_Invocations.append((users: users, conversation: conversation))

        if let error = addParticipantsTo_MockError {
            throw error
        }

        guard let mock = addParticipantsTo_MockMethod else {
            fatalError("no mock for `addParticipantsTo`")
        }

        try await mock(users, conversation)
    }

    // MARK: - removeParticipant

    public var removeParticipantFrom_Invocations: [(user: ZMUser, conversation: ZMConversation)] = []
    public var removeParticipantFrom_MockError: Error?
    public var removeParticipantFrom_MockMethod: ((ZMUser, ZMConversation) async throws -> Void)?

    public func removeParticipant(_ user: ZMUser, from conversation: ZMConversation) async throws {
        removeParticipantFrom_Invocations.append((user: user, conversation: conversation))

        if let error = removeParticipantFrom_MockError {
            throw error
        }

        guard let mock = removeParticipantFrom_MockMethod else {
            fatalError("no mock for `removeParticipantFrom`")
        }

        try await mock(user, conversation)
    }

}
public class MockConversationServiceInterface: ConversationServiceInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - createGroupConversation

    public var createGroupConversationNameUsersAllowGuestsAllowServicesEnableReceiptsMessageProtocolCompletion_Invocations: [(name: String?, users: Set<ZMUser>, allowGuests: Bool, allowServices: Bool, enableReceipts: Bool, messageProtocol: MessageProtocol, completion: (Result<ZMConversation, ConversationCreationFailure>) -> Void)] = []
    public var createGroupConversationNameUsersAllowGuestsAllowServicesEnableReceiptsMessageProtocolCompletion_MockMethod: ((String?, Set<ZMUser>, Bool, Bool, Bool, MessageProtocol, @escaping (Result<ZMConversation, ConversationCreationFailure>) -> Void) -> Void)?

    public func createGroupConversation(name: String?, users: Set<ZMUser>, allowGuests: Bool, allowServices: Bool, enableReceipts: Bool, messageProtocol: MessageProtocol, completion: @escaping (Result<ZMConversation, ConversationCreationFailure>) -> Void) {
        createGroupConversationNameUsersAllowGuestsAllowServicesEnableReceiptsMessageProtocolCompletion_Invocations.append((name: name, users: users, allowGuests: allowGuests, allowServices: allowServices, enableReceipts: enableReceipts, messageProtocol: messageProtocol, completion: completion))

        guard let mock = createGroupConversationNameUsersAllowGuestsAllowServicesEnableReceiptsMessageProtocolCompletion_MockMethod else {
            fatalError("no mock for `createGroupConversationNameUsersAllowGuestsAllowServicesEnableReceiptsMessageProtocolCompletion`")
        }

        mock(name, users, allowGuests, allowServices, enableReceipts, messageProtocol, completion)
    }

    // MARK: - createTeamOneOnOneProteusConversation

    public var createTeamOneOnOneProteusConversationUserCompletion_Invocations: [(user: ZMUser, completion: (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void)] = []
    public var createTeamOneOnOneProteusConversationUserCompletion_MockMethod: ((ZMUser, @escaping (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void) -> Void)?

    public func createTeamOneOnOneProteusConversation(user: ZMUser, completion: @escaping (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void) {
        createTeamOneOnOneProteusConversationUserCompletion_Invocations.append((user: user, completion: completion))

        guard let mock = createTeamOneOnOneProteusConversationUserCompletion_MockMethod else {
            fatalError("no mock for `createTeamOneOnOneProteusConversationUserCompletion`")
        }

        mock(user, completion)
    }

    // MARK: - syncConversation

    public var syncConversationQualifiedIDCompletion_Invocations: [(qualifiedID: QualifiedID, completion: () -> Void)] = []
    public var syncConversationQualifiedIDCompletion_MockMethod: ((QualifiedID, @escaping () -> Void) -> Void)?

    public func syncConversation(qualifiedID: QualifiedID, completion: @escaping () -> Void) {
        syncConversationQualifiedIDCompletion_Invocations.append((qualifiedID: qualifiedID, completion: completion))

        guard let mock = syncConversationQualifiedIDCompletion_MockMethod else {
            fatalError("no mock for `syncConversationQualifiedIDCompletion`")
        }

        mock(qualifiedID, completion)
    }

    // MARK: - syncConversation

    public var syncConversationQualifiedID_Invocations: [QualifiedID] = []
    public var syncConversationQualifiedID_MockMethod: ((QualifiedID) async -> Void)?

    public func syncConversation(qualifiedID: QualifiedID) async {
        syncConversationQualifiedID_Invocations.append(qualifiedID)

        guard let mock = syncConversationQualifiedID_MockMethod else {
            fatalError("no mock for `syncConversationQualifiedID`")
        }

        await mock(qualifiedID)
    }

}
public class MockE2eIAPI: E2eIAPI {

    // MARK: - Life cycle

    public init() {}


    // MARK: - getWireNonce

    public var getWireNonceClientId_Invocations: [String] = []
    public var getWireNonceClientId_MockError: Error?
    public var getWireNonceClientId_MockMethod: ((String) async throws -> String)?
    public var getWireNonceClientId_MockValue: String?

    public func getWireNonce(clientId: String) async throws -> String {
        getWireNonceClientId_Invocations.append(clientId)

        if let error = getWireNonceClientId_MockError {
            throw error
        }

        if let mock = getWireNonceClientId_MockMethod {
            return try await mock(clientId)
        } else if let mock = getWireNonceClientId_MockValue {
            return mock
        } else {
            fatalError("no mock for `getWireNonceClientId`")
        }
    }

    // MARK: - getAccessToken

    public var getAccessTokenClientIdDpopToken_Invocations: [(clientId: String, dpopToken: String)] = []
    public var getAccessTokenClientIdDpopToken_MockError: Error?
    public var getAccessTokenClientIdDpopToken_MockMethod: ((String, String) async throws -> AccessTokenResponse)?
    public var getAccessTokenClientIdDpopToken_MockValue: AccessTokenResponse?

    public func getAccessToken(clientId: String, dpopToken: String) async throws -> AccessTokenResponse {
        getAccessTokenClientIdDpopToken_Invocations.append((clientId: clientId, dpopToken: dpopToken))

        if let error = getAccessTokenClientIdDpopToken_MockError {
            throw error
        }

        if let mock = getAccessTokenClientIdDpopToken_MockMethod {
            return try await mock(clientId, dpopToken)
        } else if let mock = getAccessTokenClientIdDpopToken_MockValue {
            return mock
        } else {
            fatalError("no mock for `getAccessTokenClientIdDpopToken`")
        }
    }

}
public class MockE2eIKeyPackageRotating: E2eIKeyPackageRotating {

    // MARK: - Life cycle

    public init() {}


    // MARK: - rotateKeysAndMigrateConversations

    public var rotateKeysAndMigrateConversationsEnrollmentCertificateChain_Invocations: [(enrollment: E2eiEnrollmentProtocol, certificateChain: String)] = []
    public var rotateKeysAndMigrateConversationsEnrollmentCertificateChain_MockError: Error?
    public var rotateKeysAndMigrateConversationsEnrollmentCertificateChain_MockMethod: ((E2eiEnrollmentProtocol, String) async throws -> Void)?

    public func rotateKeysAndMigrateConversations(enrollment: E2eiEnrollmentProtocol, certificateChain: String) async throws {
        rotateKeysAndMigrateConversationsEnrollmentCertificateChain_Invocations.append((enrollment: enrollment, certificateChain: certificateChain))

        if let error = rotateKeysAndMigrateConversationsEnrollmentCertificateChain_MockError {
            throw error
        }

        guard let mock = rotateKeysAndMigrateConversationsEnrollmentCertificateChain_MockMethod else {
            fatalError("no mock for `rotateKeysAndMigrateConversationsEnrollmentCertificateChain`")
        }

        try await mock(enrollment, certificateChain)
    }

    // MARK: - onNewCRLsDistributionPoints

    public var onNewCRLsDistributionPoints_Invocations: [Void] = []
    public var onNewCRLsDistributionPoints_MockMethod: (() -> AnyPublisher<CRLsDistributionPoints, Never>)?
    public var onNewCRLsDistributionPoints_MockValue: AnyPublisher<CRLsDistributionPoints, Never>?

    public func onNewCRLsDistributionPoints() -> AnyPublisher<CRLsDistributionPoints, Never> {
        onNewCRLsDistributionPoints_Invocations.append(())

        if let mock = onNewCRLsDistributionPoints_MockMethod {
            return mock()
        } else if let mock = onNewCRLsDistributionPoints_MockValue {
            return mock
        } else {
            fatalError("no mock for `onNewCRLsDistributionPoints`")
        }
    }

}
class MockMLSClientIDsProviding: MLSClientIDsProviding {

    // MARK: - Life cycle



    // MARK: - fetchUserClients

    var fetchUserClientsForIn_Invocations: [(userID: QualifiedID, context: NotificationContext)] = []
    var fetchUserClientsForIn_MockError: Error?
    var fetchUserClientsForIn_MockMethod: ((QualifiedID, NotificationContext) async throws -> [MLSClientID])?
    var fetchUserClientsForIn_MockValue: [MLSClientID]?

    func fetchUserClients(for userID: QualifiedID, in context: NotificationContext) async throws -> [MLSClientID] {
        fetchUserClientsForIn_Invocations.append((userID: userID, context: context))

        if let error = fetchUserClientsForIn_MockError {
            throw error
        }

        if let mock = fetchUserClientsForIn_MockMethod {
            return try await mock(userID, context)
        } else if let mock = fetchUserClientsForIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchUserClientsForIn`")
        }
    }

}
class MockMLSConversationParticipantsServiceInterface: MLSConversationParticipantsServiceInterface {

    // MARK: - Life cycle



    // MARK: - addParticipants

    var addParticipantsTo_Invocations: [(users: [ZMUser], conversation: ZMConversation)] = []
    var addParticipantsTo_MockError: Error?
    var addParticipantsTo_MockMethod: (([ZMUser], ZMConversation) async throws -> Void)?

    func addParticipants(_ users: [ZMUser], to conversation: ZMConversation) async throws {
        addParticipantsTo_Invocations.append((users: users, conversation: conversation))

        if let error = addParticipantsTo_MockError {
            throw error
        }

        guard let mock = addParticipantsTo_MockMethod else {
            fatalError("no mock for `addParticipantsTo`")
        }

        try await mock(users, conversation)
    }

    // MARK: - removeParticipant

    var removeParticipantFrom_Invocations: [(user: ZMUser, conversation: ZMConversation)] = []
    var removeParticipantFrom_MockError: Error?
    var removeParticipantFrom_MockMethod: ((ZMUser, ZMConversation) async throws -> Void)?

    func removeParticipant(_ user: ZMUser, from conversation: ZMConversation) async throws {
        removeParticipantFrom_Invocations.append((user: user, conversation: conversation))

        if let error = removeParticipantFrom_MockError {
            throw error
        }

        guard let mock = removeParticipantFrom_MockMethod else {
            fatalError("no mock for `removeParticipantFrom`")
        }

        try await mock(user, conversation)
    }

}
public class MockMLSEventProcessing: MLSEventProcessing {

    // MARK: - Life cycle

    public init() {}


    // MARK: - updateConversationIfNeeded

    public var updateConversationIfNeededConversationFallbackGroupIDContext_Invocations: [(conversation: ZMConversation, fallbackGroupID: MLSGroupID?, context: NSManagedObjectContext)] = []
    public var updateConversationIfNeededConversationFallbackGroupIDContext_MockMethod: ((ZMConversation, MLSGroupID?, NSManagedObjectContext) async -> Void)?

    public func updateConversationIfNeeded(conversation: ZMConversation, fallbackGroupID: MLSGroupID?, context: NSManagedObjectContext) async {
        updateConversationIfNeededConversationFallbackGroupIDContext_Invocations.append((conversation: conversation, fallbackGroupID: fallbackGroupID, context: context))

        guard let mock = updateConversationIfNeededConversationFallbackGroupIDContext_MockMethod else {
            fatalError("no mock for `updateConversationIfNeededConversationFallbackGroupIDContext`")
        }

        await mock(conversation, fallbackGroupID, context)
    }

    // MARK: - process

    public var processWelcomeMessageConversationIDIn_Invocations: [(welcomeMessage: String, conversationID: QualifiedID, context: NSManagedObjectContext)] = []
    public var processWelcomeMessageConversationIDIn_MockMethod: ((String, QualifiedID, NSManagedObjectContext) async -> Void)?

    public func process(welcomeMessage: String, conversationID: QualifiedID, in context: NSManagedObjectContext) async {
        processWelcomeMessageConversationIDIn_Invocations.append((welcomeMessage: welcomeMessage, conversationID: conversationID, context: context))

        guard let mock = processWelcomeMessageConversationIDIn_MockMethod else {
            fatalError("no mock for `processWelcomeMessageConversationIDIn`")
        }

        await mock(welcomeMessage, conversationID, context)
    }

    // MARK: - wipeMLSGroup

    public var wipeMLSGroupForConversationContext_Invocations: [(conversation: ZMConversation, context: NSManagedObjectContext)] = []
    public var wipeMLSGroupForConversationContext_MockMethod: ((ZMConversation, NSManagedObjectContext) async -> Void)?

    public func wipeMLSGroup(forConversation conversation: ZMConversation, context: NSManagedObjectContext) async {
        wipeMLSGroupForConversationContext_Invocations.append((conversation: conversation, context: context))

        guard let mock = wipeMLSGroupForConversationContext_MockMethod else {
            fatalError("no mock for `wipeMLSGroupForConversationContext`")
        }

        await mock(conversation, context)
    }

}
public class MockMessageAPI: MessageAPI {

    // MARK: - Life cycle

    public init() {}


    // MARK: - broadcastProteusMessage

    public var broadcastProteusMessageMessage_Invocations: [any ProteusMessage] = []
    public var broadcastProteusMessageMessage_MockError: Error?
    public var broadcastProteusMessageMessage_MockMethod: ((any ProteusMessage) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse))?
    public var broadcastProteusMessageMessage_MockValue: (Payload.MessageSendingStatus, ZMTransportResponse)?

    public func broadcastProteusMessage(message: any ProteusMessage) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse) {
        broadcastProteusMessageMessage_Invocations.append(message)

        if let error = broadcastProteusMessageMessage_MockError {
            throw error
        }

        if let mock = broadcastProteusMessageMessage_MockMethod {
            return try await mock(message)
        } else if let mock = broadcastProteusMessageMessage_MockValue {
            return mock
        } else {
            fatalError("no mock for `broadcastProteusMessageMessage`")
        }
    }

    // MARK: - sendProteusMessage

    public var sendProteusMessageMessageConversationID_Invocations: [(message: any ProteusMessage, conversationID: QualifiedID)] = []
    public var sendProteusMessageMessageConversationID_MockError: Error?
    public var sendProteusMessageMessageConversationID_MockMethod: ((any ProteusMessage, QualifiedID) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse))?
    public var sendProteusMessageMessageConversationID_MockValue: (Payload.MessageSendingStatus, ZMTransportResponse)?

    public func sendProteusMessage(message: any ProteusMessage, conversationID: QualifiedID) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse) {
        sendProteusMessageMessageConversationID_Invocations.append((message: message, conversationID: conversationID))

        if let error = sendProteusMessageMessageConversationID_MockError {
            throw error
        }

        if let mock = sendProteusMessageMessageConversationID_MockMethod {
            return try await mock(message, conversationID)
        } else if let mock = sendProteusMessageMessageConversationID_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendProteusMessageMessageConversationID`")
        }
    }

    // MARK: - sendMLSMessage

    public var sendMLSMessageMessageConversationIDExpirationDate_Invocations: [(encryptedMessage: Data, conversationID: QualifiedID, expirationDate: Date?)] = []
    public var sendMLSMessageMessageConversationIDExpirationDate_MockError: Error?
    public var sendMLSMessageMessageConversationIDExpirationDate_MockMethod: ((Data, QualifiedID, Date?) async throws -> (Payload.MLSMessageSendingStatus, ZMTransportResponse))?
    public var sendMLSMessageMessageConversationIDExpirationDate_MockValue: (Payload.MLSMessageSendingStatus, ZMTransportResponse)?

    public func sendMLSMessage(message encryptedMessage: Data, conversationID: QualifiedID, expirationDate: Date?) async throws -> (Payload.MLSMessageSendingStatus, ZMTransportResponse) {
        sendMLSMessageMessageConversationIDExpirationDate_Invocations.append((encryptedMessage: encryptedMessage, conversationID: conversationID, expirationDate: expirationDate))

        if let error = sendMLSMessageMessageConversationIDExpirationDate_MockError {
            throw error
        }

        if let mock = sendMLSMessageMessageConversationIDExpirationDate_MockMethod {
            return try await mock(encryptedMessage, conversationID, expirationDate)
        } else if let mock = sendMLSMessageMessageConversationIDExpirationDate_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendMLSMessageMessageConversationIDExpirationDate`")
        }
    }

}
public class MockMessageDependencyResolverInterface: MessageDependencyResolverInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - waitForDependenciesToResolve

    public var waitForDependenciesToResolveFor_Invocations: [any SendableMessage] = []
    public var waitForDependenciesToResolveFor_MockError: Error?
    public var waitForDependenciesToResolveFor_MockMethod: ((any SendableMessage) async throws -> Void)?

    public func waitForDependenciesToResolve(for message: any SendableMessage) async throws {
        waitForDependenciesToResolveFor_Invocations.append(message)

        if let error = waitForDependenciesToResolveFor_MockError {
            throw error
        }

        guard let mock = waitForDependenciesToResolveFor_MockMethod else {
            fatalError("no mock for `waitForDependenciesToResolveFor`")
        }

        try await mock(message)
    }

}
public class MockMessageSenderInterface: MessageSenderInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - sendMessage

    public var sendMessageMessage_Invocations: [any SendableMessage] = []
    public var sendMessageMessage_MockError: Error?
    public var sendMessageMessage_MockMethod: ((any SendableMessage) async throws -> Void)?

    public func sendMessage(message: any SendableMessage) async throws {
        sendMessageMessage_Invocations.append(message)

        if let error = sendMessageMessage_MockError {
            throw error
        }

        guard let mock = sendMessageMessage_MockMethod else {
            fatalError("no mock for `sendMessageMessage`")
        }

        try await mock(message)
    }

    // MARK: - broadcastMessage

    public var broadcastMessageMessage_Invocations: [any ProteusMessage] = []
    public var broadcastMessageMessage_MockError: Error?
    public var broadcastMessageMessage_MockMethod: ((any ProteusMessage) async throws -> Void)?

    public func broadcastMessage(message: any ProteusMessage) async throws {
        broadcastMessageMessage_Invocations.append(message)

        if let error = broadcastMessageMessage_MockError {
            throw error
        }

        guard let mock = broadcastMessageMessage_MockMethod else {
            fatalError("no mock for `broadcastMessageMessage`")
        }

        try await mock(message)
    }

}
public class MockPrekeyAPI: PrekeyAPI {

    // MARK: - Life cycle

    public init() {}


    // MARK: - fetchPrekeys

    public var fetchPrekeysFor_Invocations: [Set<QualifiedClientID>] = []
    public var fetchPrekeysFor_MockError: Error?
    public var fetchPrekeysFor_MockMethod: ((Set<QualifiedClientID>) async throws -> Payload.PrekeyByQualifiedUserID)?
    public var fetchPrekeysFor_MockValue: Payload.PrekeyByQualifiedUserID?

    public func fetchPrekeys(for clients: Set<QualifiedClientID>) async throws -> Payload.PrekeyByQualifiedUserID {
        fetchPrekeysFor_Invocations.append(clients)

        if let error = fetchPrekeysFor_MockError {
            throw error
        }

        if let mock = fetchPrekeysFor_MockMethod {
            return try await mock(clients)
        } else if let mock = fetchPrekeysFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchPrekeysFor`")
        }
    }

}
public class MockPrekeyPayloadProcessorInterface: PrekeyPayloadProcessorInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - establishSessions

    public var establishSessionsFromWithContext_Invocations: [(payload: Payload.PrekeyByQualifiedUserID, selfClient: UserClient, context: NSManagedObjectContext)] = []
    public var establishSessionsFromWithContext_MockMethod: ((Payload.PrekeyByQualifiedUserID, UserClient, NSManagedObjectContext) async -> Void)?

    public func establishSessions(from payload: Payload.PrekeyByQualifiedUserID, with selfClient: UserClient, context: NSManagedObjectContext) async {
        establishSessionsFromWithContext_Invocations.append((payload: payload, selfClient: selfClient, context: context))

        guard let mock = establishSessionsFromWithContext_MockMethod else {
            fatalError("no mock for `establishSessionsFromWithContext`")
        }

        await mock(payload, selfClient, context)
    }

}
class MockProteusConversationParticipantsServiceInterface: ProteusConversationParticipantsServiceInterface {

    // MARK: - Life cycle



    // MARK: - addParticipants

    var addParticipantsTo_Invocations: [(users: [ZMUser], conversation: ZMConversation)] = []
    var addParticipantsTo_MockError: Error?
    var addParticipantsTo_MockMethod: (([ZMUser], ZMConversation) async throws -> Void)?

    func addParticipants(_ users: [ZMUser], to conversation: ZMConversation) async throws {
        addParticipantsTo_Invocations.append((users: users, conversation: conversation))

        if let error = addParticipantsTo_MockError {
            throw error
        }

        guard let mock = addParticipantsTo_MockMethod else {
            fatalError("no mock for `addParticipantsTo`")
        }

        try await mock(users, conversation)
    }

    // MARK: - removeParticipant

    var removeParticipantFrom_Invocations: [(user: ZMUser, conversation: ZMConversation)] = []
    var removeParticipantFrom_MockError: Error?
    var removeParticipantFrom_MockMethod: ((ZMUser, ZMConversation) async throws -> Void)?

    func removeParticipant(_ user: ZMUser, from conversation: ZMConversation) async throws {
        removeParticipantFrom_Invocations.append((user: user, conversation: conversation))

        if let error = removeParticipantFrom_MockError {
            throw error
        }

        guard let mock = removeParticipantFrom_MockMethod else {
            fatalError("no mock for `removeParticipantFrom`")
        }

        try await mock(user, conversation)
    }

}
public class MockQuickSyncObserverInterface: QuickSyncObserverInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - waitForQuickSyncToFinish

    public var waitForQuickSyncToFinish_Invocations: [Void] = []
    public var waitForQuickSyncToFinish_MockMethod: (() async -> Void)?

    public func waitForQuickSyncToFinish() async {
        waitForQuickSyncToFinish_Invocations.append(())

        guard let mock = waitForQuickSyncToFinish_MockMethod else {
            fatalError("no mock for `waitForQuickSyncToFinish`")
        }

        await mock()
    }

}
public class MockSessionEstablisherInterface: SessionEstablisherInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - establishSession

    public var establishSessionWithApiVersion_Invocations: [(clients: Set<QualifiedClientID>, apiVersion: APIVersion)] = []
    public var establishSessionWithApiVersion_MockError: Error?
    public var establishSessionWithApiVersion_MockMethod: ((Set<QualifiedClientID>, APIVersion) async throws -> Void)?

    public func establishSession(with clients: Set<QualifiedClientID>, apiVersion: APIVersion) async throws {
        establishSessionWithApiVersion_Invocations.append((clients: clients, apiVersion: apiVersion))

        if let error = establishSessionWithApiVersion_MockError {
            throw error
        }

        guard let mock = establishSessionWithApiVersion_MockMethod else {
            fatalError("no mock for `establishSessionWithApiVersion`")
        }

        try await mock(clients, apiVersion)
    }

}
class MockUserProfilePayloadProcessing: UserProfilePayloadProcessing {

    // MARK: - Life cycle



    // MARK: - updateUserProfiles

    var updateUserProfilesFromIn_Invocations: [(userProfiles: Payload.UserProfiles, context: NSManagedObjectContext)] = []
    var updateUserProfilesFromIn_MockMethod: ((Payload.UserProfiles, NSManagedObjectContext) -> Void)?

    func updateUserProfiles(from userProfiles: Payload.UserProfiles, in context: NSManagedObjectContext) {
        updateUserProfilesFromIn_Invocations.append((userProfiles: userProfiles, context: context))

        guard let mock = updateUserProfilesFromIn_MockMethod else {
            fatalError("no mock for `updateUserProfilesFromIn`")
        }

        mock(userProfiles, context)
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
