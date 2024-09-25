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

    // MARK: - userClientAPI

    public var userClientAPIApiVersion_Invocations: [APIVersion] = []
    public var userClientAPIApiVersion_MockMethod: ((APIVersion) -> UserClientAPI)?
    public var userClientAPIApiVersion_MockValue: UserClientAPI?

    public func userClientAPI(apiVersion: APIVersion) -> UserClientAPI {
        userClientAPIApiVersion_Invocations.append(apiVersion)

        if let mock = userClientAPIApiVersion_MockMethod {
            return mock(apiVersion)
        } else if let mock = userClientAPIApiVersion_MockValue {
            return mock
        } else {
            fatalError("no mock for `userClientAPIApiVersion`")
        }
    }

}

public class MockAcmeAPIInterface: AcmeAPIInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - getACMEDirectory

    public var getACMEDirectory_Invocations: [Void] = []
    public var getACMEDirectory_MockError: Error?
    public var getACMEDirectory_MockMethod: (() async throws -> Data)?
    public var getACMEDirectory_MockValue: Data?

    public func getACMEDirectory() async throws -> Data {
        getACMEDirectory_Invocations.append(())

        if let error = getACMEDirectory_MockError {
            throw error
        }

        if let mock = getACMEDirectory_MockMethod {
            return try await mock()
        } else if let mock = getACMEDirectory_MockValue {
            return mock
        } else {
            fatalError("no mock for `getACMEDirectory`")
        }
    }

    // MARK: - getACMENonce

    public var getACMENoncePath_Invocations: [String] = []
    public var getACMENoncePath_MockError: Error?
    public var getACMENoncePath_MockMethod: ((String) async throws -> String)?
    public var getACMENoncePath_MockValue: String?

    public func getACMENonce(path: String) async throws -> String {
        getACMENoncePath_Invocations.append(path)

        if let error = getACMENoncePath_MockError {
            throw error
        }

        if let mock = getACMENoncePath_MockMethod {
            return try await mock(path)
        } else if let mock = getACMENoncePath_MockValue {
            return mock
        } else {
            fatalError("no mock for `getACMENoncePath`")
        }
    }

    // MARK: - getTrustAnchor

    public var getTrustAnchor_Invocations: [Void] = []
    public var getTrustAnchor_MockError: Error?
    public var getTrustAnchor_MockMethod: (() async throws -> String)?
    public var getTrustAnchor_MockValue: String?

    public func getTrustAnchor() async throws -> String {
        getTrustAnchor_Invocations.append(())

        if let error = getTrustAnchor_MockError {
            throw error
        }

        if let mock = getTrustAnchor_MockMethod {
            return try await mock()
        } else if let mock = getTrustAnchor_MockValue {
            return mock
        } else {
            fatalError("no mock for `getTrustAnchor`")
        }
    }

    // MARK: - getFederationCertificates

    public var getFederationCertificates_Invocations: [Void] = []
    public var getFederationCertificates_MockError: Error?
    public var getFederationCertificates_MockMethod: (() async throws -> [String])?
    public var getFederationCertificates_MockValue: [String]?

    public func getFederationCertificates() async throws -> [String] {
        getFederationCertificates_Invocations.append(())

        if let error = getFederationCertificates_MockError {
            throw error
        }

        if let mock = getFederationCertificates_MockMethod {
            return try await mock()
        } else if let mock = getFederationCertificates_MockValue {
            return mock
        } else {
            fatalError("no mock for `getFederationCertificates`")
        }
    }

    // MARK: - sendACMERequest

    public var sendACMERequestPathRequestBody_Invocations: [(path: String, requestBody: Data)] = []
    public var sendACMERequestPathRequestBody_MockError: Error?
    public var sendACMERequestPathRequestBody_MockMethod: ((String, Data) async throws -> ACMEResponse)?
    public var sendACMERequestPathRequestBody_MockValue: ACMEResponse?

    public func sendACMERequest(path: String, requestBody: Data) async throws -> ACMEResponse {
        sendACMERequestPathRequestBody_Invocations.append((path: path, requestBody: requestBody))

        if let error = sendACMERequestPathRequestBody_MockError {
            throw error
        }

        if let mock = sendACMERequestPathRequestBody_MockMethod {
            return try await mock(path, requestBody)
        } else if let mock = sendACMERequestPathRequestBody_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendACMERequestPathRequestBody`")
        }
    }

    // MARK: - sendAuthorizationRequest

    public var sendAuthorizationRequestPathRequestBody_Invocations: [(path: String, requestBody: Data)] = []
    public var sendAuthorizationRequestPathRequestBody_MockError: Error?
    public var sendAuthorizationRequestPathRequestBody_MockMethod: ((String, Data) async throws -> ACMEAuthorizationResponse)?
    public var sendAuthorizationRequestPathRequestBody_MockValue: ACMEAuthorizationResponse?

    public func sendAuthorizationRequest(path: String, requestBody: Data) async throws -> ACMEAuthorizationResponse {
        sendAuthorizationRequestPathRequestBody_Invocations.append((path: path, requestBody: requestBody))

        if let error = sendAuthorizationRequestPathRequestBody_MockError {
            throw error
        }

        if let mock = sendAuthorizationRequestPathRequestBody_MockMethod {
            return try await mock(path, requestBody)
        } else if let mock = sendAuthorizationRequestPathRequestBody_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendAuthorizationRequestPathRequestBody`")
        }
    }

    // MARK: - sendChallengeRequest

    public var sendChallengeRequestPathRequestBody_Invocations: [(path: String, requestBody: Data)] = []
    public var sendChallengeRequestPathRequestBody_MockError: Error?
    public var sendChallengeRequestPathRequestBody_MockMethod: ((String, Data) async throws -> ChallengeResponse)?
    public var sendChallengeRequestPathRequestBody_MockValue: ChallengeResponse?

    public func sendChallengeRequest(path: String, requestBody: Data) async throws -> ChallengeResponse {
        sendChallengeRequestPathRequestBody_Invocations.append((path: path, requestBody: requestBody))

        if let error = sendChallengeRequestPathRequestBody_MockError {
            throw error
        }

        if let mock = sendChallengeRequestPathRequestBody_MockMethod {
            return try await mock(path, requestBody)
        } else if let mock = sendChallengeRequestPathRequestBody_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendChallengeRequestPathRequestBody`")
        }
    }

}

public class MockCertificateRevocationListAPIProtocol: CertificateRevocationListAPIProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - getRevocationList

    public var getRevocationListFrom_Invocations: [URL] = []
    public var getRevocationListFrom_MockError: Error?
    public var getRevocationListFrom_MockMethod: ((URL) async throws -> Data)?
    public var getRevocationListFrom_MockValue: Data?

    public func getRevocationList(from distributionPoint: URL) async throws -> Data {
        getRevocationListFrom_Invocations.append(distributionPoint)

        if let error = getRevocationListFrom_MockError {
            throw error
        }

        if let mock = getRevocationListFrom_MockMethod {
            return try await mock(distributionPoint)
        } else if let mock = getRevocationListFrom_MockValue {
            return mock
        } else {
            fatalError("no mock for `getRevocationListFrom`")
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

    // MARK: - syncConversationIfMissing

    public var syncConversationIfMissingQualifiedID_Invocations: [QualifiedID] = []
    public var syncConversationIfMissingQualifiedID_MockMethod: ((QualifiedID) async -> Void)?

    public func syncConversationIfMissing(qualifiedID: QualifiedID) async {
        syncConversationIfMissingQualifiedID_Invocations.append(qualifiedID)

        guard let mock = syncConversationIfMissingQualifiedID_MockMethod else {
            fatalError("no mock for `syncConversationIfMissingQualifiedID`")
        }

        await mock(qualifiedID)
    }

}

public class MockE2EIKeyPackageRotating: E2EIKeyPackageRotating {

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

public class MockEnrollE2EICertificateUseCaseProtocol: EnrollE2EICertificateUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invokeAuthenticate_Invocations: [OAuthBlock] = []
    public var invokeAuthenticate_MockError: Error?
    public var invokeAuthenticate_MockMethod: ((@escaping OAuthBlock) async throws -> String)?
    public var invokeAuthenticate_MockValue: String?

    public func invoke(authenticate: @escaping OAuthBlock) async throws -> String {
        invokeAuthenticate_Invocations.append(authenticate)

        if let error = invokeAuthenticate_MockError {
            throw error
        }

        if let mock = invokeAuthenticate_MockMethod {
            return try await mock(authenticate)
        } else if let mock = invokeAuthenticate_MockValue {
            return mock
        } else {
            fatalError("no mock for `invokeAuthenticate`")
        }
    }

}

public class MockEventDecoderProtocol: EventDecoderProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - decryptAndStoreEvents

    public var decryptAndStoreEventsPublicKeys_Invocations: [(events: [ZMUpdateEvent], publicKeys: EARPublicKeys?)] = []
    public var decryptAndStoreEventsPublicKeys_MockError: Error?
    public var decryptAndStoreEventsPublicKeys_MockMethod: (([ZMUpdateEvent], EARPublicKeys?) async throws -> [ZMUpdateEvent])?
    public var decryptAndStoreEventsPublicKeys_MockValue: [ZMUpdateEvent]?

    public func decryptAndStoreEvents(_ events: [ZMUpdateEvent], publicKeys: EARPublicKeys?) async throws -> [ZMUpdateEvent] {
        decryptAndStoreEventsPublicKeys_Invocations.append((events: events, publicKeys: publicKeys))

        if let error = decryptAndStoreEventsPublicKeys_MockError {
            throw error
        }

        if let mock = decryptAndStoreEventsPublicKeys_MockMethod {
            return try await mock(events, publicKeys)
        } else if let mock = decryptAndStoreEventsPublicKeys_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptAndStoreEventsPublicKeys`")
        }
    }

    // MARK: - processStoredEvents

    public var processStoredEventsWithCallEventsOnly_Invocations: [(privateKeys: EARPrivateKeys?, callEventsOnly: Bool, block: ([ZMUpdateEvent]) async -> Void)] = []
    public var processStoredEventsWithCallEventsOnly_MockMethod: ((EARPrivateKeys?, Bool, @escaping ([ZMUpdateEvent]) async -> Void) async -> Void)?

    public func processStoredEvents(with privateKeys: EARPrivateKeys?, callEventsOnly: Bool, _ block: @escaping ([ZMUpdateEvent]) async -> Void) async {
        processStoredEventsWithCallEventsOnly_Invocations.append((privateKeys: privateKeys, callEventsOnly: callEventsOnly, block: block))

        guard let mock = processStoredEventsWithCallEventsOnly_MockMethod else {
            fatalError("no mock for `processStoredEventsWithCallEventsOnly`")
        }

        await mock(privateKeys, callEventsOnly, block)
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

    public var broadcastProteusMessageMessage_Invocations: [Data] = []
    public var broadcastProteusMessageMessage_MockError: Error?
    public var broadcastProteusMessageMessage_MockMethod: ((Data) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse))?
    public var broadcastProteusMessageMessage_MockValue: (Payload.MessageSendingStatus, ZMTransportResponse)?

    public func broadcastProteusMessage(message encryptedMessage: Data) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse) {
        broadcastProteusMessageMessage_Invocations.append(encryptedMessage)

        if let error = broadcastProteusMessageMessage_MockError {
            throw error
        }

        if let mock = broadcastProteusMessageMessage_MockMethod {
            return try await mock(encryptedMessage)
        } else if let mock = broadcastProteusMessageMessage_MockValue {
            return mock
        } else {
            fatalError("no mock for `broadcastProteusMessageMessage`")
        }
    }

    // MARK: - sendProteusMessage

    public var sendProteusMessageMessageConversationIDExpirationDate_Invocations: [(encryptedMessage: Data, conversationID: QualifiedID, expirationDate: Date?)] = []
    public var sendProteusMessageMessageConversationIDExpirationDate_MockError: Error?
    public var sendProteusMessageMessageConversationIDExpirationDate_MockMethod: ((Data, QualifiedID, Date?) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse))?
    public var sendProteusMessageMessageConversationIDExpirationDate_MockValue: (Payload.MessageSendingStatus, ZMTransportResponse)?

    public func sendProteusMessage(message encryptedMessage: Data, conversationID: QualifiedID, expirationDate: Date?) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse) {
        sendProteusMessageMessageConversationIDExpirationDate_Invocations.append((encryptedMessage: encryptedMessage, conversationID: conversationID, expirationDate: expirationDate))

        if let error = sendProteusMessageMessageConversationIDExpirationDate_MockError {
            throw error
        }

        if let mock = sendProteusMessageMessageConversationIDExpirationDate_MockMethod {
            return try await mock(encryptedMessage, conversationID, expirationDate)
        } else if let mock = sendProteusMessageMessageConversationIDExpirationDate_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendProteusMessageMessageConversationIDExpirationDate`")
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

public class MockProteusMessage: ProteusMessage {

    // MARK: - Life cycle

    public init() {}

    // MARK: - shouldExpire

    public var shouldExpire: Bool {
        get { return underlyingShouldExpire }
        set(value) { underlyingShouldExpire = value }
    }

    public var underlyingShouldExpire: Bool!

    // MARK: - underlyingMessage

    public var underlyingMessage: GenericMessage?

    // MARK: - targetRecipients

    public var targetRecipients: Recipients {
        get { return underlyingTargetRecipients }
        set(value) { underlyingTargetRecipients = value }
    }

    public var underlyingTargetRecipients: Recipients!

    // MARK: - context

    public var context: NSManagedObjectContext {
        get { return underlyingContext }
        set(value) { underlyingContext = value }
    }

    public var underlyingContext: NSManagedObjectContext!

    // MARK: - conversation

    public var conversation: ZMConversation?

    // MARK: - dependentObjectNeedingUpdateBeforeProcessing

    public var dependentObjectNeedingUpdateBeforeProcessing: NSObject?

    // MARK: - isExpired

    public var isExpired: Bool {
        get { return underlyingIsExpired }
        set(value) { underlyingIsExpired = value }
    }

    public var underlyingIsExpired: Bool!

    // MARK: - shouldIgnoreTheSecurityLevelCheck

    public var shouldIgnoreTheSecurityLevelCheck: Bool {
        get { return underlyingShouldIgnoreTheSecurityLevelCheck }
        set(value) { underlyingShouldIgnoreTheSecurityLevelCheck = value }
    }

    public var underlyingShouldIgnoreTheSecurityLevelCheck: Bool!

    // MARK: - expirationDate

    public var expirationDate: Date?

    // MARK: - expirationReasonCode

    public var expirationReasonCode: NSNumber?


    // MARK: - setExpirationDate

    public var setExpirationDate_Invocations: [Void] = []
    public var setExpirationDate_MockMethod: (() -> Void)?

    public func setExpirationDate() {
        setExpirationDate_Invocations.append(())

        guard let mock = setExpirationDate_MockMethod else {
            fatalError("no mock for `setExpirationDate`")
        }

        mock()
    }

    // MARK: - prepareMessageForSending

    public var prepareMessageForSending_Invocations: [Void] = []
    public var prepareMessageForSending_MockError: Error?
    public var prepareMessageForSending_MockMethod: (() async throws -> Void)?

    public func prepareMessageForSending() async throws {
        prepareMessageForSending_Invocations.append(())

        if let error = prepareMessageForSending_MockError {
            throw error
        }

        guard let mock = prepareMessageForSending_MockMethod else {
            fatalError("no mock for `prepareMessageForSending`")
        }

        try await mock()
    }

    // MARK: - setUnderlyingMessage

    public var setUnderlyingMessage_Invocations: [GenericMessage] = []
    public var setUnderlyingMessage_MockError: Error?
    public var setUnderlyingMessage_MockMethod: ((GenericMessage) throws -> Void)?

    public func setUnderlyingMessage(_ message: GenericMessage) throws {
        setUnderlyingMessage_Invocations.append(message)

        if let error = setUnderlyingMessage_MockError {
            throw error
        }

        guard let mock = setUnderlyingMessage_MockMethod else {
            fatalError("no mock for `setUnderlyingMessage`")
        }

        try mock(message)
    }

    // MARK: - missesRecipients

    public var missesRecipients_Invocations: [Set<WireDataModel.UserClient>] = []
    public var missesRecipients_MockMethod: ((Set<WireDataModel.UserClient>) -> Void)?

    public func missesRecipients(_ recipients: Set<WireDataModel.UserClient>) {
        missesRecipients_Invocations.append(recipients)

        guard let mock = missesRecipients_MockMethod else {
            fatalError("no mock for `missesRecipients`")
        }

        mock(recipients)
    }

    // MARK: - detectedRedundantUsers

    public var detectedRedundantUsers_Invocations: [[ZMUser]] = []
    public var detectedRedundantUsers_MockMethod: (([ZMUser]) -> Void)?

    public func detectedRedundantUsers(_ users: [ZMUser]) {
        detectedRedundantUsers_Invocations.append(users)

        guard let mock = detectedRedundantUsers_MockMethod else {
            fatalError("no mock for `detectedRedundantUsers`")
        }

        mock(users)
    }

    // MARK: - delivered

    public var deliveredWith_Invocations: [ZMTransportResponse] = []
    public var deliveredWith_MockMethod: ((ZMTransportResponse) -> Void)?

    public func delivered(with response: ZMTransportResponse) {
        deliveredWith_Invocations.append(response)

        guard let mock = deliveredWith_MockMethod else {
            fatalError("no mock for `deliveredWith`")
        }

        mock(response)
    }

    // MARK: - addFailedToSendRecipients

    public var addFailedToSendRecipients_Invocations: [[ZMUser]] = []
    public var addFailedToSendRecipients_MockMethod: (([ZMUser]) -> Void)?

    public func addFailedToSendRecipients(_ recipients: [ZMUser]) {
        addFailedToSendRecipients_Invocations.append(recipients)

        guard let mock = addFailedToSendRecipients_MockMethod else {
            fatalError("no mock for `addFailedToSendRecipients`")
        }

        mock(recipients)
    }

    // MARK: - expire

    public var expire_Invocations: [Void] = []
    public var expire_MockMethod: (() -> Void)?

    public func expire() {
        expire_Invocations.append(())

        guard let mock = expire_MockMethod else {
            fatalError("no mock for `expire`")
        }

        mock()
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

public class MockSyncProgress: SyncProgress {

    // MARK: - Life cycle

    public init() {}

    // MARK: - currentSyncPhase

    public var currentSyncPhase: SyncPhase {
        get { return underlyingCurrentSyncPhase }
        set(value) { underlyingCurrentSyncPhase = value }
    }

    public var underlyingCurrentSyncPhase: SyncPhase!


    // MARK: - finishCurrentSyncPhase

    public var finishCurrentSyncPhasePhase_Invocations: [SyncPhase] = []
    public var finishCurrentSyncPhasePhase_MockMethod: ((SyncPhase) -> Void)?

    public func finishCurrentSyncPhase(phase: SyncPhase) {
        finishCurrentSyncPhasePhase_Invocations.append(phase)

        guard let mock = finishCurrentSyncPhasePhase_MockMethod else {
            fatalError("no mock for `finishCurrentSyncPhasePhase`")
        }

        mock(phase)
    }

    // MARK: - failCurrentSyncPhase

    public var failCurrentSyncPhasePhase_Invocations: [SyncPhase] = []
    public var failCurrentSyncPhasePhase_MockMethod: ((SyncPhase) -> Void)?

    public func failCurrentSyncPhase(phase: SyncPhase) {
        failCurrentSyncPhasePhase_Invocations.append(phase)

        guard let mock = failCurrentSyncPhasePhase_MockMethod else {
            fatalError("no mock for `failCurrentSyncPhasePhase`")
        }

        mock(phase)
    }

}

public class MockUserClientAPI: UserClientAPI {

    // MARK: - Life cycle

    public init() {}


    // MARK: - deleteUserClient

    public var deleteUserClientClientIdPassword_Invocations: [(clientId: String, password: String)] = []
    public var deleteUserClientClientIdPassword_MockError: Error?
    public var deleteUserClientClientIdPassword_MockMethod: ((String, String) async throws -> Void)?

    public func deleteUserClient(clientId: String, password: String) async throws {
        deleteUserClientClientIdPassword_Invocations.append((clientId: clientId, password: password))

        if let error = deleteUserClientClientIdPassword_MockError {
            throw error
        }

        guard let mock = deleteUserClientClientIdPassword_MockMethod else {
            fatalError("no mock for `deleteUserClientClientIdPassword`")
        }

        try await mock(clientId, password)
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
