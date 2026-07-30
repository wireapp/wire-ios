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


import LocalAuthentication
import Combine
import WireCoreCrypto

@testable import WireDataModel
























public class MockAuthenticationContextProtocol: AuthenticationContextProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - laContext

    public var laContext: LAContext {
        get { return underlyingLaContext }
        set(value) { underlyingLaContext = value }
    }

    public var underlyingLaContext: LAContext!

    // MARK: - evaluatedPolicyDomainState

    public var evaluatedPolicyDomainState: Data?


    // MARK: - canEvaluatePolicy

    public var canEvaluatePolicyError_Invocations: [(policy: LAPolicy, error: NSErrorPointer)] = []
    public var canEvaluatePolicyError_MockMethod: ((LAPolicy, NSErrorPointer) -> Bool)?
    public var canEvaluatePolicyError_MockValue: Bool?

    public func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        canEvaluatePolicyError_Invocations.append((policy: policy, error: error))

        if let mock = canEvaluatePolicyError_MockMethod {
            return mock(policy, error)
        } else if let mock = canEvaluatePolicyError_MockValue {
            return mock
        } else {
            fatalError("no mock for `canEvaluatePolicyError`")
        }
    }

    // MARK: - evaluatePolicy

    public var evaluatePolicyLocalizedReasonReply_Invocations: [(policy: LAPolicy, localizedReason: String, reply: (Bool, Error?) -> Void)] = []
    public var evaluatePolicyLocalizedReasonReply_MockMethod: ((LAPolicy, String, @escaping (Bool, Error?) -> Void) -> Void)?

    public func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
        evaluatePolicyLocalizedReasonReply_Invocations.append((policy: policy, localizedReason: localizedReason, reply: reply))

        guard let mock = evaluatePolicyLocalizedReasonReply_MockMethod else {
            fatalError("no mock for `evaluatePolicyLocalizedReasonReply`")
        }

        mock(policy, localizedReason, reply)
    }

}

class MockBiometricsStateProtocol: BiometricsStateProtocol {

    // MARK: - Life cycle



    // MARK: - biometricsChanged

    var biometricsChangedIn_Invocations: [AuthenticationContextProtocol] = []
    var biometricsChangedIn_MockMethod: ((AuthenticationContextProtocol) -> Bool)?
    var biometricsChangedIn_MockValue: Bool?

    func biometricsChanged(in context: AuthenticationContextProtocol) -> Bool {
        biometricsChangedIn_Invocations.append(context)

        if let mock = biometricsChangedIn_MockMethod {
            return mock(context)
        } else if let mock = biometricsChangedIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `biometricsChangedIn`")
        }
    }

    // MARK: - persistState

    var persistState_Invocations: [Void] = []
    var persistState_MockMethod: (() -> Void)?

    func persistState() {
        persistState_Invocations.append(())

        guard let mock = persistState_MockMethod else {
            fatalError("no mock for `persistState`")
        }

        mock()
    }

}

public class MockConversationLike: ConversationLike {

    // MARK: - Life cycle

    public init() {}

    // MARK: - objectId

    public var objectId: Any {
        get { return underlyingObjectId }
        set(value) { underlyingObjectId = value }
    }

    public var underlyingObjectId: Any!

    // MARK: - conversationType

    public var conversationType: ZMConversationType {
        get { return underlyingConversationType }
        set(value) { underlyingConversationType = value }
    }

    public var underlyingConversationType: ZMConversationType!

    // MARK: - isSelfAnActiveMember

    public var isSelfAnActiveMember: Bool {
        get { return underlyingIsSelfAnActiveMember }
        set(value) { underlyingIsSelfAnActiveMember = value }
    }

    public var underlyingIsSelfAnActiveMember: Bool!

    // MARK: - teamRemoteIdentifier

    public var teamRemoteIdentifier: UUID?

    // MARK: - localParticipantsCount

    public var localParticipantsCount: Int {
        get { return underlyingLocalParticipantsCount }
        set(value) { underlyingLocalParticipantsCount = value }
    }

    public var underlyingLocalParticipantsCount: Int!

    // MARK: - displayName

    public var displayName: String?

    // MARK: - connectedUserType

    public var connectedUserType: UserType?

    // MARK: - allowGuests

    public var allowGuests: Bool {
        get { return underlyingAllowGuests }
        set(value) { underlyingAllowGuests = value }
    }

    public var underlyingAllowGuests: Bool!

    // MARK: - allowApps

    public var allowApps: Bool {
        get { return underlyingAllowApps }
        set(value) { underlyingAllowApps = value }
    }

    public var underlyingAllowApps: Bool!

    // MARK: - isUnderLegalHold

    public var isUnderLegalHold: Bool {
        get { return underlyingIsUnderLegalHold }
        set(value) { underlyingIsUnderLegalHold = value }
    }

    public var underlyingIsUnderLegalHold: Bool!

    // MARK: - isMLSConversationDegraded

    public var isMLSConversationDegraded: Bool {
        get { return underlyingIsMLSConversationDegraded }
        set(value) { underlyingIsMLSConversationDegraded = value }
    }

    public var underlyingIsMLSConversationDegraded: Bool!

    // MARK: - isProteusConversationDegraded

    public var isProteusConversationDegraded: Bool {
        get { return underlyingIsProteusConversationDegraded }
        set(value) { underlyingIsProteusConversationDegraded = value }
    }

    public var underlyingIsProteusConversationDegraded: Bool!

    // MARK: - sortedActiveParticipantsUserTypes

    public var sortedActiveParticipantsUserTypes: [UserType] = []

    // MARK: - relatedConnectionState

    public var relatedConnectionState: ZMConnectionStatus {
        get { return underlyingRelatedConnectionState }
        set(value) { underlyingRelatedConnectionState = value }
    }

    public var underlyingRelatedConnectionState: ZMConnectionStatus!

    // MARK: - lastMessage

    public var lastMessage: ZMConversationMessage?

    // MARK: - firstUnreadMessage

    public var firstUnreadMessage: ZMConversationMessage?

    // MARK: - areAppsPresent

    public var areAppsPresent: Bool {
        get { return underlyingAreAppsPresent }
        set(value) { underlyingAreAppsPresent = value }
    }

    public var underlyingAreAppsPresent: Bool!

    // MARK: - domain

    public var domain: String?

    // MARK: - isChannel

    public var isChannel: Bool {
        get { return underlyingIsChannel }
        set(value) { underlyingIsChannel = value }
    }

    public var underlyingIsChannel: Bool!

    // MARK: - privateChannelPermission

    public var privateChannelPermission: PrivateChannelPermission {
        get { return underlyingPrivateChannelPermission }
        set(value) { underlyingPrivateChannelPermission = value }
    }

    public var underlyingPrivateChannelPermission: PrivateChannelPermission!

    // MARK: - channelHistoryDepth

    public var channelHistoryDepth: String?

    // MARK: - hasMoreHistory

    public var hasMoreHistory: Bool {
        get { return underlyingHasMoreHistory }
        set(value) { underlyingHasMoreHistory = value }
    }

    public var underlyingHasMoreHistory: Bool!

    // MARK: - wireDriveCellName

    public var wireDriveCellName: String {
        get { return underlyingWireDriveCellName }
        set(value) { underlyingWireDriveCellName = value }
    }

    public var underlyingWireDriveCellName: String!

    // MARK: - isWireDriveEnabled

    public var isWireDriveEnabled: Bool {
        get { return underlyingIsWireDriveEnabled }
        set(value) { underlyingIsWireDriveEnabled = value }
    }

    public var underlyingIsWireDriveEnabled: Bool!

    // MARK: - isTeamConversation

    public var isTeamConversation: Bool {
        get { return underlyingIsTeamConversation }
        set(value) { underlyingIsTeamConversation = value }
    }

    public var underlyingIsTeamConversation: Bool!


    // MARK: - localParticipantsContain

    public var localParticipantsContainUser_Invocations: [UserType] = []
    public var localParticipantsContainUser_MockMethod: ((UserType) -> Bool)?
    public var localParticipantsContainUser_MockValue: Bool?

    public func localParticipantsContain(user: UserType) -> Bool {
        localParticipantsContainUser_Invocations.append(user)

        if let mock = localParticipantsContainUser_MockMethod {
            return mock(user)
        } else if let mock = localParticipantsContainUser_MockValue {
            return mock
        } else {
            fatalError("no mock for `localParticipantsContainUser`")
        }
    }

    // MARK: - verifyLegalHoldSubjects

    public var verifyLegalHoldSubjects_Invocations: [Void] = []
    public var verifyLegalHoldSubjects_MockMethod: (() -> Void)?

    public func verifyLegalHoldSubjects() {
        verifyLegalHoldSubjects_Invocations.append(())

        guard let mock = verifyLegalHoldSubjects_MockMethod else {
            fatalError("no mock for `verifyLegalHoldSubjects`")
        }

        mock()
    }

}

public class MockCoreCryptoContextProtocol: CoreCryptoContextProtocol, @unchecked Sendable {

    // MARK: - Life cycle

    public init() {}


    // MARK: - addClientsToConversation

    public var addClientsToConversationConversationIdKeyPackages_Invocations: [(conversationId: WireCoreCryptoUniffi.ConversationId, keyPackages: [WireCoreCryptoUniffi.KeyPackage])] = []
    public var addClientsToConversationConversationIdKeyPackages_MockError: Error?
    public var addClientsToConversationConversationIdKeyPackages_MockMethod: ((WireCoreCryptoUniffi.ConversationId, [WireCoreCryptoUniffi.KeyPackage]) async throws -> Void)?

    public func addClientsToConversation(conversationId: WireCoreCryptoUniffi.ConversationId, keyPackages: [WireCoreCryptoUniffi.KeyPackage]) async throws {
        addClientsToConversationConversationIdKeyPackages_Invocations.append((conversationId: conversationId, keyPackages: keyPackages))

        if let error = addClientsToConversationConversationIdKeyPackages_MockError {
            throw error
        }

        guard let mock = addClientsToConversationConversationIdKeyPackages_MockMethod else {
            fatalError("no mock for `addClientsToConversationConversationIdKeyPackages`")
        }

        try await mock(conversationId, keyPackages)
    }

    // MARK: - addCredential

    public var addCredentialCredential_Invocations: [WireCoreCryptoUniffi.Credential] = []
    public var addCredentialCredential_MockError: Error?
    public var addCredentialCredential_MockMethod: ((WireCoreCryptoUniffi.Credential) async throws -> WireCoreCryptoUniffi.CredentialRef)?
    public var addCredentialCredential_MockValue: WireCoreCryptoUniffi.CredentialRef?

    public func addCredential(credential: WireCoreCryptoUniffi.Credential) async throws -> WireCoreCryptoUniffi.CredentialRef {
        addCredentialCredential_Invocations.append(credential)

        if let error = addCredentialCredential_MockError {
            throw error
        }

        if let mock = addCredentialCredential_MockMethod {
            return try await mock(credential)
        } else if let mock = addCredentialCredential_MockValue {
            return mock
        } else {
            fatalError("no mock for `addCredentialCredential`")
        }
    }

    // MARK: - checkCredentials

    public var checkCredentials_Invocations: [Void] = []
    public var checkCredentials_MockError: Error?
    public var checkCredentials_MockMethod: (() async throws -> Void)?

    public func checkCredentials() async throws {
        checkCredentials_Invocations.append(())

        if let error = checkCredentials_MockError {
            throw error
        }

        guard let mock = checkCredentials_MockMethod else {
            fatalError("no mock for `checkCredentials`")
        }

        try await mock()
    }

    // MARK: - commitPendingProposals

    public var commitPendingProposalsConversationId_Invocations: [WireCoreCryptoUniffi.ConversationId] = []
    public var commitPendingProposalsConversationId_MockError: Error?
    public var commitPendingProposalsConversationId_MockMethod: ((WireCoreCryptoUniffi.ConversationId) async throws -> Void)?

    public func commitPendingProposals(conversationId: WireCoreCryptoUniffi.ConversationId) async throws {
        commitPendingProposalsConversationId_Invocations.append(conversationId)

        if let error = commitPendingProposalsConversationId_MockError {
            throw error
        }

        guard let mock = commitPendingProposalsConversationId_MockMethod else {
            fatalError("no mock for `commitPendingProposalsConversationId`")
        }

        try await mock(conversationId)
    }

    // MARK: - conversationCipherSuite

    public var conversationCipherSuiteConversationId_Invocations: [WireCoreCryptoUniffi.ConversationId] = []
    public var conversationCipherSuiteConversationId_MockError: Error?
    public var conversationCipherSuiteConversationId_MockMethod: ((WireCoreCryptoUniffi.ConversationId) async throws -> WireCoreCryptoUniffi.CipherSuite)?
    public var conversationCipherSuiteConversationId_MockValue: WireCoreCryptoUniffi.CipherSuite?

    public func conversationCipherSuite(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> WireCoreCryptoUniffi.CipherSuite {
        conversationCipherSuiteConversationId_Invocations.append(conversationId)

        if let error = conversationCipherSuiteConversationId_MockError {
            throw error
        }

        if let mock = conversationCipherSuiteConversationId_MockMethod {
            return try await mock(conversationId)
        } else if let mock = conversationCipherSuiteConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationCipherSuiteConversationId`")
        }
    }

    // MARK: - conversationCredential

    public var conversationCredentialConversationId_Invocations: [WireCoreCryptoUniffi.ConversationId] = []
    public var conversationCredentialConversationId_MockError: Error?
    public var conversationCredentialConversationId_MockMethod: ((WireCoreCryptoUniffi.ConversationId) async throws -> WireCoreCryptoUniffi.CredentialRef)?
    public var conversationCredentialConversationId_MockValue: WireCoreCryptoUniffi.CredentialRef?

    public func conversationCredential(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> WireCoreCryptoUniffi.CredentialRef {
        conversationCredentialConversationId_Invocations.append(conversationId)

        if let error = conversationCredentialConversationId_MockError {
            throw error
        }

        if let mock = conversationCredentialConversationId_MockMethod {
            return try await mock(conversationId)
        } else if let mock = conversationCredentialConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationCredentialConversationId`")
        }
    }

    // MARK: - conversationEpoch

    public var conversationEpochConversationId_Invocations: [WireCoreCryptoUniffi.ConversationId] = []
    public var conversationEpochConversationId_MockError: Error?
    public var conversationEpochConversationId_MockMethod: ((WireCoreCryptoUniffi.ConversationId) async throws -> UInt64)?
    public var conversationEpochConversationId_MockValue: UInt64?

    public func conversationEpoch(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> UInt64 {
        conversationEpochConversationId_Invocations.append(conversationId)

        if let error = conversationEpochConversationId_MockError {
            throw error
        }

        if let mock = conversationEpochConversationId_MockMethod {
            return try await mock(conversationId)
        } else if let mock = conversationEpochConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationEpochConversationId`")
        }
    }

    // MARK: - conversationExists

    public var conversationExistsConversationId_Invocations: [WireCoreCryptoUniffi.ConversationId] = []
    public var conversationExistsConversationId_MockError: Error?
    public var conversationExistsConversationId_MockMethod: ((WireCoreCryptoUniffi.ConversationId) async throws -> Bool)?
    public var conversationExistsConversationId_MockValue: Bool?

    public func conversationExists(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> Bool {
        conversationExistsConversationId_Invocations.append(conversationId)

        if let error = conversationExistsConversationId_MockError {
            throw error
        }

        if let mock = conversationExistsConversationId_MockMethod {
            return try await mock(conversationId)
        } else if let mock = conversationExistsConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationExistsConversationId`")
        }
    }

    // MARK: - createConversation

    public var createConversationConversationIdCredentialRefExternalSender_Invocations: [(conversationId: WireCoreCryptoUniffi.ConversationId, credentialRef: WireCoreCryptoUniffi.CredentialRef, externalSender: WireCoreCryptoUniffi.ExternalSender?)] = []
    public var createConversationConversationIdCredentialRefExternalSender_MockError: Error?
    public var createConversationConversationIdCredentialRefExternalSender_MockMethod: ((WireCoreCryptoUniffi.ConversationId, WireCoreCryptoUniffi.CredentialRef, WireCoreCryptoUniffi.ExternalSender?) async throws -> Void)?

    public func createConversation(conversationId: WireCoreCryptoUniffi.ConversationId, credentialRef: WireCoreCryptoUniffi.CredentialRef, externalSender: WireCoreCryptoUniffi.ExternalSender?) async throws {
        createConversationConversationIdCredentialRefExternalSender_Invocations.append((conversationId: conversationId, credentialRef: credentialRef, externalSender: externalSender))

        if let error = createConversationConversationIdCredentialRefExternalSender_MockError {
            throw error
        }

        guard let mock = createConversationConversationIdCredentialRefExternalSender_MockMethod else {
            fatalError("no mock for `createConversationConversationIdCredentialRefExternalSender`")
        }

        try await mock(conversationId, credentialRef, externalSender)
    }

    // MARK: - decryptMessage

    public var decryptMessageConversationIdPayload_Invocations: [(conversationId: WireCoreCryptoUniffi.ConversationId, payload: Data)] = []
    public var decryptMessageConversationIdPayload_MockError: Error?
    public var decryptMessageConversationIdPayload_MockMethod: ((WireCoreCryptoUniffi.ConversationId, Data) async throws -> WireCoreCryptoUniffi.DecryptedMessage)?
    public var decryptMessageConversationIdPayload_MockValue: WireCoreCryptoUniffi.DecryptedMessage?

    public func decryptMessage(conversationId: WireCoreCryptoUniffi.ConversationId, payload: Data) async throws -> WireCoreCryptoUniffi.DecryptedMessage {
        decryptMessageConversationIdPayload_Invocations.append((conversationId: conversationId, payload: payload))

        if let error = decryptMessageConversationIdPayload_MockError {
            throw error
        }

        if let mock = decryptMessageConversationIdPayload_MockMethod {
            return try await mock(conversationId, payload)
        } else if let mock = decryptMessageConversationIdPayload_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptMessageConversationIdPayload`")
        }
    }

    // MARK: - disableHistorySharing

    public var disableHistorySharingConversationId_Invocations: [WireCoreCryptoUniffi.ConversationId] = []
    public var disableHistorySharingConversationId_MockError: Error?
    public var disableHistorySharingConversationId_MockMethod: ((WireCoreCryptoUniffi.ConversationId) async throws -> Void)?

    public func disableHistorySharing(conversationId: WireCoreCryptoUniffi.ConversationId) async throws {
        disableHistorySharingConversationId_Invocations.append(conversationId)

        if let error = disableHistorySharingConversationId_MockError {
            throw error
        }

        guard let mock = disableHistorySharingConversationId_MockMethod else {
            fatalError("no mock for `disableHistorySharingConversationId`")
        }

        try await mock(conversationId)
    }

    // MARK: - e2eiConversationState

    public var e2eiConversationStateConversationId_Invocations: [WireCoreCryptoUniffi.ConversationId] = []
    public var e2eiConversationStateConversationId_MockError: Error?
    public var e2eiConversationStateConversationId_MockMethod: ((WireCoreCryptoUniffi.ConversationId) async throws -> WireCoreCryptoUniffi.E2eiConversationState)?
    public var e2eiConversationStateConversationId_MockValue: WireCoreCryptoUniffi.E2eiConversationState?

    public func e2eiConversationState(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> WireCoreCryptoUniffi.E2eiConversationState {
        e2eiConversationStateConversationId_Invocations.append(conversationId)

        if let error = e2eiConversationStateConversationId_MockError {
            throw error
        }

        if let mock = e2eiConversationStateConversationId_MockMethod {
            return try await mock(conversationId)
        } else if let mock = e2eiConversationStateConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiConversationStateConversationId`")
        }
    }

    // MARK: - e2eiIsEnabled

    public var e2eiIsEnabledCipherSuite_Invocations: [WireCoreCryptoUniffi.CipherSuite] = []
    public var e2eiIsEnabledCipherSuite_MockError: Error?
    public var e2eiIsEnabledCipherSuite_MockMethod: ((WireCoreCryptoUniffi.CipherSuite) async throws -> Bool)?
    public var e2eiIsEnabledCipherSuite_MockValue: Bool?

    public func e2eiIsEnabled(cipherSuite: WireCoreCryptoUniffi.CipherSuite) async throws -> Bool {
        e2eiIsEnabledCipherSuite_Invocations.append(cipherSuite)

        if let error = e2eiIsEnabledCipherSuite_MockError {
            throw error
        }

        if let mock = e2eiIsEnabledCipherSuite_MockMethod {
            return try await mock(cipherSuite)
        } else if let mock = e2eiIsEnabledCipherSuite_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiIsEnabledCipherSuite`")
        }
    }

    // MARK: - enableHistorySharing

    public var enableHistorySharingConversationId_Invocations: [WireCoreCryptoUniffi.ConversationId] = []
    public var enableHistorySharingConversationId_MockError: Error?
    public var enableHistorySharingConversationId_MockMethod: ((WireCoreCryptoUniffi.ConversationId) async throws -> Void)?

    public func enableHistorySharing(conversationId: WireCoreCryptoUniffi.ConversationId) async throws {
        enableHistorySharingConversationId_Invocations.append(conversationId)

        if let error = enableHistorySharingConversationId_MockError {
            throw error
        }

        guard let mock = enableHistorySharingConversationId_MockMethod else {
            fatalError("no mock for `enableHistorySharingConversationId`")
        }

        try await mock(conversationId)
    }

    // MARK: - encryptMessage

    public var encryptMessageConversationIdMessage_Invocations: [(conversationId: WireCoreCryptoUniffi.ConversationId, message: Data)] = []
    public var encryptMessageConversationIdMessage_MockError: Error?
    public var encryptMessageConversationIdMessage_MockMethod: ((WireCoreCryptoUniffi.ConversationId, Data) async throws -> Data)?
    public var encryptMessageConversationIdMessage_MockValue: Data?

    public func encryptMessage(conversationId: WireCoreCryptoUniffi.ConversationId, message: Data) async throws -> Data {
        encryptMessageConversationIdMessage_Invocations.append((conversationId: conversationId, message: message))

        if let error = encryptMessageConversationIdMessage_MockError {
            throw error
        }

        if let mock = encryptMessageConversationIdMessage_MockMethod {
            return try await mock(conversationId, message)
        } else if let mock = encryptMessageConversationIdMessage_MockValue {
            return mock
        } else {
            fatalError("no mock for `encryptMessageConversationIdMessage`")
        }
    }

    // MARK: - exportSecretKey

    public var exportSecretKeyConversationIdKeyLength_Invocations: [(conversationId: WireCoreCryptoUniffi.ConversationId, keyLength: UInt32)] = []
    public var exportSecretKeyConversationIdKeyLength_MockError: Error?
    public var exportSecretKeyConversationIdKeyLength_MockMethod: ((WireCoreCryptoUniffi.ConversationId, UInt32) async throws -> WireCoreCryptoUniffi.SecretKey)?
    public var exportSecretKeyConversationIdKeyLength_MockValue: WireCoreCryptoUniffi.SecretKey?

    public func exportSecretKey(conversationId: WireCoreCryptoUniffi.ConversationId, keyLength: UInt32) async throws -> WireCoreCryptoUniffi.SecretKey {
        exportSecretKeyConversationIdKeyLength_Invocations.append((conversationId: conversationId, keyLength: keyLength))

        if let error = exportSecretKeyConversationIdKeyLength_MockError {
            throw error
        }

        if let mock = exportSecretKeyConversationIdKeyLength_MockMethod {
            return try await mock(conversationId, keyLength)
        } else if let mock = exportSecretKeyConversationIdKeyLength_MockValue {
            return mock
        } else {
            fatalError("no mock for `exportSecretKeyConversationIdKeyLength`")
        }
    }

    // MARK: - generateKeyPackage

    public var generateKeyPackageCredentialRefLifetime_Invocations: [(credentialRef: WireCoreCryptoUniffi.CredentialRef, lifetime: TimeInterval?)] = []
    public var generateKeyPackageCredentialRefLifetime_MockError: Error?
    public var generateKeyPackageCredentialRefLifetime_MockMethod: ((WireCoreCryptoUniffi.CredentialRef, TimeInterval?) async throws -> WireCoreCryptoUniffi.KeyPackage)?
    public var generateKeyPackageCredentialRefLifetime_MockValue: WireCoreCryptoUniffi.KeyPackage?

    public func generateKeyPackage(credentialRef: WireCoreCryptoUniffi.CredentialRef, lifetime: TimeInterval?) async throws -> WireCoreCryptoUniffi.KeyPackage {
        generateKeyPackageCredentialRefLifetime_Invocations.append((credentialRef: credentialRef, lifetime: lifetime))

        if let error = generateKeyPackageCredentialRefLifetime_MockError {
            throw error
        }

        if let mock = generateKeyPackageCredentialRefLifetime_MockMethod {
            return try await mock(credentialRef, lifetime)
        } else if let mock = generateKeyPackageCredentialRefLifetime_MockValue {
            return mock
        } else {
            fatalError("no mock for `generateKeyPackageCredentialRefLifetime`")
        }
    }

    // MARK: - getClientIds

    public var getClientIdsConversationId_Invocations: [WireCoreCryptoUniffi.ConversationId] = []
    public var getClientIdsConversationId_MockError: Error?
    public var getClientIdsConversationId_MockMethod: ((WireCoreCryptoUniffi.ConversationId) async throws -> [WireCoreCryptoUniffi.ClientId])?
    public var getClientIdsConversationId_MockValue: [WireCoreCryptoUniffi.ClientId]?

    public func getClientIds(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> [WireCoreCryptoUniffi.ClientId] {
        getClientIdsConversationId_Invocations.append(conversationId)

        if let error = getClientIdsConversationId_MockError {
            throw error
        }

        if let mock = getClientIdsConversationId_MockMethod {
            return try await mock(conversationId)
        } else if let mock = getClientIdsConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `getClientIdsConversationId`")
        }
    }

    // MARK: - getData

    public var getData_Invocations: [Void] = []
    public var getData_MockError: Error?
    public var getData_MockMethod: (() async throws -> Data?)?
    public var getData_MockValue: Data??

    public func getData() async throws -> Data? {
        getData_Invocations.append(())

        if let error = getData_MockError {
            throw error
        }

        if let mock = getData_MockMethod {
            return try await mock()
        } else if let mock = getData_MockValue {
            return mock
        } else {
            fatalError("no mock for `getData`")
        }
    }

    // MARK: - getDeviceIdentities

    public var getDeviceIdentitiesConversationIdDeviceIds_Invocations: [(conversationId: WireCoreCryptoUniffi.ConversationId, deviceIds: [WireCoreCryptoUniffi.ClientId])] = []
    public var getDeviceIdentitiesConversationIdDeviceIds_MockError: Error?
    public var getDeviceIdentitiesConversationIdDeviceIds_MockMethod: ((WireCoreCryptoUniffi.ConversationId, [WireCoreCryptoUniffi.ClientId]) async throws -> [WireCoreCryptoUniffi.WireIdentity])?
    public var getDeviceIdentitiesConversationIdDeviceIds_MockValue: [WireCoreCryptoUniffi.WireIdentity]?

    public func getDeviceIdentities(conversationId: WireCoreCryptoUniffi.ConversationId, deviceIds: [WireCoreCryptoUniffi.ClientId]) async throws -> [WireCoreCryptoUniffi.WireIdentity] {
        getDeviceIdentitiesConversationIdDeviceIds_Invocations.append((conversationId: conversationId, deviceIds: deviceIds))

        if let error = getDeviceIdentitiesConversationIdDeviceIds_MockError {
            throw error
        }

        if let mock = getDeviceIdentitiesConversationIdDeviceIds_MockMethod {
            return try await mock(conversationId, deviceIds)
        } else if let mock = getDeviceIdentitiesConversationIdDeviceIds_MockValue {
            return mock
        } else {
            fatalError("no mock for `getDeviceIdentitiesConversationIdDeviceIds`")
        }
    }

    // MARK: - getExternalSender

    public var getExternalSenderConversationId_Invocations: [WireCoreCryptoUniffi.ConversationId] = []
    public var getExternalSenderConversationId_MockError: Error?
    public var getExternalSenderConversationId_MockMethod: ((WireCoreCryptoUniffi.ConversationId) async throws -> WireCoreCryptoUniffi.ExternalSender)?
    public var getExternalSenderConversationId_MockValue: WireCoreCryptoUniffi.ExternalSender?

    public func getExternalSender(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> WireCoreCryptoUniffi.ExternalSender {
        getExternalSenderConversationId_Invocations.append(conversationId)

        if let error = getExternalSenderConversationId_MockError {
            throw error
        }

        if let mock = getExternalSenderConversationId_MockMethod {
            return try await mock(conversationId)
        } else if let mock = getExternalSenderConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `getExternalSenderConversationId`")
        }
    }

    // MARK: - getKeyPackages

    public var getKeyPackages_Invocations: [Void] = []
    public var getKeyPackages_MockError: Error?
    public var getKeyPackages_MockMethod: (() async throws -> [WireCoreCryptoUniffi.KeyPackageRef])?
    public var getKeyPackages_MockValue: [WireCoreCryptoUniffi.KeyPackageRef]?

    public func getKeyPackages() async throws -> [WireCoreCryptoUniffi.KeyPackageRef] {
        getKeyPackages_Invocations.append(())

        if let error = getKeyPackages_MockError {
            throw error
        }

        if let mock = getKeyPackages_MockMethod {
            return try await mock()
        } else if let mock = getKeyPackages_MockValue {
            return mock
        } else {
            fatalError("no mock for `getKeyPackages`")
        }
    }

    // MARK: - getUserIdentities

    public var getUserIdentitiesConversationIdUserIds_Invocations: [(conversationId: WireCoreCryptoUniffi.ConversationId, userIds: [WireCoreCryptoUniffi.Uuid])] = []
    public var getUserIdentitiesConversationIdUserIds_MockError: Error?
    public var getUserIdentitiesConversationIdUserIds_MockMethod: ((WireCoreCryptoUniffi.ConversationId, [WireCoreCryptoUniffi.Uuid]) async throws -> [WireCoreCryptoUniffi.Uuid: [WireCoreCryptoUniffi.WireIdentity]])?
    public var getUserIdentitiesConversationIdUserIds_MockValue: [WireCoreCryptoUniffi.Uuid: [WireCoreCryptoUniffi.WireIdentity]]?

    public func getUserIdentities(conversationId: WireCoreCryptoUniffi.ConversationId, userIds: [WireCoreCryptoUniffi.Uuid]) async throws -> [WireCoreCryptoUniffi.Uuid: [WireCoreCryptoUniffi.WireIdentity]] {
        getUserIdentitiesConversationIdUserIds_Invocations.append((conversationId: conversationId, userIds: userIds))

        if let error = getUserIdentitiesConversationIdUserIds_MockError {
            throw error
        }

        if let mock = getUserIdentitiesConversationIdUserIds_MockMethod {
            return try await mock(conversationId, userIds)
        } else if let mock = getUserIdentitiesConversationIdUserIds_MockValue {
            return mock
        } else {
            fatalError("no mock for `getUserIdentitiesConversationIdUserIds`")
        }
    }

    // MARK: - joinByExternalCommit

    public var joinByExternalCommitGroupInfoCredentialRef_Invocations: [(groupInfo: WireCoreCryptoUniffi.GroupInfo, credentialRef: WireCoreCryptoUniffi.CredentialRef)] = []
    public var joinByExternalCommitGroupInfoCredentialRef_MockError: Error?
    public var joinByExternalCommitGroupInfoCredentialRef_MockMethod: ((WireCoreCryptoUniffi.GroupInfo, WireCoreCryptoUniffi.CredentialRef) async throws -> WireCoreCryptoUniffi.ConversationId)?
    public var joinByExternalCommitGroupInfoCredentialRef_MockValue: WireCoreCryptoUniffi.ConversationId?

    public func joinByExternalCommit(groupInfo: WireCoreCryptoUniffi.GroupInfo, credentialRef: WireCoreCryptoUniffi.CredentialRef) async throws -> WireCoreCryptoUniffi.ConversationId {
        joinByExternalCommitGroupInfoCredentialRef_Invocations.append((groupInfo: groupInfo, credentialRef: credentialRef))

        if let error = joinByExternalCommitGroupInfoCredentialRef_MockError {
            throw error
        }

        if let mock = joinByExternalCommitGroupInfoCredentialRef_MockMethod {
            return try await mock(groupInfo, credentialRef)
        } else if let mock = joinByExternalCommitGroupInfoCredentialRef_MockValue {
            return mock
        } else {
            fatalError("no mock for `joinByExternalCommitGroupInfoCredentialRef`")
        }
    }

    // MARK: - mlsInit

    public var mlsInitClientIdTransport_Invocations: [(clientId: WireCoreCryptoUniffi.ClientId, transport: any WireCoreCryptoUniffi.MlsTransport)] = []
    public var mlsInitClientIdTransport_MockError: Error?
    public var mlsInitClientIdTransport_MockMethod: ((WireCoreCryptoUniffi.ClientId, any WireCoreCryptoUniffi.MlsTransport) async throws -> Void)?

    public func mlsInit(clientId: WireCoreCryptoUniffi.ClientId, transport: any WireCoreCryptoUniffi.MlsTransport) async throws {
        mlsInitClientIdTransport_Invocations.append((clientId: clientId, transport: transport))

        if let error = mlsInitClientIdTransport_MockError {
            throw error
        }

        guard let mock = mlsInitClientIdTransport_MockMethod else {
            fatalError("no mock for `mlsInitClientIdTransport`")
        }

        try await mock(clientId, transport)
    }

    // MARK: - processWelcomeMessage

    public var processWelcomeMessageWelcomeMessage_Invocations: [WireCoreCryptoUniffi.Welcome] = []
    public var processWelcomeMessageWelcomeMessage_MockError: Error?
    public var processWelcomeMessageWelcomeMessage_MockMethod: ((WireCoreCryptoUniffi.Welcome) async throws -> WireCoreCryptoUniffi.ConversationId)?
    public var processWelcomeMessageWelcomeMessage_MockValue: WireCoreCryptoUniffi.ConversationId?

    public func processWelcomeMessage(welcomeMessage: WireCoreCryptoUniffi.Welcome) async throws -> WireCoreCryptoUniffi.ConversationId {
        processWelcomeMessageWelcomeMessage_Invocations.append(welcomeMessage)

        if let error = processWelcomeMessageWelcomeMessage_MockError {
            throw error
        }

        if let mock = processWelcomeMessageWelcomeMessage_MockMethod {
            return try await mock(welcomeMessage)
        } else if let mock = processWelcomeMessageWelcomeMessage_MockValue {
            return mock
        } else {
            fatalError("no mock for `processWelcomeMessageWelcomeMessage`")
        }
    }

    // MARK: - proteusDecrypt

    public var proteusDecryptSessionIdCiphertext_Invocations: [(sessionId: String, ciphertext: Data)] = []
    public var proteusDecryptSessionIdCiphertext_MockError: Error?
    public var proteusDecryptSessionIdCiphertext_MockMethod: ((String, Data) async throws -> Data)?
    public var proteusDecryptSessionIdCiphertext_MockValue: Data?

    public func proteusDecrypt(sessionId: String, ciphertext: Data) async throws -> Data {
        proteusDecryptSessionIdCiphertext_Invocations.append((sessionId: sessionId, ciphertext: ciphertext))

        if let error = proteusDecryptSessionIdCiphertext_MockError {
            throw error
        }

        if let mock = proteusDecryptSessionIdCiphertext_MockMethod {
            return try await mock(sessionId, ciphertext)
        } else if let mock = proteusDecryptSessionIdCiphertext_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusDecryptSessionIdCiphertext`")
        }
    }

    // MARK: - proteusDecryptSafe

    public var proteusDecryptSafeSessionIdCiphertext_Invocations: [(sessionId: String, ciphertext: Data)] = []
    public var proteusDecryptSafeSessionIdCiphertext_MockError: Error?
    public var proteusDecryptSafeSessionIdCiphertext_MockMethod: ((String, Data) async throws -> Data)?
    public var proteusDecryptSafeSessionIdCiphertext_MockValue: Data?

    public func proteusDecryptSafe(sessionId: String, ciphertext: Data) async throws -> Data {
        proteusDecryptSafeSessionIdCiphertext_Invocations.append((sessionId: sessionId, ciphertext: ciphertext))

        if let error = proteusDecryptSafeSessionIdCiphertext_MockError {
            throw error
        }

        if let mock = proteusDecryptSafeSessionIdCiphertext_MockMethod {
            return try await mock(sessionId, ciphertext)
        } else if let mock = proteusDecryptSafeSessionIdCiphertext_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusDecryptSafeSessionIdCiphertext`")
        }
    }

    // MARK: - proteusEncrypt

    public var proteusEncryptSessionIdPlaintext_Invocations: [(sessionId: String, plaintext: Data)] = []
    public var proteusEncryptSessionIdPlaintext_MockError: Error?
    public var proteusEncryptSessionIdPlaintext_MockMethod: ((String, Data) async throws -> Data)?
    public var proteusEncryptSessionIdPlaintext_MockValue: Data?

    public func proteusEncrypt(sessionId: String, plaintext: Data) async throws -> Data {
        proteusEncryptSessionIdPlaintext_Invocations.append((sessionId: sessionId, plaintext: plaintext))

        if let error = proteusEncryptSessionIdPlaintext_MockError {
            throw error
        }

        if let mock = proteusEncryptSessionIdPlaintext_MockMethod {
            return try await mock(sessionId, plaintext)
        } else if let mock = proteusEncryptSessionIdPlaintext_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusEncryptSessionIdPlaintext`")
        }
    }

    // MARK: - proteusEncryptBatched

    public var proteusEncryptBatchedSessionsPlaintext_Invocations: [(sessions: [String], plaintext: Data)] = []
    public var proteusEncryptBatchedSessionsPlaintext_MockError: Error?
    public var proteusEncryptBatchedSessionsPlaintext_MockMethod: (([String], Data) async throws -> [String: Data])?
    public var proteusEncryptBatchedSessionsPlaintext_MockValue: [String: Data]?

    public func proteusEncryptBatched(sessions: [String], plaintext: Data) async throws -> [String: Data] {
        proteusEncryptBatchedSessionsPlaintext_Invocations.append((sessions: sessions, plaintext: plaintext))

        if let error = proteusEncryptBatchedSessionsPlaintext_MockError {
            throw error
        }

        if let mock = proteusEncryptBatchedSessionsPlaintext_MockMethod {
            return try await mock(sessions, plaintext)
        } else if let mock = proteusEncryptBatchedSessionsPlaintext_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusEncryptBatchedSessionsPlaintext`")
        }
    }

    // MARK: - proteusFingerprint

    public var proteusFingerprint_Invocations: [Void] = []
    public var proteusFingerprint_MockError: Error?
    public var proteusFingerprint_MockMethod: (() async throws -> String)?
    public var proteusFingerprint_MockValue: String?

    public func proteusFingerprint() async throws -> String {
        proteusFingerprint_Invocations.append(())

        if let error = proteusFingerprint_MockError {
            throw error
        }

        if let mock = proteusFingerprint_MockMethod {
            return try await mock()
        } else if let mock = proteusFingerprint_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusFingerprint`")
        }
    }

    // MARK: - proteusFingerprintLocal

    public var proteusFingerprintLocalSessionId_Invocations: [String] = []
    public var proteusFingerprintLocalSessionId_MockError: Error?
    public var proteusFingerprintLocalSessionId_MockMethod: ((String) async throws -> String)?
    public var proteusFingerprintLocalSessionId_MockValue: String?

    public func proteusFingerprintLocal(sessionId: String) async throws -> String {
        proteusFingerprintLocalSessionId_Invocations.append(sessionId)

        if let error = proteusFingerprintLocalSessionId_MockError {
            throw error
        }

        if let mock = proteusFingerprintLocalSessionId_MockMethod {
            return try await mock(sessionId)
        } else if let mock = proteusFingerprintLocalSessionId_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusFingerprintLocalSessionId`")
        }
    }

    // MARK: - proteusFingerprintRemote

    public var proteusFingerprintRemoteSessionId_Invocations: [String] = []
    public var proteusFingerprintRemoteSessionId_MockError: Error?
    public var proteusFingerprintRemoteSessionId_MockMethod: ((String) async throws -> String)?
    public var proteusFingerprintRemoteSessionId_MockValue: String?

    public func proteusFingerprintRemote(sessionId: String) async throws -> String {
        proteusFingerprintRemoteSessionId_Invocations.append(sessionId)

        if let error = proteusFingerprintRemoteSessionId_MockError {
            throw error
        }

        if let mock = proteusFingerprintRemoteSessionId_MockMethod {
            return try await mock(sessionId)
        } else if let mock = proteusFingerprintRemoteSessionId_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusFingerprintRemoteSessionId`")
        }
    }

    // MARK: - proteusInit

    public var proteusInit_Invocations: [Void] = []
    public var proteusInit_MockError: Error?
    public var proteusInit_MockMethod: (() async throws -> Void)?

    public func proteusInit() async throws {
        proteusInit_Invocations.append(())

        if let error = proteusInit_MockError {
            throw error
        }

        guard let mock = proteusInit_MockMethod else {
            fatalError("no mock for `proteusInit`")
        }

        try await mock()
    }

    // MARK: - proteusLastResortPrekey

    public var proteusLastResortPrekey_Invocations: [Void] = []
    public var proteusLastResortPrekey_MockError: Error?
    public var proteusLastResortPrekey_MockMethod: (() async throws -> Data)?
    public var proteusLastResortPrekey_MockValue: Data?

    public func proteusLastResortPrekey() async throws -> Data {
        proteusLastResortPrekey_Invocations.append(())

        if let error = proteusLastResortPrekey_MockError {
            throw error
        }

        if let mock = proteusLastResortPrekey_MockMethod {
            return try await mock()
        } else if let mock = proteusLastResortPrekey_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusLastResortPrekey`")
        }
    }

    // MARK: - proteusNewPrekey

    public var proteusNewPrekeyPrekeyId_Invocations: [UInt16] = []
    public var proteusNewPrekeyPrekeyId_MockError: Error?
    public var proteusNewPrekeyPrekeyId_MockMethod: ((UInt16) async throws -> Data)?
    public var proteusNewPrekeyPrekeyId_MockValue: Data?

    public func proteusNewPrekey(prekeyId: UInt16) async throws -> Data {
        proteusNewPrekeyPrekeyId_Invocations.append(prekeyId)

        if let error = proteusNewPrekeyPrekeyId_MockError {
            throw error
        }

        if let mock = proteusNewPrekeyPrekeyId_MockMethod {
            return try await mock(prekeyId)
        } else if let mock = proteusNewPrekeyPrekeyId_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusNewPrekeyPrekeyId`")
        }
    }

    // MARK: - proteusNewPrekeyAuto

    public var proteusNewPrekeyAuto_Invocations: [Void] = []
    public var proteusNewPrekeyAuto_MockError: Error?
    public var proteusNewPrekeyAuto_MockMethod: (() async throws -> WireCoreCryptoUniffi.ProteusAutoPrekeyBundle)?
    public var proteusNewPrekeyAuto_MockValue: WireCoreCryptoUniffi.ProteusAutoPrekeyBundle?

    public func proteusNewPrekeyAuto() async throws -> WireCoreCryptoUniffi.ProteusAutoPrekeyBundle {
        proteusNewPrekeyAuto_Invocations.append(())

        if let error = proteusNewPrekeyAuto_MockError {
            throw error
        }

        if let mock = proteusNewPrekeyAuto_MockMethod {
            return try await mock()
        } else if let mock = proteusNewPrekeyAuto_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusNewPrekeyAuto`")
        }
    }

    // MARK: - proteusSessionDelete

    public var proteusSessionDeleteSessionId_Invocations: [String] = []
    public var proteusSessionDeleteSessionId_MockError: Error?
    public var proteusSessionDeleteSessionId_MockMethod: ((String) async throws -> Void)?

    public func proteusSessionDelete(sessionId: String) async throws {
        proteusSessionDeleteSessionId_Invocations.append(sessionId)

        if let error = proteusSessionDeleteSessionId_MockError {
            throw error
        }

        guard let mock = proteusSessionDeleteSessionId_MockMethod else {
            fatalError("no mock for `proteusSessionDeleteSessionId`")
        }

        try await mock(sessionId)
    }

    // MARK: - proteusSessionExists

    public var proteusSessionExistsSessionId_Invocations: [String] = []
    public var proteusSessionExistsSessionId_MockError: Error?
    public var proteusSessionExistsSessionId_MockMethod: ((String) async throws -> Bool)?
    public var proteusSessionExistsSessionId_MockValue: Bool?

    public func proteusSessionExists(sessionId: String) async throws -> Bool {
        proteusSessionExistsSessionId_Invocations.append(sessionId)

        if let error = proteusSessionExistsSessionId_MockError {
            throw error
        }

        if let mock = proteusSessionExistsSessionId_MockMethod {
            return try await mock(sessionId)
        } else if let mock = proteusSessionExistsSessionId_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusSessionExistsSessionId`")
        }
    }

    // MARK: - proteusSessionFromMessage

    public var proteusSessionFromMessageSessionIdEnvelope_Invocations: [(sessionId: String, envelope: Data)] = []
    public var proteusSessionFromMessageSessionIdEnvelope_MockError: Error?
    public var proteusSessionFromMessageSessionIdEnvelope_MockMethod: ((String, Data) async throws -> Data)?
    public var proteusSessionFromMessageSessionIdEnvelope_MockValue: Data?

    public func proteusSessionFromMessage(sessionId: String, envelope: Data) async throws -> Data {
        proteusSessionFromMessageSessionIdEnvelope_Invocations.append((sessionId: sessionId, envelope: envelope))

        if let error = proteusSessionFromMessageSessionIdEnvelope_MockError {
            throw error
        }

        if let mock = proteusSessionFromMessageSessionIdEnvelope_MockMethod {
            return try await mock(sessionId, envelope)
        } else if let mock = proteusSessionFromMessageSessionIdEnvelope_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusSessionFromMessageSessionIdEnvelope`")
        }
    }

    // MARK: - proteusSessionFromPrekey

    public var proteusSessionFromPrekeySessionIdPrekey_Invocations: [(sessionId: String, prekey: Data)] = []
    public var proteusSessionFromPrekeySessionIdPrekey_MockError: Error?
    public var proteusSessionFromPrekeySessionIdPrekey_MockMethod: ((String, Data) async throws -> Void)?

    public func proteusSessionFromPrekey(sessionId: String, prekey: Data) async throws {
        proteusSessionFromPrekeySessionIdPrekey_Invocations.append((sessionId: sessionId, prekey: prekey))

        if let error = proteusSessionFromPrekeySessionIdPrekey_MockError {
            throw error
        }

        guard let mock = proteusSessionFromPrekeySessionIdPrekey_MockMethod else {
            fatalError("no mock for `proteusSessionFromPrekeySessionIdPrekey`")
        }

        try await mock(sessionId, prekey)
    }

    // MARK: - proteusSessionSave

    public var proteusSessionSaveSessionId_Invocations: [String] = []
    public var proteusSessionSaveSessionId_MockError: Error?
    public var proteusSessionSaveSessionId_MockMethod: ((String) async throws -> Void)?

    public func proteusSessionSave(sessionId: String) async throws {
        proteusSessionSaveSessionId_Invocations.append(sessionId)

        if let error = proteusSessionSaveSessionId_MockError {
            throw error
        }

        guard let mock = proteusSessionSaveSessionId_MockMethod else {
            fatalError("no mock for `proteusSessionSaveSessionId`")
        }

        try await mock(sessionId)
    }

    // MARK: - randomBytes

    public var randomBytesLen_Invocations: [UInt32] = []
    public var randomBytesLen_MockError: Error?
    public var randomBytesLen_MockMethod: ((UInt32) async throws -> Data)?
    public var randomBytesLen_MockValue: Data?

    public func randomBytes(len: UInt32) async throws -> Data {
        randomBytesLen_Invocations.append(len)

        if let error = randomBytesLen_MockError {
            throw error
        }

        if let mock = randomBytesLen_MockMethod {
            return try await mock(len)
        } else if let mock = randomBytesLen_MockValue {
            return mock
        } else {
            fatalError("no mock for `randomBytesLen`")
        }
    }

    // MARK: - removeClientsFromConversation

    public var removeClientsFromConversationConversationIdClients_Invocations: [(conversationId: WireCoreCryptoUniffi.ConversationId, clients: [WireCoreCryptoUniffi.ClientId])] = []
    public var removeClientsFromConversationConversationIdClients_MockError: Error?
    public var removeClientsFromConversationConversationIdClients_MockMethod: ((WireCoreCryptoUniffi.ConversationId, [WireCoreCryptoUniffi.ClientId]) async throws -> Void)?

    public func removeClientsFromConversation(conversationId: WireCoreCryptoUniffi.ConversationId, clients: [WireCoreCryptoUniffi.ClientId]) async throws {
        removeClientsFromConversationConversationIdClients_Invocations.append((conversationId: conversationId, clients: clients))

        if let error = removeClientsFromConversationConversationIdClients_MockError {
            throw error
        }

        guard let mock = removeClientsFromConversationConversationIdClients_MockMethod else {
            fatalError("no mock for `removeClientsFromConversationConversationIdClients`")
        }

        try await mock(conversationId, clients)
    }

    // MARK: - removeCredential

    public var removeCredentialCredentialRef_Invocations: [WireCoreCryptoUniffi.CredentialRef] = []
    public var removeCredentialCredentialRef_MockError: Error?
    public var removeCredentialCredentialRef_MockMethod: ((WireCoreCryptoUniffi.CredentialRef) async throws -> Void)?

    public func removeCredential(credentialRef: WireCoreCryptoUniffi.CredentialRef) async throws {
        removeCredentialCredentialRef_Invocations.append(credentialRef)

        if let error = removeCredentialCredentialRef_MockError {
            throw error
        }

        guard let mock = removeCredentialCredentialRef_MockMethod else {
            fatalError("no mock for `removeCredentialCredentialRef`")
        }

        try await mock(credentialRef)
    }

    // MARK: - removeKeyPackage

    public var removeKeyPackageKpRef_Invocations: [WireCoreCryptoUniffi.KeyPackageRef] = []
    public var removeKeyPackageKpRef_MockError: Error?
    public var removeKeyPackageKpRef_MockMethod: ((WireCoreCryptoUniffi.KeyPackageRef) async throws -> Void)?

    public func removeKeyPackage(kpRef: WireCoreCryptoUniffi.KeyPackageRef) async throws {
        removeKeyPackageKpRef_Invocations.append(kpRef)

        if let error = removeKeyPackageKpRef_MockError {
            throw error
        }

        guard let mock = removeKeyPackageKpRef_MockMethod else {
            fatalError("no mock for `removeKeyPackageKpRef`")
        }

        try await mock(kpRef)
    }

    // MARK: - removeKeyPackagesFor

    public var removeKeyPackagesForCredentialRef_Invocations: [WireCoreCryptoUniffi.CredentialRef] = []
    public var removeKeyPackagesForCredentialRef_MockError: Error?
    public var removeKeyPackagesForCredentialRef_MockMethod: ((WireCoreCryptoUniffi.CredentialRef) async throws -> Void)?

    public func removeKeyPackagesFor(credentialRef: WireCoreCryptoUniffi.CredentialRef) async throws {
        removeKeyPackagesForCredentialRef_Invocations.append(credentialRef)

        if let error = removeKeyPackagesForCredentialRef_MockError {
            throw error
        }

        guard let mock = removeKeyPackagesForCredentialRef_MockMethod else {
            fatalError("no mock for `removeKeyPackagesForCredentialRef`")
        }

        try await mock(credentialRef)
    }

    // MARK: - setConversationCredential

    public var setConversationCredentialConversationIdCredentialRef_Invocations: [(conversationId: WireCoreCryptoUniffi.ConversationId, credentialRef: WireCoreCryptoUniffi.CredentialRef)] = []
    public var setConversationCredentialConversationIdCredentialRef_MockError: Error?
    public var setConversationCredentialConversationIdCredentialRef_MockMethod: ((WireCoreCryptoUniffi.ConversationId, WireCoreCryptoUniffi.CredentialRef) async throws -> Void)?

    public func setConversationCredential(conversationId: WireCoreCryptoUniffi.ConversationId, credentialRef: WireCoreCryptoUniffi.CredentialRef) async throws {
        setConversationCredentialConversationIdCredentialRef_Invocations.append((conversationId: conversationId, credentialRef: credentialRef))

        if let error = setConversationCredentialConversationIdCredentialRef_MockError {
            throw error
        }

        guard let mock = setConversationCredentialConversationIdCredentialRef_MockMethod else {
            fatalError("no mock for `setConversationCredentialConversationIdCredentialRef`")
        }

        try await mock(conversationId, credentialRef)
    }

    // MARK: - setData

    public var setDataData_Invocations: [Data] = []
    public var setDataData_MockError: Error?
    public var setDataData_MockMethod: ((Data) async throws -> Void)?

    public func setData(data: Data) async throws {
        setDataData_Invocations.append(data)

        if let error = setDataData_MockError {
            throw error
        }

        guard let mock = setDataData_MockMethod else {
            fatalError("no mock for `setDataData`")
        }

        try await mock(data)
    }

    // MARK: - updateKeyingMaterial

    public var updateKeyingMaterialConversationId_Invocations: [WireCoreCryptoUniffi.ConversationId] = []
    public var updateKeyingMaterialConversationId_MockError: Error?
    public var updateKeyingMaterialConversationId_MockMethod: ((WireCoreCryptoUniffi.ConversationId) async throws -> Void)?

    public func updateKeyingMaterial(conversationId: WireCoreCryptoUniffi.ConversationId) async throws {
        updateKeyingMaterialConversationId_Invocations.append(conversationId)

        if let error = updateKeyingMaterialConversationId_MockError {
            throw error
        }

        guard let mock = updateKeyingMaterialConversationId_MockMethod else {
            fatalError("no mock for `updateKeyingMaterialConversationId`")
        }

        try await mock(conversationId)
    }

    // MARK: - wipeConversation

    public var wipeConversationConversationId_Invocations: [WireCoreCryptoUniffi.ConversationId] = []
    public var wipeConversationConversationId_MockError: Error?
    public var wipeConversationConversationId_MockMethod: ((WireCoreCryptoUniffi.ConversationId) async throws -> Void)?

    public func wipeConversation(conversationId: WireCoreCryptoUniffi.ConversationId) async throws {
        wipeConversationConversationId_Invocations.append(conversationId)

        if let error = wipeConversationConversationId_MockError {
            throw error
        }

        guard let mock = wipeConversationConversationId_MockMethod else {
            fatalError("no mock for `wipeConversationConversationId`")
        }

        try await mock(conversationId)
    }

}

public class MockCoreCryptoKeyMigrationManagerProtocol: CoreCryptoKeyMigrationManagerProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - isAnyMigrationRequired

    public var isAnyMigrationRequired: Bool {
        get { return underlyingIsAnyMigrationRequired }
        set(value) { underlyingIsAnyMigrationRequired = value }
    }

    public var underlyingIsAnyMigrationRequired: Bool!

    // MARK: - isMigrationToBytesNeeded

    public var isMigrationToBytesNeeded: Bool {
        get { return underlyingIsMigrationToBytesNeeded }
        set(value) { underlyingIsMigrationToBytesNeeded = value }
    }

    public var underlyingIsMigrationToBytesNeeded: Bool!

    // MARK: - isMigrationToScopedKeyNeeded

    public var isMigrationToScopedKeyNeeded: Bool {
        get { return underlyingIsMigrationToScopedKeyNeeded }
        set(value) { underlyingIsMigrationToScopedKeyNeeded = value }
    }

    public var underlyingIsMigrationToScopedKeyNeeded: Bool!

    // MARK: - isKeyRotationNeeded

    public var isKeyRotationNeeded: Bool {
        get { return underlyingIsKeyRotationNeeded }
        set(value) { underlyingIsKeyRotationNeeded = value }
    }

    public var underlyingIsKeyRotationNeeded: Bool!


    // MARK: - migrateDatabaseKeyToBytes

    public var migrateDatabaseKeyToBytesPathOldKeyNewKey_Invocations: [(path: String, oldKey: String, newKey: Data)] = []
    public var migrateDatabaseKeyToBytesPathOldKeyNewKey_MockError: Error?
    public var migrateDatabaseKeyToBytesPathOldKeyNewKey_MockMethod: ((String, String, Data) async throws -> Void)?

    public func migrateDatabaseKeyToBytes(path: String, oldKey: String, newKey: Data) async throws {
        migrateDatabaseKeyToBytesPathOldKeyNewKey_Invocations.append((path: path, oldKey: oldKey, newKey: newKey))

        if let error = migrateDatabaseKeyToBytesPathOldKeyNewKey_MockError {
            throw error
        }

        guard let mock = migrateDatabaseKeyToBytesPathOldKeyNewKey_MockMethod else {
            fatalError("no mock for `migrateDatabaseKeyToBytesPathOldKeyNewKey`")
        }

        try await mock(path, oldKey, newKey)
    }

    // MARK: - markMigrationToBytesAsSkipped

    public var markMigrationToBytesAsSkipped_Invocations: [Void] = []
    public var markMigrationToBytesAsSkipped_MockMethod: (() -> Void)?

    public func markMigrationToBytesAsSkipped() {
        markMigrationToBytesAsSkipped_Invocations.append(())

        guard let mock = markMigrationToBytesAsSkipped_MockMethod else {
            fatalError("no mock for `markMigrationToBytesAsSkipped`")
        }

        mock()
    }

    // MARK: - markMigrationToScopedKeyDone

    public var markMigrationToScopedKeyDone_Invocations: [Void] = []
    public var markMigrationToScopedKeyDone_MockMethod: (() -> Void)?

    public func markMigrationToScopedKeyDone() {
        markMigrationToScopedKeyDone_Invocations.append(())

        guard let mock = markMigrationToScopedKeyDone_MockMethod else {
            fatalError("no mock for `markMigrationToScopedKeyDone`")
        }

        mock()
    }

    // MARK: - markKeyRotationAsDone

    public var markKeyRotationAsDone_Invocations: [Void] = []
    public var markKeyRotationAsDone_MockMethod: (() -> Void)?

    public func markKeyRotationAsDone() {
        markKeyRotationAsDone_Invocations.append(())

        guard let mock = markKeyRotationAsDone_MockMethod else {
            fatalError("no mock for `markKeyRotationAsDone`")
        }

        mock()
    }

    // MARK: - updateKey

    public var updateKeyPathOldKeyNewKey_Invocations: [(path: String, oldKey: Data, newKey: Data)] = []
    public var updateKeyPathOldKeyNewKey_MockError: Error?
    public var updateKeyPathOldKeyNewKey_MockMethod: ((String, Data, Data) async throws -> Void)?

    public func updateKey(path: String, oldKey: Data, newKey: Data) async throws {
        updateKeyPathOldKeyNewKey_Invocations.append((path: path, oldKey: oldKey, newKey: newKey))

        if let error = updateKeyPathOldKeyNewKey_MockError {
            throw error
        }

        guard let mock = updateKeyPathOldKeyNewKey_MockMethod else {
            fatalError("no mock for `updateKeyPathOldKeyNewKey`")
        }

        try await mock(path, oldKey, newKey)
    }

}

public class MockCoreCryptoProviderProtocol: CoreCryptoProviderProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - coreCrypto

    public var coreCrypto_Invocations: [Void] = []
    public var coreCrypto_MockError: Error?
    public var coreCrypto_MockMethod: (() async throws -> SafeCoreCrypto)?
    public var coreCrypto_MockValue: SafeCoreCrypto?

    public func coreCrypto() async throws -> SafeCoreCrypto {
        coreCrypto_Invocations.append(())

        if let error = coreCrypto_MockError {
            throw error
        }

        if let mock = coreCrypto_MockMethod {
            return try await mock()
        } else if let mock = coreCrypto_MockValue {
            return mock
        } else {
            fatalError("no mock for `coreCrypto`")
        }
    }

    // MARK: - pkiEnvironment

    public var pkiEnvironment_Invocations: [Void] = []
    public var pkiEnvironment_MockMethod: (() async -> PkiEnvironment?)?
    public var pkiEnvironment_MockValue: PkiEnvironment??

    public func pkiEnvironment() async -> PkiEnvironment? {
        pkiEnvironment_Invocations.append(())

        if let mock = pkiEnvironment_MockMethod {
            return await mock()
        } else if let mock = pkiEnvironment_MockValue {
            return mock
        } else {
            fatalError("no mock for `pkiEnvironment`")
        }
    }

    // MARK: - initialiseMLSWithBasicCredentials

    public var initialiseMLSWithBasicCredentialsMlsClientID_Invocations: [MLSClientID] = []
    public var initialiseMLSWithBasicCredentialsMlsClientID_MockError: Error?
    public var initialiseMLSWithBasicCredentialsMlsClientID_MockMethod: ((MLSClientID) async throws -> Void)?

    public func initialiseMLSWithBasicCredentials(mlsClientID: MLSClientID) async throws {
        initialiseMLSWithBasicCredentialsMlsClientID_Invocations.append(mlsClientID)

        if let error = initialiseMLSWithBasicCredentialsMlsClientID_MockError {
            throw error
        }

        guard let mock = initialiseMLSWithBasicCredentialsMlsClientID_MockMethod else {
            fatalError("no mock for `initialiseMLSWithBasicCredentialsMlsClientID`")
        }

        try await mock(mlsClientID)
    }

    // MARK: - initialiseMLSWithEndToEndIdentity

    public var initialiseMLSWithEndToEndIdentityMlsClientIDCredential_Invocations: [(mlsClientID: MLSClientID, credential: Credential)] = []
    public var initialiseMLSWithEndToEndIdentityMlsClientIDCredential_MockError: Error?
    public var initialiseMLSWithEndToEndIdentityMlsClientIDCredential_MockMethod: ((MLSClientID, Credential) async throws -> CredentialRef)?
    public var initialiseMLSWithEndToEndIdentityMlsClientIDCredential_MockValue: CredentialRef?

    @discardableResult
    public func initialiseMLSWithEndToEndIdentity(mlsClientID: MLSClientID, credential: Credential) async throws -> CredentialRef {
        initialiseMLSWithEndToEndIdentityMlsClientIDCredential_Invocations.append((mlsClientID: mlsClientID, credential: credential))

        if let error = initialiseMLSWithEndToEndIdentityMlsClientIDCredential_MockError {
            throw error
        }

        if let mock = initialiseMLSWithEndToEndIdentityMlsClientIDCredential_MockMethod {
            return try await mock(mlsClientID, credential)
        } else if let mock = initialiseMLSWithEndToEndIdentityMlsClientIDCredential_MockValue {
            return mock
        } else {
            fatalError("no mock for `initialiseMLSWithEndToEndIdentityMlsClientIDCredential`")
        }
    }

    // MARK: - registerMlsTransport

    public var registerMlsTransport_Invocations: [any MlsTransport] = []
    public var registerMlsTransport_MockMethod: ((any MlsTransport) -> Void)?

    public func registerMlsTransport(_ transport: any MlsTransport) {
        registerMlsTransport_Invocations.append(transport)

        guard let mock = registerMlsTransport_MockMethod else {
            fatalError("no mock for `registerMlsTransport`")
        }

        mock(transport)
    }

    // MARK: - registerPkiEnvironmentHooks

    public var registerPkiEnvironmentHooks_Invocations: [any PkiEnvironmentHooks] = []
    public var registerPkiEnvironmentHooks_MockMethod: ((any PkiEnvironmentHooks) -> Void)?

    public func registerPkiEnvironmentHooks(_ hooks: any PkiEnvironmentHooks) {
        registerPkiEnvironmentHooks_Invocations.append(hooks)

        guard let mock = registerPkiEnvironmentHooks_MockMethod else {
            fatalError("no mock for `registerPkiEnvironmentHooks`")
        }

        mock(hooks)
    }

    // MARK: - registerEpochObserver

    public var registerEpochObserver_Invocations: [any WireCoreCryptoUniffi.EpochObserver] = []
    public var registerEpochObserver_MockMethod: ((any WireCoreCryptoUniffi.EpochObserver) async -> Void)?

    public func registerEpochObserver(_ epochObserver: any WireCoreCryptoUniffi.EpochObserver) async {
        registerEpochObserver_Invocations.append(epochObserver)

        guard let mock = registerEpochObserver_MockMethod else {
            fatalError("no mock for `registerEpochObserver`")
        }

        await mock(epochObserver)
    }

}

class MockCoreDataMessagingMigratorProtocol: CoreDataMessagingMigratorProtocol {

    // MARK: - Life cycle



    // MARK: - requiresMigration

    var requiresMigrationAtToVersion_Invocations: [(storeURL: URL, version: CoreDataMessagingMigrationVersion)] = []
    var requiresMigrationAtToVersion_MockMethod: ((URL, CoreDataMessagingMigrationVersion) -> Bool)?
    var requiresMigrationAtToVersion_MockValue: Bool?

    func requiresMigration(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion) -> Bool {
        requiresMigrationAtToVersion_Invocations.append((storeURL: storeURL, version: version))

        if let mock = requiresMigrationAtToVersion_MockMethod {
            return mock(storeURL, version)
        } else if let mock = requiresMigrationAtToVersion_MockValue {
            return mock
        } else {
            fatalError("no mock for `requiresMigrationAtToVersion`")
        }
    }

    // MARK: - migrateStore

    var migrateStoreAtToVersion_Invocations: [(storeURL: URL, version: CoreDataMessagingMigrationVersion)] = []
    var migrateStoreAtToVersion_MockError: Error?
    var migrateStoreAtToVersion_MockMethod: ((URL, CoreDataMessagingMigrationVersion) throws -> Void)?

    func migrateStore(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion) throws {
        migrateStoreAtToVersion_Invocations.append((storeURL: storeURL, version: version))

        if let error = migrateStoreAtToVersion_MockError {
            throw error
        }

        guard let mock = migrateStoreAtToVersion_MockMethod else {
            fatalError("no mock for `migrateStoreAtToVersion`")
        }

        try mock(storeURL, version)
    }

}

public class MockCoreDataStackProtocol: CoreDataStackProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - storesExists

    public var storesExists: Bool {
        get { return underlyingStoresExists }
        set(value) { underlyingStoresExists = value }
    }

    public var underlyingStoresExists: Bool!

    // MARK: - needsMigration

    public var needsMigration: Bool {
        get { return underlyingNeedsMigration }
        set(value) { underlyingNeedsMigration = value }
    }

    public var underlyingNeedsMigration: Bool!

    // MARK: - account

    public var account: Account {
        get { return underlyingAccount }
        set(value) { underlyingAccount = value }
    }

    public var underlyingAccount: Account!

    // MARK: - viewContext

    public var viewContext: NSManagedObjectContext {
        get { return underlyingViewContext }
        set(value) { underlyingViewContext = value }
    }

    public var underlyingViewContext: NSManagedObjectContext!

    // MARK: - syncContext

    public var syncContext: NSManagedObjectContext {
        get { return underlyingSyncContext }
        set(value) { underlyingSyncContext = value }
    }

    public var underlyingSyncContext: NSManagedObjectContext!

    // MARK: - eventContext

    public var eventContext: NSManagedObjectContext {
        get { return underlyingEventContext }
        set(value) { underlyingEventContext = value }
    }

    public var underlyingEventContext: NSManagedObjectContext!


    // MARK: - load

    public var load_Invocations: [Void] = []
    public var load_MockError: Error?
    public var load_MockMethod: (() async throws -> Void)?

    public func load() async throws {
        load_Invocations.append(())

        if let error = load_MockError {
            throw error
        }

        guard let mock = load_MockMethod else {
            fatalError("no mock for `load`")
        }

        try await mock()
    }

    // MARK: - setEARMessageEncryptionService

    public var setEARMessageEncryptionService_Invocations: [EARMessageEncryptionServiceProtocol] = []
    public var setEARMessageEncryptionService_MockMethod: ((EARMessageEncryptionServiceProtocol) -> Void)?

    public func setEARMessageEncryptionService(_ service: EARMessageEncryptionServiceProtocol) {
        setEARMessageEncryptionService_Invocations.append(service)

        guard let mock = setEARMessageEncryptionService_MockMethod else {
            fatalError("no mock for `setEARMessageEncryptionService`")
        }

        mock(service)
    }

    // MARK: - newBackgroundContext

    public var newBackgroundContext_Invocations: [Void] = []
    public var newBackgroundContext_MockMethod: (() -> NSManagedObjectContext)?
    public var newBackgroundContext_MockValue: NSManagedObjectContext?

    public func newBackgroundContext() -> NSManagedObjectContext {
        newBackgroundContext_Invocations.append(())

        if let mock = newBackgroundContext_MockMethod {
            return mock()
        } else if let mock = newBackgroundContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `newBackgroundContext`")
        }
    }

}

public class MockE2EIVerificationStatusServiceInterface: E2EIVerificationStatusServiceInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - getConversationStatus

    public var getConversationStatusGroupID_Invocations: [MLSGroupID] = []
    public var getConversationStatusGroupID_MockError: Error?
    public var getConversationStatusGroupID_MockMethod: ((MLSGroupID) async throws -> MLSVerificationStatus)?
    public var getConversationStatusGroupID_MockValue: MLSVerificationStatus?

    public func getConversationStatus(groupID: MLSGroupID) async throws -> MLSVerificationStatus {
        getConversationStatusGroupID_Invocations.append(groupID)

        if let error = getConversationStatusGroupID_MockError {
            throw error
        }

        if let mock = getConversationStatusGroupID_MockMethod {
            return try await mock(groupID)
        } else if let mock = getConversationStatusGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `getConversationStatusGroupID`")
        }
    }

}

class MockEARKeyEncryptorInterface: EARKeyEncryptorInterface {

    // MARK: - Life cycle



    // MARK: - encryptDatabaseKey

    var encryptDatabaseKeyPublicKey_Invocations: [(databaseKey: Data, publicKey: SecKey)] = []
    var encryptDatabaseKeyPublicKey_MockError: Error?
    var encryptDatabaseKeyPublicKey_MockMethod: ((Data, SecKey) throws -> Data)?
    var encryptDatabaseKeyPublicKey_MockValue: Data?

    func encryptDatabaseKey(_ databaseKey: Data, publicKey: SecKey) throws -> Data {
        encryptDatabaseKeyPublicKey_Invocations.append((databaseKey: databaseKey, publicKey: publicKey))

        if let error = encryptDatabaseKeyPublicKey_MockError {
            throw error
        }

        if let mock = encryptDatabaseKeyPublicKey_MockMethod {
            return try mock(databaseKey, publicKey)
        } else if let mock = encryptDatabaseKeyPublicKey_MockValue {
            return mock
        } else {
            fatalError("no mock for `encryptDatabaseKeyPublicKey`")
        }
    }

    // MARK: - decryptDatabaseKey

    var decryptDatabaseKeyPrivateKey_Invocations: [(encryptedDatabaseKey: Data, privateKey: SecKey)] = []
    var decryptDatabaseKeyPrivateKey_MockError: Error?
    var decryptDatabaseKeyPrivateKey_MockMethod: ((Data, SecKey) throws -> Data)?
    var decryptDatabaseKeyPrivateKey_MockValue: Data?

    func decryptDatabaseKey(_ encryptedDatabaseKey: Data, privateKey: SecKey) throws -> Data {
        decryptDatabaseKeyPrivateKey_Invocations.append((encryptedDatabaseKey: encryptedDatabaseKey, privateKey: privateKey))

        if let error = decryptDatabaseKeyPrivateKey_MockError {
            throw error
        }

        if let mock = decryptDatabaseKeyPrivateKey_MockMethod {
            return try mock(encryptedDatabaseKey, privateKey)
        } else if let mock = decryptDatabaseKeyPrivateKey_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptDatabaseKeyPrivateKey`")
        }
    }

}

class MockEARKeyRepositoryInterface: EARKeyRepositoryInterface {

    // MARK: - Life cycle



    // MARK: - storePublicKey

    var storePublicKeyDescriptionKey_Invocations: [(description: PublicEARKeyDescription, key: SecKey)] = []
    var storePublicKeyDescriptionKey_MockError: Error?
    var storePublicKeyDescriptionKey_MockMethod: ((PublicEARKeyDescription, SecKey) throws -> Void)?

    func storePublicKey(description: PublicEARKeyDescription, key: SecKey) throws {
        storePublicKeyDescriptionKey_Invocations.append((description: description, key: key))

        if let error = storePublicKeyDescriptionKey_MockError {
            throw error
        }

        guard let mock = storePublicKeyDescriptionKey_MockMethod else {
            fatalError("no mock for `storePublicKeyDescriptionKey`")
        }

        try mock(description, key)
    }

    // MARK: - fetchPublicKey

    var fetchPublicKeyDescription_Invocations: [PublicEARKeyDescription] = []
    var fetchPublicKeyDescription_MockError: Error?
    var fetchPublicKeyDescription_MockMethod: ((PublicEARKeyDescription) throws -> SecKey)?
    var fetchPublicKeyDescription_MockValue: SecKey?

    func fetchPublicKey(description: PublicEARKeyDescription) throws -> SecKey {
        fetchPublicKeyDescription_Invocations.append(description)

        if let error = fetchPublicKeyDescription_MockError {
            throw error
        }

        if let mock = fetchPublicKeyDescription_MockMethod {
            return try mock(description)
        } else if let mock = fetchPublicKeyDescription_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchPublicKeyDescription`")
        }
    }

    // MARK: - deletePublicKey

    var deletePublicKeyDescription_Invocations: [PublicEARKeyDescription] = []
    var deletePublicKeyDescription_MockError: Error?
    var deletePublicKeyDescription_MockMethod: ((PublicEARKeyDescription) throws -> Void)?

    func deletePublicKey(description: PublicEARKeyDescription) throws {
        deletePublicKeyDescription_Invocations.append(description)

        if let error = deletePublicKeyDescription_MockError {
            throw error
        }

        guard let mock = deletePublicKeyDescription_MockMethod else {
            fatalError("no mock for `deletePublicKeyDescription`")
        }

        try mock(description)
    }

    // MARK: - fetchPrivateKey

    var fetchPrivateKeyDescription_Invocations: [PrivateEARKeyDescription] = []
    var fetchPrivateKeyDescription_MockError: Error?
    var fetchPrivateKeyDescription_MockMethod: ((PrivateEARKeyDescription) throws -> SecKey)?
    var fetchPrivateKeyDescription_MockValue: SecKey?

    func fetchPrivateKey(description: PrivateEARKeyDescription) throws -> SecKey {
        fetchPrivateKeyDescription_Invocations.append(description)

        if let error = fetchPrivateKeyDescription_MockError {
            throw error
        }

        if let mock = fetchPrivateKeyDescription_MockMethod {
            return try mock(description)
        } else if let mock = fetchPrivateKeyDescription_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchPrivateKeyDescription`")
        }
    }

    // MARK: - deletePrivateKey

    var deletePrivateKeyDescription_Invocations: [PrivateEARKeyDescription] = []
    var deletePrivateKeyDescription_MockError: Error?
    var deletePrivateKeyDescription_MockMethod: ((PrivateEARKeyDescription) throws -> Void)?

    func deletePrivateKey(description: PrivateEARKeyDescription) throws {
        deletePrivateKeyDescription_Invocations.append(description)

        if let error = deletePrivateKeyDescription_MockError {
            throw error
        }

        guard let mock = deletePrivateKeyDescription_MockMethod else {
            fatalError("no mock for `deletePrivateKeyDescription`")
        }

        try mock(description)
    }

    // MARK: - storeDatabaseKey

    var storeDatabaseKeyDescriptionKey_Invocations: [(description: DatabaseEARKeyDescription, key: Data)] = []
    var storeDatabaseKeyDescriptionKey_MockError: Error?
    var storeDatabaseKeyDescriptionKey_MockMethod: ((DatabaseEARKeyDescription, Data) throws -> Void)?

    func storeDatabaseKey(description: DatabaseEARKeyDescription, key: Data) throws {
        storeDatabaseKeyDescriptionKey_Invocations.append((description: description, key: key))

        if let error = storeDatabaseKeyDescriptionKey_MockError {
            throw error
        }

        guard let mock = storeDatabaseKeyDescriptionKey_MockMethod else {
            fatalError("no mock for `storeDatabaseKeyDescriptionKey`")
        }

        try mock(description, key)
    }

    // MARK: - fetchDatabaseKey

    var fetchDatabaseKeyDescription_Invocations: [DatabaseEARKeyDescription] = []
    var fetchDatabaseKeyDescription_MockError: Error?
    var fetchDatabaseKeyDescription_MockMethod: ((DatabaseEARKeyDescription) throws -> Data)?
    var fetchDatabaseKeyDescription_MockValue: Data?

    func fetchDatabaseKey(description: DatabaseEARKeyDescription) throws -> Data {
        fetchDatabaseKeyDescription_Invocations.append(description)

        if let error = fetchDatabaseKeyDescription_MockError {
            throw error
        }

        if let mock = fetchDatabaseKeyDescription_MockMethod {
            return try mock(description)
        } else if let mock = fetchDatabaseKeyDescription_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchDatabaseKeyDescription`")
        }
    }

    // MARK: - deleteDatabaseKey

    var deleteDatabaseKeyDescription_Invocations: [DatabaseEARKeyDescription] = []
    var deleteDatabaseKeyDescription_MockError: Error?
    var deleteDatabaseKeyDescription_MockMethod: ((DatabaseEARKeyDescription) throws -> Void)?

    func deleteDatabaseKey(description: DatabaseEARKeyDescription) throws {
        deleteDatabaseKeyDescription_Invocations.append(description)

        if let error = deleteDatabaseKeyDescription_MockError {
            throw error
        }

        guard let mock = deleteDatabaseKeyDescription_MockMethod else {
            fatalError("no mock for `deleteDatabaseKeyDescription`")
        }

        try mock(description)
    }

    // MARK: - clearCache

    var clearCache_Invocations: [Void] = []
    var clearCache_MockMethod: (() -> Void)?

    func clearCache() {
        clearCache_Invocations.append(())

        guard let mock = clearCache_MockMethod else {
            fatalError("no mock for `clearCache`")
        }

        mock()
    }

}

public class MockEARMessageEncryptionServiceProtocol: EARMessageEncryptionServiceProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - isLocked

    public var isLocked: Bool {
        get { return underlyingIsLocked }
        set(value) { underlyingIsLocked = value }
    }

    public var underlyingIsLocked: Bool!


    // MARK: - setDatabaseKey

    public var setDatabaseKey_Invocations: [VolatileData?] = []
    public var setDatabaseKey_MockMethod: ((VolatileData?) -> Void)?

    public func setDatabaseKey(_ key: VolatileData?) {
        setDatabaseKey_Invocations.append(key)

        guard let mock = setDatabaseKey_MockMethod else {
            fatalError("no mock for `setDatabaseKey`")
        }

        mock(key)
    }

    // MARK: - getDatabaseKey

    public var getDatabaseKey_Invocations: [Void] = []
    public var getDatabaseKey_MockMethod: (() -> VolatileData?)?
    public var getDatabaseKey_MockValue: VolatileData??

    public func getDatabaseKey() -> VolatileData? {
        getDatabaseKey_Invocations.append(())

        if let mock = getDatabaseKey_MockMethod {
            return mock()
        } else if let mock = getDatabaseKey_MockValue {
            return mock
        } else {
            fatalError("no mock for `getDatabaseKey`")
        }
    }

    // MARK: - getContextData

    public var getContextDataFrom_Invocations: [NSManagedObjectContext] = []
    public var getContextDataFrom_MockError: Error?
    public var getContextDataFrom_MockMethod: ((NSManagedObjectContext) throws -> Data)?
    public var getContextDataFrom_MockValue: Data?

    public func getContextData(from context: NSManagedObjectContext) throws -> Data {
        getContextDataFrom_Invocations.append(context)

        if let error = getContextDataFrom_MockError {
            throw error
        }

        if let mock = getContextDataFrom_MockMethod {
            return try mock(context)
        } else if let mock = getContextDataFrom_MockValue {
            return mock
        } else {
            fatalError("no mock for `getContextDataFrom`")
        }
    }

    // MARK: - encrypt

    public var encryptDataContextData_Invocations: [(data: Data, contextData: Data)] = []
    public var encryptDataContextData_MockError: Error?
    public var encryptDataContextData_MockMethod: ((Data, Data) throws -> (data: Data, nonce: Data))?
    public var encryptDataContextData_MockValue: (data: Data, nonce: Data)?

    public func encrypt(data: Data, contextData: Data) throws -> (data: Data, nonce: Data) {
        encryptDataContextData_Invocations.append((data: data, contextData: contextData))

        if let error = encryptDataContextData_MockError {
            throw error
        }

        if let mock = encryptDataContextData_MockMethod {
            return try mock(data, contextData)
        } else if let mock = encryptDataContextData_MockValue {
            return mock
        } else {
            fatalError("no mock for `encryptDataContextData`")
        }
    }

    // MARK: - decrypt

    public var decryptDataNonceContextData_Invocations: [(data: Data, nonce: Data, contextData: Data)] = []
    public var decryptDataNonceContextData_MockError: Error?
    public var decryptDataNonceContextData_MockMethod: ((Data, Data, Data) throws -> Data)?
    public var decryptDataNonceContextData_MockValue: Data?

    public func decrypt(data: Data, nonce: Data, contextData: Data) throws -> Data {
        decryptDataNonceContextData_Invocations.append((data: data, nonce: nonce, contextData: contextData))

        if let error = decryptDataNonceContextData_MockError {
            throw error
        }

        if let mock = decryptDataNonceContextData_MockMethod {
            return try mock(data, nonce, contextData)
        } else if let mock = decryptDataNonceContextData_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptDataNonceContextData`")
        }
    }

}

public class MockEARMigratorProtocol: EARMigratorProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - migrateTowardEncryptionAtRest

    public var migrateTowardEncryptionAtRestContext_Invocations: [NSManagedObjectContext] = []
    public var migrateTowardEncryptionAtRestContext_MockError: Error?
    public var migrateTowardEncryptionAtRestContext_MockMethod: ((NSManagedObjectContext) throws -> Void)?

    public func migrateTowardEncryptionAtRest(context: NSManagedObjectContext) throws {
        migrateTowardEncryptionAtRestContext_Invocations.append(context)

        if let error = migrateTowardEncryptionAtRestContext_MockError {
            throw error
        }

        guard let mock = migrateTowardEncryptionAtRestContext_MockMethod else {
            fatalError("no mock for `migrateTowardEncryptionAtRestContext`")
        }

        try mock(context)
    }

    // MARK: - migrateAwayFromEncryptionAtRest

    public var migrateAwayFromEncryptionAtRestContext_Invocations: [NSManagedObjectContext] = []
    public var migrateAwayFromEncryptionAtRestContext_MockError: Error?
    public var migrateAwayFromEncryptionAtRestContext_MockMethod: ((NSManagedObjectContext) throws -> Void)?

    public func migrateAwayFromEncryptionAtRest(context: NSManagedObjectContext) throws {
        migrateAwayFromEncryptionAtRestContext_Invocations.append(context)

        if let error = migrateAwayFromEncryptionAtRestContext_MockError {
            throw error
        }

        guard let mock = migrateAwayFromEncryptionAtRestContext_MockMethod else {
            fatalError("no mock for `migrateAwayFromEncryptionAtRestContext`")
        }

        try mock(context)
    }

}

public class MockEARServiceInterface: EARServiceInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - delegate

    public var delegate: EARServiceDelegate?

    // MARK: - isLocked

    public var isLocked: Bool {
        get { return underlyingIsLocked }
        set(value) { underlyingIsLocked = value }
    }

    public var underlyingIsLocked: Bool!

    // MARK: - isEAREnabled

    public var isEAREnabled: Bool {
        get { return underlyingIsEAREnabled }
        set(value) { underlyingIsEAREnabled = value }
    }

    public var underlyingIsEAREnabled: Bool!


    // MARK: - enableEncryptionAtRest

    public var enableEncryptionAtRestContextSkipMigration_Invocations: [(context: NSManagedObjectContext, skipMigration: Bool)] = []
    public var enableEncryptionAtRestContextSkipMigration_MockError: Error?
    public var enableEncryptionAtRestContextSkipMigration_MockMethod: ((NSManagedObjectContext, Bool) throws -> Void)?

    public func enableEncryptionAtRest(context: NSManagedObjectContext, skipMigration: Bool) throws {
        enableEncryptionAtRestContextSkipMigration_Invocations.append((context: context, skipMigration: skipMigration))

        if let error = enableEncryptionAtRestContextSkipMigration_MockError {
            throw error
        }

        guard let mock = enableEncryptionAtRestContextSkipMigration_MockMethod else {
            fatalError("no mock for `enableEncryptionAtRestContextSkipMigration`")
        }

        try mock(context, skipMigration)
    }

    // MARK: - disableEncryptionAtRest

    public var disableEncryptionAtRestContextSkipMigration_Invocations: [(context: NSManagedObjectContext, skipMigration: Bool)] = []
    public var disableEncryptionAtRestContextSkipMigration_MockError: Error?
    public var disableEncryptionAtRestContextSkipMigration_MockMethod: ((NSManagedObjectContext, Bool) throws -> Void)?

    public func disableEncryptionAtRest(context: NSManagedObjectContext, skipMigration: Bool) throws {
        disableEncryptionAtRestContextSkipMigration_Invocations.append((context: context, skipMigration: skipMigration))

        if let error = disableEncryptionAtRestContextSkipMigration_MockError {
            throw error
        }

        guard let mock = disableEncryptionAtRestContextSkipMigration_MockMethod else {
            fatalError("no mock for `disableEncryptionAtRestContextSkipMigration`")
        }

        try mock(context, skipMigration)
    }

    // MARK: - lockDatabase

    public var lockDatabase_Invocations: [Void] = []
    public var lockDatabase_MockMethod: (() -> Void)?

    public func lockDatabase() {
        lockDatabase_Invocations.append(())

        guard let mock = lockDatabase_MockMethod else {
            fatalError("no mock for `lockDatabase`")
        }

        mock()
    }

    // MARK: - unlockDatabase

    public var unlockDatabase_Invocations: [Void] = []
    public var unlockDatabase_MockError: Error?
    public var unlockDatabase_MockMethod: (() throws -> Void)?

    public func unlockDatabase() throws {
        unlockDatabase_Invocations.append(())

        if let error = unlockDatabase_MockError {
            throw error
        }

        guard let mock = unlockDatabase_MockMethod else {
            fatalError("no mock for `unlockDatabase`")
        }

        try mock()
    }

    // MARK: - fetchPublicKeys

    public var fetchPublicKeys_Invocations: [Void] = []
    public var fetchPublicKeys_MockError: Error?
    public var fetchPublicKeys_MockMethod: (() throws -> EARPublicKeys?)?
    public var fetchPublicKeys_MockValue: EARPublicKeys??

    public func fetchPublicKeys() throws -> EARPublicKeys? {
        fetchPublicKeys_Invocations.append(())

        if let error = fetchPublicKeys_MockError {
            throw error
        }

        if let mock = fetchPublicKeys_MockMethod {
            return try mock()
        } else if let mock = fetchPublicKeys_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchPublicKeys`")
        }
    }

    // MARK: - fetchPrivateKeys

    public var fetchPrivateKeysIncludingPrimary_Invocations: [Bool] = []
    public var fetchPrivateKeysIncludingPrimary_MockError: Error?
    public var fetchPrivateKeysIncludingPrimary_MockMethod: ((Bool) throws -> EARPrivateKeys?)?
    public var fetchPrivateKeysIncludingPrimary_MockValue: EARPrivateKeys??

    public func fetchPrivateKeys(includingPrimary: Bool) throws -> EARPrivateKeys? {
        fetchPrivateKeysIncludingPrimary_Invocations.append(includingPrimary)

        if let error = fetchPrivateKeysIncludingPrimary_MockError {
            throw error
        }

        if let mock = fetchPrivateKeysIncludingPrimary_MockMethod {
            return try mock(includingPrimary)
        } else if let mock = fetchPrivateKeysIncludingPrimary_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchPrivateKeysIncludingPrimary`")
        }
    }

    // MARK: - setInitialEARFlagValue

    public var setInitialEARFlagValue_Invocations: [Bool] = []
    public var setInitialEARFlagValue_MockMethod: ((Bool) -> Void)?

    public func setInitialEARFlagValue(_ enabled: Bool) {
        setInitialEARFlagValue_Invocations.append(enabled)

        guard let mock = setInitialEARFlagValue_MockMethod else {
            fatalError("no mock for `setInitialEARFlagValue`")
        }

        mock(enabled)
    }

}

public class MockIsSelfUserE2EICertifiedUseCaseProtocol: IsSelfUserE2EICertifiedUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invoke_Invocations: [Void] = []
    public var invoke_MockError: Error?
    public var invoke_MockMethod: (() async throws -> Bool)?
    public var invoke_MockValue: Bool?

    public func invoke() async throws -> Bool {
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

public class MockIsUserE2EICertifiedUseCaseProtocol: IsUserE2EICertifiedUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invokeConversationUser_Invocations: [(conversation: ZMConversation, user: ZMUser)] = []
    public var invokeConversationUser_MockError: Error?
    public var invokeConversationUser_MockMethod: ((ZMConversation, ZMUser) async throws -> Bool)?
    public var invokeConversationUser_MockValue: Bool?

    public func invoke(conversation: ZMConversation, user: ZMUser) async throws -> Bool {
        invokeConversationUser_Invocations.append((conversation: conversation, user: user))

        if let error = invokeConversationUser_MockError {
            throw error
        }

        if let mock = invokeConversationUser_MockMethod {
            return try await mock(conversation, user)
        } else if let mock = invokeConversationUser_MockValue {
            return mock
        } else {
            fatalError("no mock for `invokeConversationUser`")
        }
    }

}

public class MockLAContextStorable: LAContextStorable {

    // MARK: - Life cycle

    public init() {}

    // MARK: - context

    public var context: LAContext?


    // MARK: - clear

    public var clear_Invocations: [Void] = []
    public var clear_MockMethod: (() -> Void)?

    public func clear() {
        clear_Invocations.append(())

        guard let mock = clear_MockMethod else {
            fatalError("no mock for `clear`")
        }

        mock()
    }

}

public class MockLastEventIDRepositoryInterface: LastEventIDRepositoryInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - fetchLastEventID

    public var fetchLastEventID_Invocations: [Void] = []
    public var fetchLastEventID_MockMethod: (() -> UUID?)?
    public var fetchLastEventID_MockValue: UUID??

    public func fetchLastEventID() -> UUID? {
        fetchLastEventID_Invocations.append(())

        if let mock = fetchLastEventID_MockMethod {
            return mock()
        } else if let mock = fetchLastEventID_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchLastEventID`")
        }
    }

    // MARK: - storeLastEventID

    public var storeLastEventID_Invocations: [UUID?] = []
    public var storeLastEventID_MockMethod: ((UUID?) -> Void)?

    public func storeLastEventID(_ id: UUID?) {
        storeLastEventID_Invocations.append(id)

        guard let mock = storeLastEventID_MockMethod else {
            fatalError("no mock for `storeLastEventID`")
        }

        mock(id)
    }

}

public class MockLegacyConversationEventProcessorProtocol: LegacyConversationEventProcessorProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - processConversationEvents

    public var processConversationEvents_Invocations: [[ZMUpdateEvent]] = []
    public var processConversationEvents_MockMethod: (([ZMUpdateEvent]) async -> Void)?

    public func processConversationEvents(_ events: [ZMUpdateEvent]) async {
        processConversationEvents_Invocations.append(events)

        guard let mock = processConversationEvents_MockMethod else {
            fatalError("no mock for `processConversationEvents`")
        }

        await mock(events)
    }

    // MARK: - processAndSaveConversationEvents

    public var processAndSaveConversationEvents_Invocations: [[ZMUpdateEvent]] = []
    public var processAndSaveConversationEvents_MockMethod: (([ZMUpdateEvent]) async -> Void)?

    public func processAndSaveConversationEvents(_ events: [ZMUpdateEvent]) async {
        processAndSaveConversationEvents_Invocations.append(events)

        guard let mock = processAndSaveConversationEvents_MockMethod else {
            fatalError("no mock for `processAndSaveConversationEvents`")
        }

        await mock(events)
    }

}

public class MockLegacyFeatureRepositoryInterface: LegacyFeatureRepositoryInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - fetchAppLock

    public var fetchAppLock_Invocations: [Void] = []
    public var fetchAppLock_MockMethod: (() -> Feature.AppLock)?
    public var fetchAppLock_MockValue: Feature.AppLock?

    public func fetchAppLock() -> Feature.AppLock {
        fetchAppLock_Invocations.append(())

        if let mock = fetchAppLock_MockMethod {
            return mock()
        } else if let mock = fetchAppLock_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchAppLock`")
        }
    }

    // MARK: - storeAppLock

    public var storeAppLock_Invocations: [Feature.AppLock] = []
    public var storeAppLock_MockMethod: ((Feature.AppLock) -> Void)?

    public func storeAppLock(_ appLock: Feature.AppLock) {
        storeAppLock_Invocations.append(appLock)

        guard let mock = storeAppLock_MockMethod else {
            fatalError("no mock for `storeAppLock`")
        }

        mock(appLock)
    }

    // MARK: - fetchApps

    public var fetchApps_Invocations: [Void] = []
    public var fetchApps_MockMethod: (() -> Feature.Apps)?
    public var fetchApps_MockValue: Feature.Apps?

    public func fetchApps() -> Feature.Apps {
        fetchApps_Invocations.append(())

        if let mock = fetchApps_MockMethod {
            return mock()
        } else if let mock = fetchApps_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchApps`")
        }
    }

    // MARK: - storeApps

    public var storeApps_Invocations: [Feature.Apps] = []
    public var storeApps_MockMethod: ((Feature.Apps) -> Void)?

    public func storeApps(_ appLock: Feature.Apps) {
        storeApps_Invocations.append(appLock)

        guard let mock = storeApps_MockMethod else {
            fatalError("no mock for `storeApps`")
        }

        mock(appLock)
    }

    // MARK: - fetchConferenceCalling

    public var fetchConferenceCalling_Invocations: [Void] = []
    public var fetchConferenceCalling_MockMethod: (() -> Feature.ConferenceCalling)?
    public var fetchConferenceCalling_MockValue: Feature.ConferenceCalling?

    public func fetchConferenceCalling() -> Feature.ConferenceCalling {
        fetchConferenceCalling_Invocations.append(())

        if let mock = fetchConferenceCalling_MockMethod {
            return mock()
        } else if let mock = fetchConferenceCalling_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchConferenceCalling`")
        }
    }

    // MARK: - storeConferenceCalling

    public var storeConferenceCalling_Invocations: [Feature.ConferenceCalling] = []
    public var storeConferenceCalling_MockMethod: ((Feature.ConferenceCalling) -> Void)?

    public func storeConferenceCalling(_ conferenceCalling: Feature.ConferenceCalling) {
        storeConferenceCalling_Invocations.append(conferenceCalling)

        guard let mock = storeConferenceCalling_MockMethod else {
            fatalError("no mock for `storeConferenceCalling`")
        }

        mock(conferenceCalling)
    }

    // MARK: - fetchFileSharing

    public var fetchFileSharing_Invocations: [Void] = []
    public var fetchFileSharing_MockMethod: (() -> Feature.FileSharing)?
    public var fetchFileSharing_MockValue: Feature.FileSharing?

    public func fetchFileSharing() -> Feature.FileSharing {
        fetchFileSharing_Invocations.append(())

        if let mock = fetchFileSharing_MockMethod {
            return mock()
        } else if let mock = fetchFileSharing_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchFileSharing`")
        }
    }

    // MARK: - storeFileSharing

    public var storeFileSharing_Invocations: [Feature.FileSharing] = []
    public var storeFileSharing_MockMethod: ((Feature.FileSharing) -> Void)?

    public func storeFileSharing(_ fileSharing: Feature.FileSharing) {
        storeFileSharing_Invocations.append(fileSharing)

        guard let mock = storeFileSharing_MockMethod else {
            fatalError("no mock for `storeFileSharing`")
        }

        mock(fileSharing)
    }

    // MARK: - fetchSelfDeletingMessages

    public var fetchSelfDeletingMessages_Invocations: [Void] = []
    public var fetchSelfDeletingMessages_MockMethod: (() -> Feature.SelfDeletingMessages)?
    public var fetchSelfDeletingMessages_MockValue: Feature.SelfDeletingMessages?

    public func fetchSelfDeletingMessages() -> Feature.SelfDeletingMessages {
        fetchSelfDeletingMessages_Invocations.append(())

        if let mock = fetchSelfDeletingMessages_MockMethod {
            return mock()
        } else if let mock = fetchSelfDeletingMessages_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfDeletingMessages`")
        }
    }

    // MARK: - storeSelfDeletingMessages

    public var storeSelfDeletingMessages_Invocations: [Feature.SelfDeletingMessages] = []
    public var storeSelfDeletingMessages_MockMethod: ((Feature.SelfDeletingMessages) -> Void)?

    public func storeSelfDeletingMessages(_ selfDeletingMessages: Feature.SelfDeletingMessages) {
        storeSelfDeletingMessages_Invocations.append(selfDeletingMessages)

        guard let mock = storeSelfDeletingMessages_MockMethod else {
            fatalError("no mock for `storeSelfDeletingMessages`")
        }

        mock(selfDeletingMessages)
    }

    // MARK: - fetchAllowedGlobalOperations

    public var fetchAllowedGlobalOperations_Invocations: [Void] = []
    public var fetchAllowedGlobalOperations_MockMethod: (() async -> Feature.AllowedGlobalOperations)?
    public var fetchAllowedGlobalOperations_MockValue: Feature.AllowedGlobalOperations?

    public func fetchAllowedGlobalOperations() async -> Feature.AllowedGlobalOperations {
        fetchAllowedGlobalOperations_Invocations.append(())

        if let mock = fetchAllowedGlobalOperations_MockMethod {
            return await mock()
        } else if let mock = fetchAllowedGlobalOperations_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchAllowedGlobalOperations`")
        }
    }

    // MARK: - storeAllowedGlobalOperations

    public var storeAllowedGlobalOperations_Invocations: [Feature.AllowedGlobalOperations] = []
    public var storeAllowedGlobalOperations_MockMethod: ((Feature.AllowedGlobalOperations) -> Void)?

    public func storeAllowedGlobalOperations(_ resetMLSConversations: Feature.AllowedGlobalOperations) {
        storeAllowedGlobalOperations_Invocations.append(resetMLSConversations)

        guard let mock = storeAllowedGlobalOperations_MockMethod else {
            fatalError("no mock for `storeAllowedGlobalOperations`")
        }

        mock(resetMLSConversations)
    }

    // MARK: - fetchConversationGuestLinks

    public var fetchConversationGuestLinks_Invocations: [Void] = []
    public var fetchConversationGuestLinks_MockMethod: (() -> Feature.ConversationGuestLinks)?
    public var fetchConversationGuestLinks_MockValue: Feature.ConversationGuestLinks?

    public func fetchConversationGuestLinks() -> Feature.ConversationGuestLinks {
        fetchConversationGuestLinks_Invocations.append(())

        if let mock = fetchConversationGuestLinks_MockMethod {
            return mock()
        } else if let mock = fetchConversationGuestLinks_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchConversationGuestLinks`")
        }
    }

    // MARK: - storeConversationGuestLinks

    public var storeConversationGuestLinks_Invocations: [Feature.ConversationGuestLinks] = []
    public var storeConversationGuestLinks_MockMethod: ((Feature.ConversationGuestLinks) -> Void)?

    public func storeConversationGuestLinks(_ conversationGuestLinks: Feature.ConversationGuestLinks) {
        storeConversationGuestLinks_Invocations.append(conversationGuestLinks)

        guard let mock = storeConversationGuestLinks_MockMethod else {
            fatalError("no mock for `storeConversationGuestLinks`")
        }

        mock(conversationGuestLinks)
    }

    // MARK: - fetchClassifiedDomains

    public var fetchClassifiedDomains_Invocations: [Void] = []
    public var fetchClassifiedDomains_MockMethod: (() -> Feature.ClassifiedDomains)?
    public var fetchClassifiedDomains_MockValue: Feature.ClassifiedDomains?

    public func fetchClassifiedDomains() -> Feature.ClassifiedDomains {
        fetchClassifiedDomains_Invocations.append(())

        if let mock = fetchClassifiedDomains_MockMethod {
            return mock()
        } else if let mock = fetchClassifiedDomains_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchClassifiedDomains`")
        }
    }

    // MARK: - storeClassifiedDomains

    public var storeClassifiedDomains_Invocations: [Feature.ClassifiedDomains] = []
    public var storeClassifiedDomains_MockMethod: ((Feature.ClassifiedDomains) -> Void)?

    public func storeClassifiedDomains(_ classifiedDomains: Feature.ClassifiedDomains) {
        storeClassifiedDomains_Invocations.append(classifiedDomains)

        guard let mock = storeClassifiedDomains_MockMethod else {
            fatalError("no mock for `storeClassifiedDomains`")
        }

        mock(classifiedDomains)
    }

    // MARK: - fetchDigitalSignature

    public var fetchDigitalSignature_Invocations: [Void] = []
    public var fetchDigitalSignature_MockMethod: (() -> Feature.DigitalSignature)?
    public var fetchDigitalSignature_MockValue: Feature.DigitalSignature?

    public func fetchDigitalSignature() -> Feature.DigitalSignature {
        fetchDigitalSignature_Invocations.append(())

        if let mock = fetchDigitalSignature_MockMethod {
            return mock()
        } else if let mock = fetchDigitalSignature_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchDigitalSignature`")
        }
    }

    // MARK: - storeDigitalSignature

    public var storeDigitalSignature_Invocations: [Feature.DigitalSignature] = []
    public var storeDigitalSignature_MockMethod: ((Feature.DigitalSignature) -> Void)?

    public func storeDigitalSignature(_ digitalSignature: Feature.DigitalSignature) {
        storeDigitalSignature_Invocations.append(digitalSignature)

        guard let mock = storeDigitalSignature_MockMethod else {
            fatalError("no mock for `storeDigitalSignature`")
        }

        mock(digitalSignature)
    }

    // MARK: - fetchMLS

    public var fetchMLS_Invocations: [Void] = []
    public var fetchMLS_MockMethod: (() -> Feature.MLS)?
    public var fetchMLS_MockValue: Feature.MLS?

    public func fetchMLS() -> Feature.MLS {
        fetchMLS_Invocations.append(())

        if let mock = fetchMLS_MockMethod {
            return mock()
        } else if let mock = fetchMLS_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchMLS`")
        }
    }

    // MARK: - storeMLS

    public var storeMLS_Invocations: [Feature.MLS] = []
    public var storeMLS_MockMethod: ((Feature.MLS) -> Void)?

    public func storeMLS(_ mls: Feature.MLS) {
        storeMLS_Invocations.append(mls)

        guard let mock = storeMLS_MockMethod else {
            fatalError("no mock for `storeMLS`")
        }

        mock(mls)
    }

    // MARK: - fetchE2EI

    public var fetchE2EI_Invocations: [Void] = []
    public var fetchE2EI_MockMethod: (() -> Feature.E2EI)?
    public var fetchE2EI_MockValue: Feature.E2EI?

    public func fetchE2EI() -> Feature.E2EI {
        fetchE2EI_Invocations.append(())

        if let mock = fetchE2EI_MockMethod {
            return mock()
        } else if let mock = fetchE2EI_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchE2EI`")
        }
    }

    // MARK: - storeE2EI

    public var storeE2EI_Invocations: [Feature.E2EI] = []
    public var storeE2EI_MockMethod: ((Feature.E2EI) -> Void)?

    public func storeE2EI(_ e2ei: Feature.E2EI) {
        storeE2EI_Invocations.append(e2ei)

        guard let mock = storeE2EI_MockMethod else {
            fatalError("no mock for `storeE2EI`")
        }

        mock(e2ei)
    }

    // MARK: - fetchMLSMigration

    public var fetchMLSMigration_Invocations: [Void] = []
    public var fetchMLSMigration_MockMethod: (() -> Feature.MLSMigration)?
    public var fetchMLSMigration_MockValue: Feature.MLSMigration?

    public func fetchMLSMigration() -> Feature.MLSMigration {
        fetchMLSMigration_Invocations.append(())

        if let mock = fetchMLSMigration_MockMethod {
            return mock()
        } else if let mock = fetchMLSMigration_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchMLSMigration`")
        }
    }

    // MARK: - storeMLSMigration

    public var storeMLSMigration_Invocations: [Feature.MLSMigration] = []
    public var storeMLSMigration_MockMethod: ((Feature.MLSMigration) -> Void)?

    public func storeMLSMigration(_ mlsMigration: Feature.MLSMigration) {
        storeMLSMigration_Invocations.append(mlsMigration)

        guard let mock = storeMLSMigration_MockMethod else {
            fatalError("no mock for `storeMLSMigration`")
        }

        mock(mlsMigration)
    }

    // MARK: - fetchChannels

    public var fetchChannels_Invocations: [Void] = []
    public var fetchChannels_MockMethod: (() -> Feature.Channels)?
    public var fetchChannels_MockValue: Feature.Channels?

    public func fetchChannels() -> Feature.Channels {
        fetchChannels_Invocations.append(())

        if let mock = fetchChannels_MockMethod {
            return mock()
        } else if let mock = fetchChannels_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchChannels`")
        }
    }

    // MARK: - storeChannels

    public var storeChannels_Invocations: [Feature.Channels] = []
    public var storeChannels_MockMethod: ((Feature.Channels) -> Void)?

    public func storeChannels(_ channels: Feature.Channels) {
        storeChannels_Invocations.append(channels)

        guard let mock = storeChannels_MockMethod else {
            fatalError("no mock for `storeChannels`")
        }

        mock(channels)
    }

    // MARK: - fetchConsumableNotifications

    public var fetchConsumableNotifications_Invocations: [Void] = []
    public var fetchConsumableNotifications_MockMethod: (() -> Feature.ConsumableNotifications)?
    public var fetchConsumableNotifications_MockValue: Feature.ConsumableNotifications?

    public func fetchConsumableNotifications() -> Feature.ConsumableNotifications {
        fetchConsumableNotifications_Invocations.append(())

        if let mock = fetchConsumableNotifications_MockMethod {
            return mock()
        } else if let mock = fetchConsumableNotifications_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchConsumableNotifications`")
        }
    }

    // MARK: - storeConsumableNotifications

    public var storeConsumableNotifications_Invocations: [Feature.ConsumableNotifications] = []
    public var storeConsumableNotifications_MockMethod: ((Feature.ConsumableNotifications) -> Void)?

    public func storeConsumableNotifications(_ consumableNotifications: Feature.ConsumableNotifications) {
        storeConsumableNotifications_Invocations.append(consumableNotifications)

        guard let mock = storeConsumableNotifications_MockMethod else {
            fatalError("no mock for `storeConsumableNotifications`")
        }

        mock(consumableNotifications)
    }

    // MARK: - fetchCells

    public var fetchCells_Invocations: [Void] = []
    public var fetchCells_MockMethod: (() -> Feature.Cells)?
    public var fetchCells_MockValue: Feature.Cells?

    public func fetchCells() -> Feature.Cells {
        fetchCells_Invocations.append(())

        if let mock = fetchCells_MockMethod {
            return mock()
        } else if let mock = fetchCells_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchCells`")
        }
    }

    // MARK: - storeCells

    public var storeCells_Invocations: [Feature.Cells] = []
    public var storeCells_MockMethod: ((Feature.Cells) -> Void)?

    public func storeCells(_ cells: Feature.Cells) {
        storeCells_Invocations.append(cells)

        guard let mock = storeCells_MockMethod else {
            fatalError("no mock for `storeCells`")
        }

        mock(cells)
    }

    // MARK: - fetchAssetAuditLog

    public var fetchAssetAuditLog_Invocations: [Void] = []
    public var fetchAssetAuditLog_MockMethod: (() -> Feature.AssetAuditLog)?
    public var fetchAssetAuditLog_MockValue: Feature.AssetAuditLog?

    public func fetchAssetAuditLog() -> Feature.AssetAuditLog {
        fetchAssetAuditLog_Invocations.append(())

        if let mock = fetchAssetAuditLog_MockMethod {
            return mock()
        } else if let mock = fetchAssetAuditLog_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchAssetAuditLog`")
        }
    }

    // MARK: - fetchCellsInternal

    public var fetchCellsInternal_Invocations: [Void] = []
    public var fetchCellsInternal_MockMethod: (() -> Feature.CellsInternal?)?
    public var fetchCellsInternal_MockValue: Feature.CellsInternal??

    public func fetchCellsInternal() -> Feature.CellsInternal? {
        fetchCellsInternal_Invocations.append(())

        if let mock = fetchCellsInternal_MockMethod {
            return mock()
        } else if let mock = fetchCellsInternal_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchCellsInternal`")
        }
    }

}

class MockMLSActionsProviderProtocol: MLSActionsProviderProtocol {

    // MARK: - Life cycle



    // MARK: - fetchBackendPublicKeys

    var fetchBackendPublicKeysIn_Invocations: [NotificationContext] = []
    var fetchBackendPublicKeysIn_MockError: Error?
    var fetchBackendPublicKeysIn_MockMethod: ((NotificationContext) async throws -> BackendMLSPublicKeys)?
    var fetchBackendPublicKeysIn_MockValue: BackendMLSPublicKeys?

    func fetchBackendPublicKeys(in context: NotificationContext) async throws -> BackendMLSPublicKeys {
        fetchBackendPublicKeysIn_Invocations.append(context)

        if let error = fetchBackendPublicKeysIn_MockError {
            throw error
        }

        if let mock = fetchBackendPublicKeysIn_MockMethod {
            return try await mock(context)
        } else if let mock = fetchBackendPublicKeysIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchBackendPublicKeysIn`")
        }
    }

    // MARK: - countUnclaimedKeyPackages

    var countUnclaimedKeyPackagesClientIDCiphersuiteContext_Invocations: [(clientID: String, ciphersuite: MLSCipherSuite?, context: NotificationContext)] = []
    var countUnclaimedKeyPackagesClientIDCiphersuiteContext_MockError: Error?
    var countUnclaimedKeyPackagesClientIDCiphersuiteContext_MockMethod: ((String, MLSCipherSuite?, NotificationContext) async throws -> Int)?
    var countUnclaimedKeyPackagesClientIDCiphersuiteContext_MockValue: Int?

    func countUnclaimedKeyPackages(clientID: String, ciphersuite: MLSCipherSuite?, context: NotificationContext) async throws -> Int {
        countUnclaimedKeyPackagesClientIDCiphersuiteContext_Invocations.append((clientID: clientID, ciphersuite: ciphersuite, context: context))

        if let error = countUnclaimedKeyPackagesClientIDCiphersuiteContext_MockError {
            throw error
        }

        if let mock = countUnclaimedKeyPackagesClientIDCiphersuiteContext_MockMethod {
            return try await mock(clientID, ciphersuite, context)
        } else if let mock = countUnclaimedKeyPackagesClientIDCiphersuiteContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `countUnclaimedKeyPackagesClientIDCiphersuiteContext`")
        }
    }

    // MARK: - uploadKeyPackages

    var uploadKeyPackagesClientIDKeyPackagesContext_Invocations: [(clientID: String, keyPackages: [String], context: NotificationContext)] = []
    var uploadKeyPackagesClientIDKeyPackagesContext_MockError: Error?
    var uploadKeyPackagesClientIDKeyPackagesContext_MockMethod: ((String, [String], NotificationContext) async throws -> Void)?

    func uploadKeyPackages(clientID: String, keyPackages: [String], context: NotificationContext) async throws {
        uploadKeyPackagesClientIDKeyPackagesContext_Invocations.append((clientID: clientID, keyPackages: keyPackages, context: context))

        if let error = uploadKeyPackagesClientIDKeyPackagesContext_MockError {
            throw error
        }

        guard let mock = uploadKeyPackagesClientIDKeyPackagesContext_MockMethod else {
            fatalError("no mock for `uploadKeyPackagesClientIDKeyPackagesContext`")
        }

        try await mock(clientID, keyPackages, context)
    }

    // MARK: - claimKeyPackages

    var claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_Invocations: [(userID: UUID, domain: String?, ciphersuite: MLSCipherSuite, excludedSelfClientID: String?, context: NotificationContext)] = []
    var claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockError: Error?
    var claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockMethod: ((UUID, String?, MLSCipherSuite, String?, NotificationContext) async throws -> [WireDataModel.KeyPackage])?
    var claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockValue: [WireDataModel.KeyPackage]?

    func claimKeyPackages(userID: UUID, domain: String?, ciphersuite: MLSCipherSuite, excludedSelfClientID: String?, in context: NotificationContext) async throws -> [WireDataModel.KeyPackage] {
        claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_Invocations.append((userID: userID, domain: domain, ciphersuite: ciphersuite, excludedSelfClientID: excludedSelfClientID, context: context))

        if let error = claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockError {
            throw error
        }

        if let mock = claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockMethod {
            return try await mock(userID, domain, ciphersuite, excludedSelfClientID, context)
        } else if let mock = claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn`")
        }
    }

    // MARK: - fetchConversationGroupInfo

    var fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_Invocations: [(conversationId: UUID, domain: String, subgroupType: SubgroupType?, context: NotificationContext)] = []
    var fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockError: Error?
    var fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockMethod: ((UUID, String, SubgroupType?, NotificationContext) async throws -> Data)?
    var fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue: Data?

    func fetchConversationGroupInfo(conversationId: UUID, domain: String, subgroupType: SubgroupType?, context: NotificationContext) async throws -> Data {
        fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_Invocations.append((conversationId: conversationId, domain: domain, subgroupType: subgroupType, context: context))

        if let error = fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockError {
            throw error
        }

        if let mock = fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockMethod {
            return try await mock(conversationId, domain, subgroupType, context)
        } else if let mock = fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext`")
        }
    }

    // MARK: - fetchSubgroup

    var fetchSubgroupConversationIDDomainTypeContext_Invocations: [(conversationID: UUID, domain: String, type: SubgroupType, context: NotificationContext)] = []
    var fetchSubgroupConversationIDDomainTypeContext_MockError: Error?
    var fetchSubgroupConversationIDDomainTypeContext_MockMethod: ((UUID, String, SubgroupType, NotificationContext) async throws -> MLSSubgroup)?
    var fetchSubgroupConversationIDDomainTypeContext_MockValue: MLSSubgroup?

    func fetchSubgroup(conversationID: UUID, domain: String, type: SubgroupType, context: NotificationContext) async throws -> MLSSubgroup {
        fetchSubgroupConversationIDDomainTypeContext_Invocations.append((conversationID: conversationID, domain: domain, type: type, context: context))

        if let error = fetchSubgroupConversationIDDomainTypeContext_MockError {
            throw error
        }

        if let mock = fetchSubgroupConversationIDDomainTypeContext_MockMethod {
            return try await mock(conversationID, domain, type, context)
        } else if let mock = fetchSubgroupConversationIDDomainTypeContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSubgroupConversationIDDomainTypeContext`")
        }
    }

    // MARK: - deleteSubgroup

    var deleteSubgroupConversationIDDomainSubgroupTypeEpochGroupIDContext_Invocations: [(conversationID: UUID, domain: String, subgroupType: SubgroupType, epoch: Int, groupID: MLSGroupID, context: NotificationContext)] = []
    var deleteSubgroupConversationIDDomainSubgroupTypeEpochGroupIDContext_MockError: Error?
    var deleteSubgroupConversationIDDomainSubgroupTypeEpochGroupIDContext_MockMethod: ((UUID, String, SubgroupType, Int, MLSGroupID, NotificationContext) async throws -> Void)?

    func deleteSubgroup(conversationID: UUID, domain: String, subgroupType: SubgroupType, epoch: Int, groupID: MLSGroupID, context: NotificationContext) async throws {
        deleteSubgroupConversationIDDomainSubgroupTypeEpochGroupIDContext_Invocations.append((conversationID: conversationID, domain: domain, subgroupType: subgroupType, epoch: epoch, groupID: groupID, context: context))

        if let error = deleteSubgroupConversationIDDomainSubgroupTypeEpochGroupIDContext_MockError {
            throw error
        }

        guard let mock = deleteSubgroupConversationIDDomainSubgroupTypeEpochGroupIDContext_MockMethod else {
            fatalError("no mock for `deleteSubgroupConversationIDDomainSubgroupTypeEpochGroupIDContext`")
        }

        try await mock(conversationID, domain, subgroupType, epoch, groupID, context)
    }

    // MARK: - leaveSubconversation

    var leaveSubconversationConversationIDDomainSubconversationTypeContext_Invocations: [(conversationID: UUID, domain: String, subconversationType: SubgroupType, context: NotificationContext)] = []
    var leaveSubconversationConversationIDDomainSubconversationTypeContext_MockError: Error?
    var leaveSubconversationConversationIDDomainSubconversationTypeContext_MockMethod: ((UUID, String, SubgroupType, NotificationContext) async throws -> Void)?

    func leaveSubconversation(conversationID: UUID, domain: String, subconversationType: SubgroupType, context: NotificationContext) async throws {
        leaveSubconversationConversationIDDomainSubconversationTypeContext_Invocations.append((conversationID: conversationID, domain: domain, subconversationType: subconversationType, context: context))

        if let error = leaveSubconversationConversationIDDomainSubconversationTypeContext_MockError {
            throw error
        }

        guard let mock = leaveSubconversationConversationIDDomainSubconversationTypeContext_MockMethod else {
            fatalError("no mock for `leaveSubconversationConversationIDDomainSubconversationTypeContext`")
        }

        try await mock(conversationID, domain, subconversationType, context)
    }

    // MARK: - syncConversation

    var syncConversationQualifiedIDContext_Invocations: [(qualifiedID: QualifiedID, context: NotificationContext)] = []
    var syncConversationQualifiedIDContext_MockError: Error?
    var syncConversationQualifiedIDContext_MockMethod: ((QualifiedID, NotificationContext) async throws -> Void)?

    func syncConversation(qualifiedID: QualifiedID, context: NotificationContext) async throws {
        syncConversationQualifiedIDContext_Invocations.append((qualifiedID: qualifiedID, context: context))

        if let error = syncConversationQualifiedIDContext_MockError {
            throw error
        }

        guard let mock = syncConversationQualifiedIDContext_MockMethod else {
            fatalError("no mock for `syncConversationQualifiedIDContext`")
        }

        try await mock(qualifiedID, context)
    }

    // MARK: - updateConversationProtocol

    var updateConversationProtocolQualifiedIDMessageProtocolContext_Invocations: [(qualifiedID: QualifiedID, messageProtocol: MessageProtocol, context: NotificationContext)] = []
    var updateConversationProtocolQualifiedIDMessageProtocolContext_MockError: Error?
    var updateConversationProtocolQualifiedIDMessageProtocolContext_MockMethod: ((QualifiedID, MessageProtocol, NotificationContext) async throws -> Void)?

    func updateConversationProtocol(qualifiedID: QualifiedID, messageProtocol: MessageProtocol, context: NotificationContext) async throws {
        updateConversationProtocolQualifiedIDMessageProtocolContext_Invocations.append((qualifiedID: qualifiedID, messageProtocol: messageProtocol, context: context))

        if let error = updateConversationProtocolQualifiedIDMessageProtocolContext_MockError {
            throw error
        }

        guard let mock = updateConversationProtocolQualifiedIDMessageProtocolContext_MockMethod else {
            fatalError("no mock for `updateConversationProtocolQualifiedIDMessageProtocolContext`")
        }

        try await mock(qualifiedID, messageProtocol, context)
    }

    // MARK: - syncUsers

    var syncUsersQualifiedIDsContext_Invocations: [(qualifiedIDs: [QualifiedID], context: NotificationContext)] = []
    var syncUsersQualifiedIDsContext_MockError: Error?
    var syncUsersQualifiedIDsContext_MockMethod: (([QualifiedID], NotificationContext) async throws -> Void)?

    func syncUsers(qualifiedIDs: [QualifiedID], context: NotificationContext) async throws {
        syncUsersQualifiedIDsContext_Invocations.append((qualifiedIDs: qualifiedIDs, context: context))

        if let error = syncUsersQualifiedIDsContext_MockError {
            throw error
        }

        guard let mock = syncUsersQualifiedIDsContext_MockMethod else {
            fatalError("no mock for `syncUsersQualifiedIDsContext`")
        }

        try await mock(qualifiedIDs, context)
    }

}

public class MockMLSClientManagerProtocol: MLSClientManagerProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - initializeMLSClientIfNeeded

    public var initializeMLSClientIfNeededForHasRegisteredMLSClientMlsFeatureIsBackendMLSEnabledIsE2EIRequired_Invocations: [(qualifiedClientID: QualifiedClientID, hasRegisteredMLSClient: Bool, mlsFeature: Feature.MLS, isBackendMLSEnabled: Bool, isE2EIRequired: Bool)] = []
    public var initializeMLSClientIfNeededForHasRegisteredMLSClientMlsFeatureIsBackendMLSEnabledIsE2EIRequired_MockMethod: ((QualifiedClientID, Bool, Feature.MLS, Bool, Bool) async -> Void)?

    public func initializeMLSClientIfNeeded(for qualifiedClientID: QualifiedClientID, hasRegisteredMLSClient: Bool, mlsFeature: Feature.MLS, isBackendMLSEnabled: Bool, isE2EIRequired: Bool) async {
        initializeMLSClientIfNeededForHasRegisteredMLSClientMlsFeatureIsBackendMLSEnabledIsE2EIRequired_Invocations.append((qualifiedClientID: qualifiedClientID, hasRegisteredMLSClient: hasRegisteredMLSClient, mlsFeature: mlsFeature, isBackendMLSEnabled: isBackendMLSEnabled, isE2EIRequired: isE2EIRequired))

        guard let mock = initializeMLSClientIfNeededForHasRegisteredMLSClientMlsFeatureIsBackendMLSEnabledIsE2EIRequired_MockMethod else {
            fatalError("no mock for `initializeMLSClientIfNeededForHasRegisteredMLSClientMlsFeatureIsBackendMLSEnabledIsE2EIRequired`")
        }

        await mock(qualifiedClientID, hasRegisteredMLSClient, mlsFeature, isBackendMLSEnabled, isE2EIRequired)
    }

}

public class MockMLSDecryptionServiceInterface: MLSDecryptionServiceInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - decrypt

    public var decryptMessageForSubconversationTypeContext_Invocations: [(message: String, groupID: MLSGroupID, subconversationType: SubgroupType?, context: CoreCryptoContextProtocol?)] = []
    public var decryptMessageForSubconversationTypeContext_MockError: Error?
    public var decryptMessageForSubconversationTypeContext_MockMethod: ((String, MLSGroupID, SubgroupType?, CoreCryptoContextProtocol?) async throws -> [MLSDecryptResult])?
    public var decryptMessageForSubconversationTypeContext_MockValue: [MLSDecryptResult]?

    public func decrypt(message: String, for groupID: MLSGroupID, subconversationType: SubgroupType?, context: CoreCryptoContextProtocol?) async throws -> [MLSDecryptResult] {
        decryptMessageForSubconversationTypeContext_Invocations.append((message: message, groupID: groupID, subconversationType: subconversationType, context: context))

        if let error = decryptMessageForSubconversationTypeContext_MockError {
            throw error
        }

        if let mock = decryptMessageForSubconversationTypeContext_MockMethod {
            return try await mock(message, groupID, subconversationType, context)
        } else if let mock = decryptMessageForSubconversationTypeContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptMessageForSubconversationTypeContext`")
        }
    }

    // MARK: - processWelcomeMessage

    public var processWelcomeMessageWelcomeMessageContext_Invocations: [(welcomeMessage: String, context: CoreCryptoContextProtocol?)] = []
    public var processWelcomeMessageWelcomeMessageContext_MockError: Error?
    public var processWelcomeMessageWelcomeMessageContext_MockMethod: ((String, CoreCryptoContextProtocol?) async throws -> MLSGroupID)?
    public var processWelcomeMessageWelcomeMessageContext_MockValue: MLSGroupID?

    public func processWelcomeMessage(welcomeMessage: String, context: CoreCryptoContextProtocol?) async throws -> MLSGroupID {
        processWelcomeMessageWelcomeMessageContext_Invocations.append((welcomeMessage: welcomeMessage, context: context))

        if let error = processWelcomeMessageWelcomeMessageContext_MockError {
            throw error
        }

        if let mock = processWelcomeMessageWelcomeMessageContext_MockMethod {
            return try await mock(welcomeMessage, context)
        } else if let mock = processWelcomeMessageWelcomeMessageContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `processWelcomeMessageWelcomeMessageContext`")
        }
    }

}

public class MockMLSEncryptionServiceInterface: MLSEncryptionServiceInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - encrypt

    public var encryptMessageFor_Invocations: [(message: Data, groupID: MLSGroupID)] = []
    public var encryptMessageFor_MockError: Error?
    public var encryptMessageFor_MockMethod: ((Data, MLSGroupID) async throws -> Data)?
    public var encryptMessageFor_MockValue: Data?

    public func encrypt(message: Data, for groupID: MLSGroupID) async throws -> Data {
        encryptMessageFor_Invocations.append((message: message, groupID: groupID))

        if let error = encryptMessageFor_MockError {
            throw error
        }

        if let mock = encryptMessageFor_MockMethod {
            return try await mock(message, groupID)
        } else if let mock = encryptMessageFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `encryptMessageFor`")
        }
    }

}

public class MockMLSGroupVerificationProtocol: MLSGroupVerificationProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - startObserving

    public var startObserving_Invocations: [Void] = []
    public var startObserving_MockMethod: (() -> Void)?

    public func startObserving() {
        startObserving_Invocations.append(())

        guard let mock = startObserving_MockMethod else {
            fatalError("no mock for `startObserving`")
        }

        mock()
    }

    // MARK: - updateConversation

    public var updateConversationBy_Invocations: [MLSGroupID] = []
    public var updateConversationBy_MockMethod: ((MLSGroupID) async -> Void)?

    public func updateConversation(by groupID: MLSGroupID) async {
        updateConversationBy_Invocations.append(groupID)

        guard let mock = updateConversationBy_MockMethod else {
            fatalError("no mock for `updateConversationBy`")
        }

        await mock(groupID)
    }

    // MARK: - updateConversation

    public var updateConversationWith_Invocations: [(conversation: ZMConversation, groupID: MLSGroupID)] = []
    public var updateConversationWith_MockMethod: ((ZMConversation, MLSGroupID) async -> Void)?

    public func updateConversation(_ conversation: ZMConversation, with groupID: MLSGroupID) async {
        updateConversationWith_Invocations.append((conversation: conversation, groupID: groupID))

        guard let mock = updateConversationWith_MockMethod else {
            fatalError("no mock for `updateConversationWith`")
        }

        await mock(conversation, groupID)
    }

    // MARK: - updateAllConversations

    public var updateAllConversations_Invocations: [Void] = []
    public var updateAllConversations_MockMethod: (() async -> Void)?

    public func updateAllConversations() async {
        updateAllConversations_Invocations.append(())

        guard let mock = updateAllConversations_MockMethod else {
            fatalError("no mock for `updateAllConversations`")
        }

        await mock()
    }

}

public class MockMLSServiceInterface: MLSServiceInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - localDomain

    public var localDomain: String {
        get { return underlyingLocalDomain }
        set(value) { underlyingLocalDomain = value }
    }

    public var underlyingLocalDomain: String!


    // MARK: - createGroup

    public var createGroupForParentGroupID_Invocations: [(groupID: MLSGroupID, parentGroupID: MLSGroupID)] = []
    public var createGroupForParentGroupID_MockError: Error?
    public var createGroupForParentGroupID_MockMethod: ((MLSGroupID, MLSGroupID) async throws -> MLSCipherSuite)?
    public var createGroupForParentGroupID_MockValue: MLSCipherSuite?

    public func createGroup(for groupID: MLSGroupID, parentGroupID: MLSGroupID) async throws -> MLSCipherSuite {
        createGroupForParentGroupID_Invocations.append((groupID: groupID, parentGroupID: parentGroupID))

        if let error = createGroupForParentGroupID_MockError {
            throw error
        }

        if let mock = createGroupForParentGroupID_MockMethod {
            return try await mock(groupID, parentGroupID)
        } else if let mock = createGroupForParentGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `createGroupForParentGroupID`")
        }
    }

    // MARK: - createGroup

    public var createGroupForRemovalKeys_Invocations: [(groupID: MLSGroupID, removalKeys: BackendMLSPublicKeys?)] = []
    public var createGroupForRemovalKeys_MockError: Error?
    public var createGroupForRemovalKeys_MockMethod: ((MLSGroupID, BackendMLSPublicKeys?) async throws -> MLSCipherSuite)?
    public var createGroupForRemovalKeys_MockValue: MLSCipherSuite?

    public func createGroup(for groupID: MLSGroupID, removalKeys: BackendMLSPublicKeys?) async throws -> MLSCipherSuite {
        createGroupForRemovalKeys_Invocations.append((groupID: groupID, removalKeys: removalKeys))

        if let error = createGroupForRemovalKeys_MockError {
            throw error
        }

        if let mock = createGroupForRemovalKeys_MockMethod {
            return try await mock(groupID, removalKeys)
        } else if let mock = createGroupForRemovalKeys_MockValue {
            return mock
        } else {
            fatalError("no mock for `createGroupForRemovalKeys`")
        }
    }

    // MARK: - createSelfGroup

    public var createSelfGroupFor_Invocations: [MLSGroupID] = []
    public var createSelfGroupFor_MockError: Error?
    public var createSelfGroupFor_MockMethod: ((MLSGroupID) async throws -> MLSCipherSuite)?
    public var createSelfGroupFor_MockValue: MLSCipherSuite?

    public func createSelfGroup(for groupID: MLSGroupID) async throws -> MLSCipherSuite {
        createSelfGroupFor_Invocations.append(groupID)

        if let error = createSelfGroupFor_MockError {
            throw error
        }

        if let mock = createSelfGroupFor_MockMethod {
            return try await mock(groupID)
        } else if let mock = createSelfGroupFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `createSelfGroupFor`")
        }
    }

    // MARK: - establishGroup

    public var establishGroupForWithRemovalKeys_Invocations: [(groupID: MLSGroupID, users: [MLSUser], removalKeys: BackendMLSPublicKeys?)] = []
    public var establishGroupForWithRemovalKeys_MockError: Error?
    public var establishGroupForWithRemovalKeys_MockMethod: ((MLSGroupID, [MLSUser], BackendMLSPublicKeys?) async throws -> MLSCipherSuite)?
    public var establishGroupForWithRemovalKeys_MockValue: MLSCipherSuite?

    public func establishGroup(for groupID: MLSGroupID, with users: [MLSUser], removalKeys: BackendMLSPublicKeys?) async throws -> MLSCipherSuite {
        establishGroupForWithRemovalKeys_Invocations.append((groupID: groupID, users: users, removalKeys: removalKeys))

        if let error = establishGroupForWithRemovalKeys_MockError {
            throw error
        }

        if let mock = establishGroupForWithRemovalKeys_MockMethod {
            return try await mock(groupID, users, removalKeys)
        } else if let mock = establishGroupForWithRemovalKeys_MockValue {
            return mock
        } else {
            fatalError("no mock for `establishGroupForWithRemovalKeys`")
        }
    }

    // MARK: - establishPendingGroup

    public var establishPendingGroupGroupID_Invocations: [MLSGroupID] = []
    public var establishPendingGroupGroupID_MockError: Error?
    public var establishPendingGroupGroupID_MockMethod: ((MLSGroupID) async throws -> Void)?

    public func establishPendingGroup(groupID: MLSGroupID) async throws {
        establishPendingGroupGroupID_Invocations.append(groupID)

        if let error = establishPendingGroupGroupID_MockError {
            throw error
        }

        guard let mock = establishPendingGroupGroupID_MockMethod else {
            fatalError("no mock for `establishPendingGroupGroupID`")
        }

        try await mock(groupID)
    }

    // MARK: - joinGroup

    public var joinGroupWith_Invocations: [MLSGroupID] = []
    public var joinGroupWith_MockError: Error?
    public var joinGroupWith_MockMethod: ((MLSGroupID) async throws -> Void)?

    public func joinGroup(with groupID: MLSGroupID) async throws {
        joinGroupWith_Invocations.append(groupID)

        if let error = joinGroupWith_MockError {
            throw error
        }

        guard let mock = joinGroupWith_MockMethod else {
            fatalError("no mock for `joinGroupWith`")
        }

        try await mock(groupID)
    }

    // MARK: - joinNewGroup

    public var joinNewGroupWith_Invocations: [MLSGroupID] = []
    public var joinNewGroupWith_MockError: Error?
    public var joinNewGroupWith_MockMethod: ((MLSGroupID) async throws -> Void)?

    public func joinNewGroup(with groupID: MLSGroupID) async throws {
        joinNewGroupWith_Invocations.append(groupID)

        if let error = joinNewGroupWith_MockError {
            throw error
        }

        guard let mock = joinNewGroupWith_MockMethod else {
            fatalError("no mock for `joinNewGroupWith`")
        }

        try await mock(groupID)
    }

    // MARK: - performPendingJoins

    public var performPendingJoins_Invocations: [Void] = []
    public var performPendingJoins_MockError: Error?
    public var performPendingJoins_MockMethod: (() async throws -> Void)?

    public func performPendingJoins() async throws {
        performPendingJoins_Invocations.append(())

        if let error = performPendingJoins_MockError {
            throw error
        }

        guard let mock = performPendingJoins_MockMethod else {
            fatalError("no mock for `performPendingJoins`")
        }

        try await mock()
    }

    // MARK: - recoverPendingConversationBatchIfNeeded

    public var recoverPendingConversationBatchIfNeeded_Invocations: [Void] = []
    public var recoverPendingConversationBatchIfNeeded_MockMethod: (() async -> Bool)?
    public var recoverPendingConversationBatchIfNeeded_MockValue: Bool?

    public func recoverPendingConversationBatchIfNeeded() async -> Bool {
        recoverPendingConversationBatchIfNeeded_Invocations.append(())

        if let mock = recoverPendingConversationBatchIfNeeded_MockMethod {
            return await mock()
        } else if let mock = recoverPendingConversationBatchIfNeeded_MockValue {
            return mock
        } else {
            fatalError("no mock for `recoverPendingConversationBatchIfNeeded`")
        }
    }

    // MARK: - wipeGroup

    public var wipeGroup_Invocations: [MLSGroupID] = []
    public var wipeGroup_MockError: Error?
    public var wipeGroup_MockMethod: ((MLSGroupID) async throws -> Void)?

    public func wipeGroup(_ groupID: MLSGroupID) async throws {
        wipeGroup_Invocations.append(groupID)

        if let error = wipeGroup_MockError {
            throw error
        }

        guard let mock = wipeGroup_MockMethod else {
            fatalError("no mock for `wipeGroup`")
        }

        try await mock(groupID)
    }

    // MARK: - externalSenderKey

    public var externalSenderKeyGroupID_Invocations: [MLSGroupID] = []
    public var externalSenderKeyGroupID_MockError: Error?
    public var externalSenderKeyGroupID_MockMethod: ((MLSGroupID) async throws -> Data)?
    public var externalSenderKeyGroupID_MockValue: Data?

    public func externalSenderKey(groupID: MLSGroupID) async throws -> Data {
        externalSenderKeyGroupID_Invocations.append(groupID)

        if let error = externalSenderKeyGroupID_MockError {
            throw error
        }

        if let mock = externalSenderKeyGroupID_MockMethod {
            return try await mock(groupID)
        } else if let mock = externalSenderKeyGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `externalSenderKeyGroupID`")
        }
    }

    // MARK: - conversationExists

    public var conversationExistsGroupID_Invocations: [MLSGroupID] = []
    public var conversationExistsGroupID_MockError: Error?
    public var conversationExistsGroupID_MockMethod: ((MLSGroupID) async throws -> Bool)?
    public var conversationExistsGroupID_MockValue: Bool?

    public func conversationExists(groupID: MLSGroupID) async throws -> Bool {
        conversationExistsGroupID_Invocations.append(groupID)

        if let error = conversationExistsGroupID_MockError {
            throw error
        }

        if let mock = conversationExistsGroupID_MockMethod {
            return try await mock(groupID)
        } else if let mock = conversationExistsGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationExistsGroupID`")
        }
    }

    // MARK: - addMembersToConversation

    public var addMembersToConversationWithFor_Invocations: [(users: [MLSUser], groupID: MLSGroupID)] = []
    public var addMembersToConversationWithFor_MockError: Error?
    public var addMembersToConversationWithFor_MockMethod: (([MLSUser], MLSGroupID) async throws -> Void)?

    public func addMembersToConversation(with users: [MLSUser], for groupID: MLSGroupID) async throws {
        addMembersToConversationWithFor_Invocations.append((users: users, groupID: groupID))

        if let error = addMembersToConversationWithFor_MockError {
            throw error
        }

        guard let mock = addMembersToConversationWithFor_MockMethod else {
            fatalError("no mock for `addMembersToConversationWithFor`")
        }

        try await mock(users, groupID)
    }

    // MARK: - removeMembersFromConversation

    public var removeMembersFromConversationWithFor_Invocations: [(clientIds: [MLSClientID], groupID: MLSGroupID)] = []
    public var removeMembersFromConversationWithFor_MockError: Error?
    public var removeMembersFromConversationWithFor_MockMethod: (([MLSClientID], MLSGroupID) async throws -> Void)?

    public func removeMembersFromConversation(with clientIds: [MLSClientID], for groupID: MLSGroupID) async throws {
        removeMembersFromConversationWithFor_Invocations.append((clientIds: clientIds, groupID: groupID))

        if let error = removeMembersFromConversationWithFor_MockError {
            throw error
        }

        guard let mock = removeMembersFromConversationWithFor_MockMethod else {
            fatalError("no mock for `removeMembersFromConversationWithFor`")
        }

        try await mock(clientIds, groupID)
    }

    // MARK: - createOrJoinSubgroup

    public var createOrJoinSubgroupParentQualifiedIDParentID_Invocations: [(parentQualifiedID: QualifiedID, parentID: MLSGroupID)] = []
    public var createOrJoinSubgroupParentQualifiedIDParentID_MockError: Error?
    public var createOrJoinSubgroupParentQualifiedIDParentID_MockMethod: ((QualifiedID, MLSGroupID) async throws -> MLSGroupID)?
    public var createOrJoinSubgroupParentQualifiedIDParentID_MockValue: MLSGroupID?

    public func createOrJoinSubgroup(parentQualifiedID: QualifiedID, parentID: MLSGroupID) async throws -> MLSGroupID {
        createOrJoinSubgroupParentQualifiedIDParentID_Invocations.append((parentQualifiedID: parentQualifiedID, parentID: parentID))

        if let error = createOrJoinSubgroupParentQualifiedIDParentID_MockError {
            throw error
        }

        if let mock = createOrJoinSubgroupParentQualifiedIDParentID_MockMethod {
            return try await mock(parentQualifiedID, parentID)
        } else if let mock = createOrJoinSubgroupParentQualifiedIDParentID_MockValue {
            return mock
        } else {
            fatalError("no mock for `createOrJoinSubgroupParentQualifiedIDParentID`")
        }
    }

    // MARK: - conferenceSubconversation

    public var conferenceSubconversationParentGroupID_Invocations: [MLSGroupID] = []
    public var conferenceSubconversationParentGroupID_MockMethod: ((MLSGroupID) async -> MLSGroupID?)?
    public var conferenceSubconversationParentGroupID_MockValue: MLSGroupID??

    public func conferenceSubconversation(parentGroupID: MLSGroupID) async -> MLSGroupID? {
        conferenceSubconversationParentGroupID_Invocations.append(parentGroupID)

        if let mock = conferenceSubconversationParentGroupID_MockMethod {
            return await mock(parentGroupID)
        } else if let mock = conferenceSubconversationParentGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `conferenceSubconversationParentGroupID`")
        }
    }

    // MARK: - leaveSubconversation

    public var leaveSubconversationParentQualifiedIDParentGroupIDSubconversationType_Invocations: [(parentQualifiedID: QualifiedID, parentGroupID: MLSGroupID, subconversationType: SubgroupType)] = []
    public var leaveSubconversationParentQualifiedIDParentGroupIDSubconversationType_MockError: Error?
    public var leaveSubconversationParentQualifiedIDParentGroupIDSubconversationType_MockMethod: ((QualifiedID, MLSGroupID, SubgroupType) async throws -> Void)?

    public func leaveSubconversation(parentQualifiedID: QualifiedID, parentGroupID: MLSGroupID, subconversationType: SubgroupType) async throws {
        leaveSubconversationParentQualifiedIDParentGroupIDSubconversationType_Invocations.append((parentQualifiedID: parentQualifiedID, parentGroupID: parentGroupID, subconversationType: subconversationType))

        if let error = leaveSubconversationParentQualifiedIDParentGroupIDSubconversationType_MockError {
            throw error
        }

        guard let mock = leaveSubconversationParentQualifiedIDParentGroupIDSubconversationType_MockMethod else {
            fatalError("no mock for `leaveSubconversationParentQualifiedIDParentGroupIDSubconversationType`")
        }

        try await mock(parentQualifiedID, parentGroupID, subconversationType)
    }

    // MARK: - leaveSubconversationIfNeeded

    public var leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID_Invocations: [(parentQualifiedID: QualifiedID, parentGroupID: MLSGroupID, subconversationType: SubgroupType, selfClientID: MLSClientID)] = []
    public var leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID_MockError: Error?
    public var leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID_MockMethod: ((QualifiedID, MLSGroupID, SubgroupType, MLSClientID) async throws -> Void)?

    public func leaveSubconversationIfNeeded(parentQualifiedID: QualifiedID, parentGroupID: MLSGroupID, subconversationType: SubgroupType, selfClientID: MLSClientID) async throws {
        leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID_Invocations.append((parentQualifiedID: parentQualifiedID, parentGroupID: parentGroupID, subconversationType: subconversationType, selfClientID: selfClientID))

        if let error = leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID_MockError {
            throw error
        }

        guard let mock = leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID_MockMethod else {
            fatalError("no mock for `leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID`")
        }

        try await mock(parentQualifiedID, parentGroupID, subconversationType, selfClientID)
    }

    // MARK: - deleteSubgroup

    public var deleteSubgroupParentQualifiedID_Invocations: [QualifiedID] = []
    public var deleteSubgroupParentQualifiedID_MockError: Error?
    public var deleteSubgroupParentQualifiedID_MockMethod: ((QualifiedID) async throws -> Void)?

    public func deleteSubgroup(parentQualifiedID: QualifiedID) async throws {
        deleteSubgroupParentQualifiedID_Invocations.append(parentQualifiedID)

        if let error = deleteSubgroupParentQualifiedID_MockError {
            throw error
        }

        guard let mock = deleteSubgroupParentQualifiedID_MockMethod else {
            fatalError("no mock for `deleteSubgroupParentQualifiedID`")
        }

        try await mock(parentQualifiedID)
    }

    // MARK: - subconversationMembers

    public var subconversationMembersFor_Invocations: [MLSGroupID] = []
    public var subconversationMembersFor_MockError: Error?
    public var subconversationMembersFor_MockMethod: ((MLSGroupID) async throws -> [MLSClientID])?
    public var subconversationMembersFor_MockValue: [MLSClientID]?

    public func subconversationMembers(for subconversationGroupID: MLSGroupID) async throws -> [MLSClientID] {
        subconversationMembersFor_Invocations.append(subconversationGroupID)

        if let error = subconversationMembersFor_MockError {
            throw error
        }

        if let mock = subconversationMembersFor_MockMethod {
            return try await mock(subconversationGroupID)
        } else if let mock = subconversationMembersFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `subconversationMembersFor`")
        }
    }

    // MARK: - commitPendingProposals

    public var commitPendingProposalsIn_Invocations: [MLSGroupID] = []
    public var commitPendingProposalsIn_MockError: Error?
    public var commitPendingProposalsIn_MockMethod: ((MLSGroupID) async throws -> Void)?

    public func commitPendingProposals(in groupID: MLSGroupID) async throws {
        commitPendingProposalsIn_Invocations.append(groupID)

        if let error = commitPendingProposalsIn_MockError {
            throw error
        }

        guard let mock = commitPendingProposalsIn_MockMethod else {
            fatalError("no mock for `commitPendingProposalsIn`")
        }

        try await mock(groupID)
    }

    // MARK: - commitPendingProposals

    public var commitPendingProposalsInSkipRetry_Invocations: [(groupID: MLSGroupID, skipRetry: Bool)] = []
    public var commitPendingProposalsInSkipRetry_MockError: Error?
    public var commitPendingProposalsInSkipRetry_MockMethod: ((MLSGroupID, Bool) async throws -> Void)?

    public func commitPendingProposals(in groupID: MLSGroupID, skipRetry: Bool) async throws {
        commitPendingProposalsInSkipRetry_Invocations.append((groupID: groupID, skipRetry: skipRetry))

        if let error = commitPendingProposalsInSkipRetry_MockError {
            throw error
        }

        guard let mock = commitPendingProposalsInSkipRetry_MockMethod else {
            fatalError("no mock for `commitPendingProposalsInSkipRetry`")
        }

        try await mock(groupID, skipRetry)
    }

    // MARK: - updateKeyMaterialForAllStaleGroupsIfNeeded

    public var updateKeyMaterialForAllStaleGroupsIfNeeded_Invocations: [Void] = []
    public var updateKeyMaterialForAllStaleGroupsIfNeeded_MockMethod: (() async -> Void)?

    public func updateKeyMaterialForAllStaleGroupsIfNeeded() async {
        updateKeyMaterialForAllStaleGroupsIfNeeded_Invocations.append(())

        guard let mock = updateKeyMaterialForAllStaleGroupsIfNeeded_MockMethod else {
            fatalError("no mock for `updateKeyMaterialForAllStaleGroupsIfNeeded`")
        }

        await mock()
    }

    // MARK: - uploadKeyPackagesIfNeeded

    public var uploadKeyPackagesIfNeeded_Invocations: [Void] = []
    public var uploadKeyPackagesIfNeeded_MockMethod: (() async -> Void)?

    public func uploadKeyPackagesIfNeeded() async {
        uploadKeyPackagesIfNeeded_Invocations.append(())

        guard let mock = uploadKeyPackagesIfNeeded_MockMethod else {
            fatalError("no mock for `uploadKeyPackagesIfNeeded`")
        }

        await mock()
    }

    // MARK: - repairOutOfSyncConversations

    public var repairOutOfSyncConversations_Invocations: [Void] = []
    public var repairOutOfSyncConversations_MockError: Error?
    public var repairOutOfSyncConversations_MockMethod: (() async throws -> Void)?

    public func repairOutOfSyncConversations() async throws {
        repairOutOfSyncConversations_Invocations.append(())

        if let error = repairOutOfSyncConversations_MockError {
            throw error
        }

        guard let mock = repairOutOfSyncConversations_MockMethod else {
            fatalError("no mock for `repairOutOfSyncConversations`")
        }

        try await mock()
    }

    // MARK: - fetchAndRepairGroup

    public var fetchAndRepairGroupWith_Invocations: [MLSGroupID] = []
    public var fetchAndRepairGroupWith_MockMethod: ((MLSGroupID) async -> Void)?

    public func fetchAndRepairGroup(with groupID: MLSGroupID) async {
        fetchAndRepairGroupWith_Invocations.append(groupID)

        guard let mock = fetchAndRepairGroupWith_MockMethod else {
            fatalError("no mock for `fetchAndRepairGroupWith`")
        }

        await mock(groupID)
    }

    // MARK: - epochChanges

    public var epochChanges_Invocations: [Void] = []
    public var epochChanges_MockMethod: (() -> AsyncStream<MLSGroupID>)?
    public var epochChanges_MockValue: AsyncStream<MLSGroupID>?

    public func epochChanges() -> AsyncStream<MLSGroupID> {
        epochChanges_Invocations.append(())

        if let mock = epochChanges_MockMethod {
            return mock()
        } else if let mock = epochChanges_MockValue {
            return mock
        } else {
            fatalError("no mock for `epochChanges`")
        }
    }

    // MARK: - generateConferenceInfo

    public var generateConferenceInfoParentGroupIDSubconversationGroupID_Invocations: [(parentGroupID: MLSGroupID, subconversationGroupID: MLSGroupID)] = []
    public var generateConferenceInfoParentGroupIDSubconversationGroupID_MockError: Error?
    public var generateConferenceInfoParentGroupIDSubconversationGroupID_MockMethod: ((MLSGroupID, MLSGroupID) async throws -> MLSConferenceInfo)?
    public var generateConferenceInfoParentGroupIDSubconversationGroupID_MockValue: MLSConferenceInfo?

    public func generateConferenceInfo(parentGroupID: MLSGroupID, subconversationGroupID: MLSGroupID) async throws -> MLSConferenceInfo {
        generateConferenceInfoParentGroupIDSubconversationGroupID_Invocations.append((parentGroupID: parentGroupID, subconversationGroupID: subconversationGroupID))

        if let error = generateConferenceInfoParentGroupIDSubconversationGroupID_MockError {
            throw error
        }

        if let mock = generateConferenceInfoParentGroupIDSubconversationGroupID_MockMethod {
            return try await mock(parentGroupID, subconversationGroupID)
        } else if let mock = generateConferenceInfoParentGroupIDSubconversationGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `generateConferenceInfoParentGroupIDSubconversationGroupID`")
        }
    }

    // MARK: - onConferenceInfoChange

    public var onConferenceInfoChangeParentGroupIDSubConversationGroupID_Invocations: [(parentGroupID: MLSGroupID, subConversationGroupID: MLSGroupID)] = []
    public var onConferenceInfoChangeParentGroupIDSubConversationGroupID_MockMethod: ((MLSGroupID, MLSGroupID) -> AsyncThrowingStream<MLSConferenceInfo, Error>)?
    public var onConferenceInfoChangeParentGroupIDSubConversationGroupID_MockValue: AsyncThrowingStream<MLSConferenceInfo, Error>?

    public func onConferenceInfoChange(parentGroupID: MLSGroupID, subConversationGroupID: MLSGroupID) -> AsyncThrowingStream<MLSConferenceInfo, Error> {
        onConferenceInfoChangeParentGroupIDSubConversationGroupID_Invocations.append((parentGroupID: parentGroupID, subConversationGroupID: subConversationGroupID))

        if let mock = onConferenceInfoChangeParentGroupIDSubConversationGroupID_MockMethod {
            return mock(parentGroupID, subConversationGroupID)
        } else if let mock = onConferenceInfoChangeParentGroupIDSubConversationGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `onConferenceInfoChangeParentGroupIDSubConversationGroupID`")
        }
    }

    // MARK: - startProteusToMLSMigration

    public var startProteusToMLSMigration_Invocations: [Void] = []
    public var startProteusToMLSMigration_MockError: Error?
    public var startProteusToMLSMigration_MockMethod: (() async throws -> Void)?

    public func startProteusToMLSMigration() async throws {
        startProteusToMLSMigration_Invocations.append(())

        if let error = startProteusToMLSMigration_MockError {
            throw error
        }

        guard let mock = startProteusToMLSMigration_MockMethod else {
            fatalError("no mock for `startProteusToMLSMigration`")
        }

        try await mock()
    }

    // MARK: - reEstablishPendingGroup

    public var reEstablishPendingGroupGroupID_Invocations: [MLSGroupID] = []
    public var reEstablishPendingGroupGroupID_MockError: Error?
    public var reEstablishPendingGroupGroupID_MockMethod: ((MLSGroupID) async throws -> Void)?

    public func reEstablishPendingGroup(groupID: MLSGroupID) async throws {
        reEstablishPendingGroupGroupID_Invocations.append(groupID)

        if let error = reEstablishPendingGroupGroupID_MockError {
            throw error
        }

        guard let mock = reEstablishPendingGroupGroupID_MockMethod else {
            fatalError("no mock for `reEstablishPendingGroupGroupID`")
        }

        try await mock(groupID)
    }

    // MARK: - epoch

    public var epochFor_Invocations: [MLSGroupID] = []
    public var epochFor_MockError: Error?
    public var epochFor_MockMethod: ((MLSGroupID) async throws -> UInt64)?
    public var epochFor_MockValue: UInt64?

    public func epoch(for groupID: MLSGroupID) async throws -> UInt64 {
        epochFor_Invocations.append(groupID)

        if let error = epochFor_MockError {
            throw error
        }

        if let mock = epochFor_MockMethod {
            return try await mock(groupID)
        } else if let mock = epochFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `epochFor`")
        }
    }

    // MARK: - setResetBrokenMLSConversationDelegate

    public var setResetBrokenMLSConversationDelegate_Invocations: [any ResetBrokenMLSConversationDelegate] = []
    public var setResetBrokenMLSConversationDelegate_MockMethod: ((any ResetBrokenMLSConversationDelegate) -> Void)?

    public func setResetBrokenMLSConversationDelegate(_ delegate: any ResetBrokenMLSConversationDelegate) {
        setResetBrokenMLSConversationDelegate_Invocations.append(delegate)

        guard let mock = setResetBrokenMLSConversationDelegate_MockMethod else {
            fatalError("no mock for `setResetBrokenMLSConversationDelegate`")
        }

        mock(delegate)
    }

    // MARK: - decrypt

    public var decryptMessageForSubconversationTypeContext_Invocations: [(message: String, groupID: MLSGroupID, subconversationType: SubgroupType?, context: CoreCryptoContextProtocol?)] = []
    public var decryptMessageForSubconversationTypeContext_MockError: Error?
    public var decryptMessageForSubconversationTypeContext_MockMethod: ((String, MLSGroupID, SubgroupType?, CoreCryptoContextProtocol?) async throws -> [MLSDecryptResult])?
    public var decryptMessageForSubconversationTypeContext_MockValue: [MLSDecryptResult]?

    public func decrypt(message: String, for groupID: MLSGroupID, subconversationType: SubgroupType?, context: CoreCryptoContextProtocol?) async throws -> [MLSDecryptResult] {
        decryptMessageForSubconversationTypeContext_Invocations.append((message: message, groupID: groupID, subconversationType: subconversationType, context: context))

        if let error = decryptMessageForSubconversationTypeContext_MockError {
            throw error
        }

        if let mock = decryptMessageForSubconversationTypeContext_MockMethod {
            return try await mock(message, groupID, subconversationType, context)
        } else if let mock = decryptMessageForSubconversationTypeContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptMessageForSubconversationTypeContext`")
        }
    }

    // MARK: - processWelcomeMessage

    public var processWelcomeMessageWelcomeMessageContext_Invocations: [(welcomeMessage: String, context: CoreCryptoContextProtocol?)] = []
    public var processWelcomeMessageWelcomeMessageContext_MockError: Error?
    public var processWelcomeMessageWelcomeMessageContext_MockMethod: ((String, CoreCryptoContextProtocol?) async throws -> MLSGroupID)?
    public var processWelcomeMessageWelcomeMessageContext_MockValue: MLSGroupID?

    public func processWelcomeMessage(welcomeMessage: String, context: CoreCryptoContextProtocol?) async throws -> MLSGroupID {
        processWelcomeMessageWelcomeMessageContext_Invocations.append((welcomeMessage: welcomeMessage, context: context))

        if let error = processWelcomeMessageWelcomeMessageContext_MockError {
            throw error
        }

        if let mock = processWelcomeMessageWelcomeMessageContext_MockMethod {
            return try await mock(welcomeMessage, context)
        } else if let mock = processWelcomeMessageWelcomeMessageContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `processWelcomeMessageWelcomeMessageContext`")
        }
    }

    // MARK: - encrypt

    public var encryptMessageFor_Invocations: [(message: Data, groupID: MLSGroupID)] = []
    public var encryptMessageFor_MockError: Error?
    public var encryptMessageFor_MockMethod: ((Data, MLSGroupID) async throws -> Data)?
    public var encryptMessageFor_MockValue: Data?

    public func encrypt(message: Data, for groupID: MLSGroupID) async throws -> Data {
        encryptMessageFor_Invocations.append((message: message, groupID: groupID))

        if let error = encryptMessageFor_MockError {
            throw error
        }

        if let mock = encryptMessageFor_MockMethod {
            return try await mock(message, groupID)
        } else if let mock = encryptMessageFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `encryptMessageFor`")
        }
    }

}

public class MockOneOnOneMigratorInterface: OneOnOneMigratorInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - migrateToMLS

    public var migrateToMLSUserIDIn_Invocations: [(userID: QualifiedID, context: NSManagedObjectContext)] = []
    public var migrateToMLSUserIDIn_MockError: Error?
    public var migrateToMLSUserIDIn_MockMethod: ((QualifiedID, NSManagedObjectContext) async throws -> MLSGroupID)?
    public var migrateToMLSUserIDIn_MockValue: MLSGroupID?

    @discardableResult
    public func migrateToMLS(userID: QualifiedID, in context: NSManagedObjectContext) async throws -> MLSGroupID {
        migrateToMLSUserIDIn_Invocations.append((userID: userID, context: context))

        if let error = migrateToMLSUserIDIn_MockError {
            throw error
        }

        if let mock = migrateToMLSUserIDIn_MockMethod {
            return try await mock(userID, context)
        } else if let mock = migrateToMLSUserIDIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `migrateToMLSUserIDIn`")
        }
    }

}

public class MockOneOnOneProtocolSelectorInterface: OneOnOneProtocolSelectorInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - getProtocolForUser

    public var getProtocolForUserWithIn_Invocations: [(id: QualifiedID, context: NSManagedObjectContext)] = []
    public var getProtocolForUserWithIn_MockError: Error?
    public var getProtocolForUserWithIn_MockMethod: ((QualifiedID, NSManagedObjectContext) async throws -> MessageProtocol?)?
    public var getProtocolForUserWithIn_MockValue: MessageProtocol??

    public func getProtocolForUser(with id: QualifiedID, in context: NSManagedObjectContext) async throws -> MessageProtocol? {
        getProtocolForUserWithIn_Invocations.append((id: id, context: context))

        if let error = getProtocolForUserWithIn_MockError {
            throw error
        }

        if let mock = getProtocolForUserWithIn_MockMethod {
            return try await mock(id, context)
        } else if let mock = getProtocolForUserWithIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `getProtocolForUserWithIn`")
        }
    }

}

public class MockOneOnOneResolverInterface: OneOnOneResolverInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - resolveAllOneOnOneConversations

    public var resolveAllOneOnOneConversationsIn_Invocations: [NSManagedObjectContext] = []
    public var resolveAllOneOnOneConversationsIn_MockError: Error?
    public var resolveAllOneOnOneConversationsIn_MockMethod: ((NSManagedObjectContext) async throws -> Void)?

    public func resolveAllOneOnOneConversations(in context: NSManagedObjectContext) async throws {
        resolveAllOneOnOneConversationsIn_Invocations.append(context)

        if let error = resolveAllOneOnOneConversationsIn_MockError {
            throw error
        }

        guard let mock = resolveAllOneOnOneConversationsIn_MockMethod else {
            fatalError("no mock for `resolveAllOneOnOneConversationsIn`")
        }

        try await mock(context)
    }

    // MARK: - resolveOneOnOneConversation

    public var resolveOneOnOneConversationWithIn_Invocations: [(userID: QualifiedID, context: NSManagedObjectContext)] = []
    public var resolveOneOnOneConversationWithIn_MockError: Error?
    public var resolveOneOnOneConversationWithIn_MockMethod: ((QualifiedID, NSManagedObjectContext) async throws -> OneOnOneConversationResolution)?
    public var resolveOneOnOneConversationWithIn_MockValue: OneOnOneConversationResolution?

    @discardableResult
    public func resolveOneOnOneConversation(with userID: QualifiedID, in context: NSManagedObjectContext) async throws -> OneOnOneConversationResolution {
        resolveOneOnOneConversationWithIn_Invocations.append((userID: userID, context: context))

        if let error = resolveOneOnOneConversationWithIn_MockError {
            throw error
        }

        if let mock = resolveOneOnOneConversationWithIn_MockMethod {
            return try await mock(userID, context)
        } else if let mock = resolveOneOnOneConversationWithIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `resolveOneOnOneConversationWithIn`")
        }
    }

}

public class MockProteusServiceInterface: ProteusServiceInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - lastPrekeyID

    public var lastPrekeyIDCallsCount = 0
    public var lastPrekeyIDCalled: Bool {
        return lastPrekeyIDCallsCount > 0
    }

    public var lastPrekeyID: UInt16 {
        get async {
            lastPrekeyIDCallsCount += 1
            if let lastPrekeyIDClosure {
                return await lastPrekeyIDClosure()
            } else {
                return underlyingLastPrekeyID
            }
        }
    }
    public var underlyingLastPrekeyID: UInt16!
    public var lastPrekeyIDClosure: (() async -> UInt16)?


    // MARK: - establishSession

    public var establishSessionIdFromPrekey_Invocations: [(id: ProteusSessionID, fromPrekey: String)] = []
    public var establishSessionIdFromPrekey_MockError: Error?
    public var establishSessionIdFromPrekey_MockMethod: ((ProteusSessionID, String) async throws -> Void)?

    public func establishSession(id: ProteusSessionID, fromPrekey: String) async throws {
        establishSessionIdFromPrekey_Invocations.append((id: id, fromPrekey: fromPrekey))

        if let error = establishSessionIdFromPrekey_MockError {
            throw error
        }

        guard let mock = establishSessionIdFromPrekey_MockMethod else {
            fatalError("no mock for `establishSessionIdFromPrekey`")
        }

        try await mock(id, fromPrekey)
    }

    // MARK: - deleteSession

    public var deleteSessionId_Invocations: [ProteusSessionID] = []
    public var deleteSessionId_MockError: Error?
    public var deleteSessionId_MockMethod: ((ProteusSessionID) async throws -> Void)?

    public func deleteSession(id: ProteusSessionID) async throws {
        deleteSessionId_Invocations.append(id)

        if let error = deleteSessionId_MockError {
            throw error
        }

        guard let mock = deleteSessionId_MockMethod else {
            fatalError("no mock for `deleteSessionId`")
        }

        try await mock(id)
    }

    // MARK: - sessionExists

    public var sessionExistsId_Invocations: [ProteusSessionID] = []
    public var sessionExistsId_MockMethod: ((ProteusSessionID) async -> Bool)?
    public var sessionExistsId_MockValue: Bool?

    public func sessionExists(id: ProteusSessionID) async -> Bool {
        sessionExistsId_Invocations.append(id)

        if let mock = sessionExistsId_MockMethod {
            return await mock(id)
        } else if let mock = sessionExistsId_MockValue {
            return mock
        } else {
            fatalError("no mock for `sessionExistsId`")
        }
    }

    // MARK: - encrypt

    public var encryptDataForSession_Invocations: [(data: Data, id: ProteusSessionID)] = []
    public var encryptDataForSession_MockError: Error?
    public var encryptDataForSession_MockMethod: ((Data, ProteusSessionID) async throws -> Data)?
    public var encryptDataForSession_MockValue: Data?

    public func encrypt(data: Data, forSession id: ProteusSessionID) async throws -> Data {
        encryptDataForSession_Invocations.append((data: data, id: id))

        if let error = encryptDataForSession_MockError {
            throw error
        }

        if let mock = encryptDataForSession_MockMethod {
            return try await mock(data, id)
        } else if let mock = encryptDataForSession_MockValue {
            return mock
        } else {
            fatalError("no mock for `encryptDataForSession`")
        }
    }

    // MARK: - encryptBatched

    public var encryptBatchedDataForSessions_Invocations: [(data: Data, sessions: [ProteusSessionID])] = []
    public var encryptBatchedDataForSessions_MockError: Error?
    public var encryptBatchedDataForSessions_MockMethod: ((Data, [ProteusSessionID]) async throws -> [String: Data])?
    public var encryptBatchedDataForSessions_MockValue: [String: Data]?

    public func encryptBatched(data: Data, forSessions sessions: [ProteusSessionID]) async throws -> [String: Data] {
        encryptBatchedDataForSessions_Invocations.append((data: data, sessions: sessions))

        if let error = encryptBatchedDataForSessions_MockError {
            throw error
        }

        if let mock = encryptBatchedDataForSessions_MockMethod {
            return try await mock(data, sessions)
        } else if let mock = encryptBatchedDataForSessions_MockValue {
            return mock
        } else {
            fatalError("no mock for `encryptBatchedDataForSessions`")
        }
    }

    // MARK: - decrypt

    public var decryptDataForSessionContext_Invocations: [(data: Data, id: ProteusSessionID, context: CoreCryptoContextProtocol?)] = []
    public var decryptDataForSessionContext_MockError: Error?
    public var decryptDataForSessionContext_MockMethod: ((Data, ProteusSessionID, CoreCryptoContextProtocol?) async throws -> (didCreateNewSession: Bool, decryptedData: Data))?
    public var decryptDataForSessionContext_MockValue: (didCreateNewSession: Bool, decryptedData: Data)?

    public func decrypt(data: Data, forSession id: ProteusSessionID, context: CoreCryptoContextProtocol?) async throws -> (didCreateNewSession: Bool, decryptedData: Data) {
        decryptDataForSessionContext_Invocations.append((data: data, id: id, context: context))

        if let error = decryptDataForSessionContext_MockError {
            throw error
        }

        if let mock = decryptDataForSessionContext_MockMethod {
            return try await mock(data, id, context)
        } else if let mock = decryptDataForSessionContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptDataForSessionContext`")
        }
    }

    // MARK: - generatePrekey

    public var generatePrekeyId_Invocations: [UInt16] = []
    public var generatePrekeyId_MockError: Error?
    public var generatePrekeyId_MockMethod: ((UInt16) async throws -> String)?
    public var generatePrekeyId_MockValue: String?

    public func generatePrekey(id: UInt16) async throws -> String {
        generatePrekeyId_Invocations.append(id)

        if let error = generatePrekeyId_MockError {
            throw error
        }

        if let mock = generatePrekeyId_MockMethod {
            return try await mock(id)
        } else if let mock = generatePrekeyId_MockValue {
            return mock
        } else {
            fatalError("no mock for `generatePrekeyId`")
        }
    }

    // MARK: - lastPrekey

    public var lastPrekey_Invocations: [Void] = []
    public var lastPrekey_MockError: Error?
    public var lastPrekey_MockMethod: (() async throws -> String)?
    public var lastPrekey_MockValue: String?

    public func lastPrekey() async throws -> String {
        lastPrekey_Invocations.append(())

        if let error = lastPrekey_MockError {
            throw error
        }

        if let mock = lastPrekey_MockMethod {
            return try await mock()
        } else if let mock = lastPrekey_MockValue {
            return mock
        } else {
            fatalError("no mock for `lastPrekey`")
        }
    }

    // MARK: - generatePrekeys

    public var generatePrekeysStartCount_Invocations: [(start: UInt16, count: UInt16)] = []
    public var generatePrekeysStartCount_MockError: Error?
    public var generatePrekeysStartCount_MockMethod: ((UInt16, UInt16) async throws -> [IdPrekeyTuple])?
    public var generatePrekeysStartCount_MockValue: [IdPrekeyTuple]?

    public func generatePrekeys(start: UInt16, count: UInt16) async throws -> [IdPrekeyTuple] {
        generatePrekeysStartCount_Invocations.append((start: start, count: count))

        if let error = generatePrekeysStartCount_MockError {
            throw error
        }

        if let mock = generatePrekeysStartCount_MockMethod {
            return try await mock(start, count)
        } else if let mock = generatePrekeysStartCount_MockValue {
            return mock
        } else {
            fatalError("no mock for `generatePrekeysStartCount`")
        }
    }

    // MARK: - localFingerprint

    public var localFingerprint_Invocations: [Void] = []
    public var localFingerprint_MockError: Error?
    public var localFingerprint_MockMethod: (() async throws -> String)?
    public var localFingerprint_MockValue: String?

    public func localFingerprint() async throws -> String {
        localFingerprint_Invocations.append(())

        if let error = localFingerprint_MockError {
            throw error
        }

        if let mock = localFingerprint_MockMethod {
            return try await mock()
        } else if let mock = localFingerprint_MockValue {
            return mock
        } else {
            fatalError("no mock for `localFingerprint`")
        }
    }

    // MARK: - remoteFingerprint

    public var remoteFingerprintForSession_Invocations: [ProteusSessionID] = []
    public var remoteFingerprintForSession_MockError: Error?
    public var remoteFingerprintForSession_MockMethod: ((ProteusSessionID) async throws -> String)?
    public var remoteFingerprintForSession_MockValue: String?

    public func remoteFingerprint(forSession id: ProteusSessionID) async throws -> String {
        remoteFingerprintForSession_Invocations.append(id)

        if let error = remoteFingerprintForSession_MockError {
            throw error
        }

        if let mock = remoteFingerprintForSession_MockMethod {
            return try await mock(id)
        } else if let mock = remoteFingerprintForSession_MockValue {
            return mock
        } else {
            fatalError("no mock for `remoteFingerprintForSession`")
        }
    }

    // MARK: - fingerprint

    public var fingerprintFromPrekey_Invocations: [String] = []
    public var fingerprintFromPrekey_MockError: Error?
    public var fingerprintFromPrekey_MockMethod: ((String) async throws -> String)?
    public var fingerprintFromPrekey_MockValue: String?

    public func fingerprint(fromPrekey prekey: String) async throws -> String {
        fingerprintFromPrekey_Invocations.append(prekey)

        if let error = fingerprintFromPrekey_MockError {
            throw error
        }

        if let mock = fingerprintFromPrekey_MockMethod {
            return try await mock(prekey)
        } else if let mock = fingerprintFromPrekey_MockValue {
            return mock
        } else {
            fatalError("no mock for `fingerprintFromPrekey`")
        }
    }

}

public class MockProteusToMLSMigrationCoordinating: ProteusToMLSMigrationCoordinating {

    // MARK: - Life cycle

    public init() {}


    // MARK: - updateMigrationStatus

    public var updateMigrationStatus_Invocations: [Void] = []
    public var updateMigrationStatus_MockError: Error?
    public var updateMigrationStatus_MockMethod: (() async throws -> Void)?

    public func updateMigrationStatus() async throws {
        updateMigrationStatus_Invocations.append(())

        if let error = updateMigrationStatus_MockError {
            throw error
        }

        guard let mock = updateMigrationStatus_MockMethod else {
            fatalError("no mock for `updateMigrationStatus`")
        }

        try await mock()
    }

}

class MockProteusToMLSMigrationStorageInterface: ProteusToMLSMigrationStorageInterface {

    // MARK: - Life cycle


    // MARK: - migrationStatus

    var migrationStatus: ProteusToMLSMigrationCoordinator.MigrationStatus {
        get { return underlyingMigrationStatus }
        set(value) { underlyingMigrationStatus = value }
    }

    var underlyingMigrationStatus: ProteusToMLSMigrationCoordinator.MigrationStatus!


}

public class MockRemoveCoreCryptoKeysUseCaseProtocol: RemoveCoreCryptoKeysUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invokeUserID_Invocations: [UUID] = []
    public var invokeUserID_MockError: Error?
    public var invokeUserID_MockMethod: ((UUID) throws -> Void)?

    public func invoke(userID: UUID) throws {
        invokeUserID_Invocations.append(userID)

        if let error = invokeUserID_MockError {
            throw error
        }

        guard let mock = invokeUserID_MockMethod else {
            fatalError("no mock for `invokeUserID`")
        }

        try mock(userID)
    }

}

public class MockRemoveEARKeysUseCaseProtocol: RemoveEARKeysUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invokeAccountID_Invocations: [UUID] = []
    public var invokeAccountID_MockMethod: ((UUID) -> Void)?

    public func invoke(accountID: UUID) {
        invokeAccountID_Invocations.append(accountID)

        guard let mock = invokeAccountID_MockMethod else {
            fatalError("no mock for `invokeAccountID`")
        }

        mock(accountID)
    }

}

public class MockResetBrokenMLSConversationDelegate: ResetBrokenMLSConversationDelegate {

    // MARK: - Life cycle

    public init() {}


    // MARK: - didCatchBrokenMLSConversation

    public var didCatchBrokenMLSConversationGroupIDEpoch_Invocations: [(groupID: MLSGroupID, epoch: UInt64)] = []
    public var didCatchBrokenMLSConversationGroupIDEpoch_MockMethod: ((MLSGroupID, UInt64) async -> Void)?

    public func didCatchBrokenMLSConversation(groupID: MLSGroupID, epoch: UInt64) async {
        didCatchBrokenMLSConversationGroupIDEpoch_Invocations.append((groupID: groupID, epoch: epoch))

        guard let mock = didCatchBrokenMLSConversationGroupIDEpoch_MockMethod else {
            fatalError("no mock for `didCatchBrokenMLSConversationGroupIDEpoch`")
        }

        await mock(groupID, epoch)
    }

}

public class MockStaleCoreCryptoKeysTrackerProtocol: StaleCoreCryptoKeysTrackerProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - addKey

    public var addKeyId_Invocations: [UUID] = []
    public var addKeyId_MockMethod: ((UUID) -> Void)?

    public func addKey(id: UUID) {
        addKeyId_Invocations.append(id)

        guard let mock = addKeyId_MockMethod else {
            fatalError("no mock for `addKeyId`")
        }

        mock(id)
    }

    // MARK: - getAll

    public var getAll_Invocations: [Void] = []
    public var getAll_MockMethod: (() -> [UUID])?
    public var getAll_MockValue: [UUID]?

    public func getAll() -> [UUID] {
        getAll_Invocations.append(())

        if let mock = getAll_MockMethod {
            return mock()
        } else if let mock = getAll_MockValue {
            return mock
        } else {
            fatalError("no mock for `getAll`")
        }
    }

    // MARK: - clear

    public var clear_Invocations: [Void] = []
    public var clear_MockMethod: (() -> Void)?

    public func clear() {
        clear_Invocations.append(())

        guard let mock = clear_MockMethod else {
            fatalError("no mock for `clear`")
        }

        mock()
    }

    // MARK: - removeKey

    public var removeKeyId_Invocations: [UUID] = []
    public var removeKeyId_MockMethod: ((UUID) -> Void)?

    public func removeKey(id: UUID) {
        removeKeyId_Invocations.append(id)

        guard let mock = removeKeyId_MockMethod else {
            fatalError("no mock for `removeKeyId`")
        }

        mock(id)
    }

}

public class MockStaleMLSKeyDetectorProtocol: StaleMLSKeyDetectorProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - refreshIntervalInDays

    public var refreshIntervalInDays: UInt {
        get { return underlyingRefreshIntervalInDays }
        set(value) { underlyingRefreshIntervalInDays = value }
    }

    public var underlyingRefreshIntervalInDays: UInt!

    // MARK: - groupsWithStaleKeyingMaterial

    public var groupsWithStaleKeyingMaterial: Set<MLSGroupID> {
        get { return underlyingGroupsWithStaleKeyingMaterial }
        set(value) { underlyingGroupsWithStaleKeyingMaterial = value }
    }

    public var underlyingGroupsWithStaleKeyingMaterial: Set<MLSGroupID>!


    // MARK: - keyingMaterialUpdated

    public var keyingMaterialUpdatedFor_Invocations: [MLSGroupID] = []
    public var keyingMaterialUpdatedFor_MockMethod: ((MLSGroupID) -> Void)?

    public func keyingMaterialUpdated(for groupID: MLSGroupID) {
        keyingMaterialUpdatedFor_Invocations.append(groupID)

        guard let mock = keyingMaterialUpdatedFor_MockMethod else {
            fatalError("no mock for `keyingMaterialUpdatedFor`")
        }

        mock(groupID)
    }

}

public class MockSubconversationGroupIDRepositoryInterface: SubconversationGroupIDRepositoryInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - storeSubconversationGroupID

    public var storeSubconversationGroupIDForTypeParentGroupID_Invocations: [(groupID: MLSGroupID?, type: SubgroupType, parentGroupID: MLSGroupID)] = []
    public var storeSubconversationGroupIDForTypeParentGroupID_MockMethod: ((MLSGroupID?, SubgroupType, MLSGroupID) async -> Void)?

    public func storeSubconversationGroupID(_ groupID: MLSGroupID?, forType type: SubgroupType, parentGroupID: MLSGroupID) async {
        storeSubconversationGroupIDForTypeParentGroupID_Invocations.append((groupID: groupID, type: type, parentGroupID: parentGroupID))

        guard let mock = storeSubconversationGroupIDForTypeParentGroupID_MockMethod else {
            fatalError("no mock for `storeSubconversationGroupIDForTypeParentGroupID`")
        }

        await mock(groupID, type, parentGroupID)
    }

    // MARK: - fetchSubconversationGroupID

    public var fetchSubconversationGroupIDForTypeParentGroupID_Invocations: [(type: SubgroupType, parentGroupID: MLSGroupID)] = []
    public var fetchSubconversationGroupIDForTypeParentGroupID_MockMethod: ((SubgroupType, MLSGroupID) async -> MLSGroupID?)?
    public var fetchSubconversationGroupIDForTypeParentGroupID_MockValue: MLSGroupID??

    public func fetchSubconversationGroupID(forType type: SubgroupType, parentGroupID: MLSGroupID) async -> MLSGroupID? {
        fetchSubconversationGroupIDForTypeParentGroupID_Invocations.append((type: type, parentGroupID: parentGroupID))

        if let mock = fetchSubconversationGroupIDForTypeParentGroupID_MockMethod {
            return await mock(type, parentGroupID)
        } else if let mock = fetchSubconversationGroupIDForTypeParentGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSubconversationGroupIDForTypeParentGroupID`")
        }
    }

    // MARK: - findSubgroupTypeAndParentID

    public var findSubgroupTypeAndParentIDFor_Invocations: [MLSGroupID] = []
    public var findSubgroupTypeAndParentIDFor_MockMethod: ((MLSGroupID) async -> (parentID: MLSGroupID, type: SubgroupType)?)?
    public var findSubgroupTypeAndParentIDFor_MockValue: (parentID: MLSGroupID, type: SubgroupType)??

    public func findSubgroupTypeAndParentID(for targetGroupID: MLSGroupID) async -> (parentID: MLSGroupID, type: SubgroupType)? {
        findSubgroupTypeAndParentIDFor_Invocations.append(targetGroupID)

        if let mock = findSubgroupTypeAndParentIDFor_MockMethod {
            return await mock(targetGroupID)
        } else if let mock = findSubgroupTypeAndParentIDFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `findSubgroupTypeAndParentIDFor`")
        }
    }

}

public class MockSyncStatusProtocol: SyncStatusProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - isLive

    public var isLive: Bool {
        get { return underlyingIsLive }
        set(value) { underlyingIsLive = value }
    }

    public var underlyingIsLive: Bool!


    // MARK: - performQuickSync

    public var performQuickSync_Invocations: [Void] = []
    public var performQuickSync_MockMethod: (() async -> Void)?

    public func performQuickSync() async {
        performQuickSync_Invocations.append(())

        guard let mock = performQuickSync_MockMethod else {
            fatalError("no mock for `performQuickSync`")
        }

        await mock()
    }

    // MARK: - resyncResources

    public var resyncResources_Invocations: [Void] = []
    public var resyncResources_MockMethod: (() -> Void)?

    public func resyncResources() {
        resyncResources_Invocations.append(())

        guard let mock = resyncResources_MockMethod else {
            fatalError("no mock for `resyncResources`")
        }

        mock()
    }

    // MARK: - forceSlowSync

    public var forceSlowSync_Invocations: [Void] = []
    public var forceSlowSync_MockMethod: (() -> Void)?

    public func forceSlowSync() {
        forceSlowSync_Invocations.append(())

        guard let mock = forceSlowSync_MockMethod else {
            fatalError("no mock for `forceSlowSync`")
        }

        mock()
    }

    // MARK: - recoverWithQuickSync

    public var recoverWithQuickSync_Invocations: [Void] = []
    public var recoverWithQuickSync_MockMethod: (() async -> Void)?

    public func recoverWithQuickSync() async {
        recoverWithQuickSync_Invocations.append(())

        guard let mock = recoverWithQuickSync_MockMethod else {
            fatalError("no mock for `recoverWithQuickSync`")
        }

        await mock()
    }

}

public class MockUpdateMLSGroupVerificationStatusUseCaseProtocol: UpdateMLSGroupVerificationStatusUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - invoke

    public var invokeForGroupID_Invocations: [(conversation: ZMConversation, groupID: MLSGroupID)] = []
    public var invokeForGroupID_MockError: Error?
    public var invokeForGroupID_MockMethod: ((ZMConversation, MLSGroupID) async throws -> Void)?

    public func invoke(for conversation: ZMConversation, groupID: MLSGroupID) async throws {
        invokeForGroupID_Invocations.append((conversation: conversation, groupID: groupID))

        if let error = invokeForGroupID_MockError {
            throw error
        }

        guard let mock = invokeForGroupID_MockMethod else {
            fatalError("no mock for `invokeForGroupID`")
        }

        try await mock(conversation, groupID)
    }

}

public class MockUserObserving: UserObserving {

    // MARK: - Life cycle

    public init() {}


    // MARK: - userDidChange

    public var userDidChange_Invocations: [UserChangeInfo] = []
    public var userDidChange_MockMethod: ((UserChangeInfo) -> Void)?

    public func userDidChange(_ changeInfo: UserChangeInfo) {
        userDidChange_Invocations.append(changeInfo)

        guard let mock = userDidChange_MockMethod else {
            fatalError("no mock for `userDidChange`")
        }

        mock(changeInfo)
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
