//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireDataModel
import WireCoreCrypto

public class MockCoreCryptoProtocol: CoreCryptoProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - addClientsToConversation

    public var addClientsToConversationConversationIdClients_Invocations: [(conversationId: Data, clients: [WireCoreCrypto.Invitee])] = []
    public var addClientsToConversationConversationIdClients_MockError: Error?
    public var addClientsToConversationConversationIdClients_MockMethod: ((Data, [WireCoreCrypto.Invitee]) async throws -> WireCoreCrypto.MemberAddedMessages)?
    public var addClientsToConversationConversationIdClients_MockValue: WireCoreCrypto.MemberAddedMessages?

    public func addClientsToConversation(conversationId: Data, clients: [WireCoreCrypto.Invitee]) async throws -> WireCoreCrypto.MemberAddedMessages {
        addClientsToConversationConversationIdClients_Invocations.append((conversationId: conversationId, clients: clients))

        if let error = addClientsToConversationConversationIdClients_MockError {
            throw error
        }

        if let mock = addClientsToConversationConversationIdClients_MockMethod {
            return try await mock(conversationId, clients)
        } else if let mock = addClientsToConversationConversationIdClients_MockValue {
            return mock
        } else {
            fatalError("no mock for `addClientsToConversationConversationIdClients`")
        }
    }

    // MARK: - clearPendingCommit

    public var clearPendingCommitConversationId_Invocations: [Data] = []
    public var clearPendingCommitConversationId_MockError: Error?
    public var clearPendingCommitConversationId_MockMethod: ((Data) async throws -> Void)?

    public func clearPendingCommit(conversationId: Data) async throws {
        clearPendingCommitConversationId_Invocations.append(conversationId)

        if let error = clearPendingCommitConversationId_MockError {
            throw error
        }

        guard let mock = clearPendingCommitConversationId_MockMethod else {
            fatalError("no mock for `clearPendingCommitConversationId`")
        }

        try await mock(conversationId)
    }

    // MARK: - clearPendingGroupFromExternalCommit

    public var clearPendingGroupFromExternalCommitConversationId_Invocations: [Data] = []
    public var clearPendingGroupFromExternalCommitConversationId_MockError: Error?
    public var clearPendingGroupFromExternalCommitConversationId_MockMethod: ((Data) async throws -> Void)?

    public func clearPendingGroupFromExternalCommit(conversationId: Data) async throws {
        clearPendingGroupFromExternalCommitConversationId_Invocations.append(conversationId)

        if let error = clearPendingGroupFromExternalCommitConversationId_MockError {
            throw error
        }

        guard let mock = clearPendingGroupFromExternalCommitConversationId_MockMethod else {
            fatalError("no mock for `clearPendingGroupFromExternalCommitConversationId`")
        }

        try await mock(conversationId)
    }

    // MARK: - clearPendingProposal

    public var clearPendingProposalConversationIdProposalRef_Invocations: [(conversationId: Data, proposalRef: Data)] = []
    public var clearPendingProposalConversationIdProposalRef_MockError: Error?
    public var clearPendingProposalConversationIdProposalRef_MockMethod: ((Data, Data) async throws -> Void)?

    public func clearPendingProposal(conversationId: Data, proposalRef: Data) async throws {
        clearPendingProposalConversationIdProposalRef_Invocations.append((conversationId: conversationId, proposalRef: proposalRef))

        if let error = clearPendingProposalConversationIdProposalRef_MockError {
            throw error
        }

        guard let mock = clearPendingProposalConversationIdProposalRef_MockMethod else {
            fatalError("no mock for `clearPendingProposalConversationIdProposalRef`")
        }

        try await mock(conversationId, proposalRef)
    }

    // MARK: - clientKeypackages

    public var clientKeypackagesCiphersuiteCredentialTypeAmountRequested_Invocations: [(ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType, amountRequested: UInt32)] = []
    public var clientKeypackagesCiphersuiteCredentialTypeAmountRequested_MockError: Error?
    public var clientKeypackagesCiphersuiteCredentialTypeAmountRequested_MockMethod: ((WireCoreCrypto.Ciphersuite, WireCoreCrypto.MlsCredentialType, UInt32) async throws -> [Data])?
    public var clientKeypackagesCiphersuiteCredentialTypeAmountRequested_MockValue: [Data]?

    public func clientKeypackages(ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType, amountRequested: UInt32) async throws -> [Data] {
        clientKeypackagesCiphersuiteCredentialTypeAmountRequested_Invocations.append((ciphersuite: ciphersuite, credentialType: credentialType, amountRequested: amountRequested))

        if let error = clientKeypackagesCiphersuiteCredentialTypeAmountRequested_MockError {
            throw error
        }

        if let mock = clientKeypackagesCiphersuiteCredentialTypeAmountRequested_MockMethod {
            return try await mock(ciphersuite, credentialType, amountRequested)
        } else if let mock = clientKeypackagesCiphersuiteCredentialTypeAmountRequested_MockValue {
            return mock
        } else {
            fatalError("no mock for `clientKeypackagesCiphersuiteCredentialTypeAmountRequested`")
        }
    }

    // MARK: - clientPublicKey

    public var clientPublicKeyCiphersuite_Invocations: [WireCoreCrypto.Ciphersuite] = []
    public var clientPublicKeyCiphersuite_MockError: Error?
    public var clientPublicKeyCiphersuite_MockMethod: ((WireCoreCrypto.Ciphersuite) async throws -> Data)?
    public var clientPublicKeyCiphersuite_MockValue: Data?

    public func clientPublicKey(ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> Data {
        clientPublicKeyCiphersuite_Invocations.append(ciphersuite)

        if let error = clientPublicKeyCiphersuite_MockError {
            throw error
        }

        if let mock = clientPublicKeyCiphersuite_MockMethod {
            return try await mock(ciphersuite)
        } else if let mock = clientPublicKeyCiphersuite_MockValue {
            return mock
        } else {
            fatalError("no mock for `clientPublicKeyCiphersuite`")
        }
    }

    // MARK: - clientValidKeypackagesCount

    public var clientValidKeypackagesCountCiphersuiteCredentialType_Invocations: [(ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType)] = []
    public var clientValidKeypackagesCountCiphersuiteCredentialType_MockError: Error?
    public var clientValidKeypackagesCountCiphersuiteCredentialType_MockMethod: ((WireCoreCrypto.Ciphersuite, WireCoreCrypto.MlsCredentialType) async throws -> UInt64)?
    public var clientValidKeypackagesCountCiphersuiteCredentialType_MockValue: UInt64?

    public func clientValidKeypackagesCount(ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType) async throws -> UInt64 {
        clientValidKeypackagesCountCiphersuiteCredentialType_Invocations.append((ciphersuite: ciphersuite, credentialType: credentialType))

        if let error = clientValidKeypackagesCountCiphersuiteCredentialType_MockError {
            throw error
        }

        if let mock = clientValidKeypackagesCountCiphersuiteCredentialType_MockMethod {
            return try await mock(ciphersuite, credentialType)
        } else if let mock = clientValidKeypackagesCountCiphersuiteCredentialType_MockValue {
            return mock
        } else {
            fatalError("no mock for `clientValidKeypackagesCountCiphersuiteCredentialType`")
        }
    }

    // MARK: - commitAccepted

    public var commitAcceptedConversationId_Invocations: [Data] = []
    public var commitAcceptedConversationId_MockError: Error?
    public var commitAcceptedConversationId_MockMethod: ((Data) async throws -> [WireCoreCrypto.BufferedDecryptedMessage]?)?
    public var commitAcceptedConversationId_MockValue: [WireCoreCrypto.BufferedDecryptedMessage]??

    public func commitAccepted(conversationId: Data) async throws -> [WireCoreCrypto.BufferedDecryptedMessage]? {
        commitAcceptedConversationId_Invocations.append(conversationId)

        if let error = commitAcceptedConversationId_MockError {
            throw error
        }

        if let mock = commitAcceptedConversationId_MockMethod {
            return try await mock(conversationId)
        } else if let mock = commitAcceptedConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `commitAcceptedConversationId`")
        }
    }

    // MARK: - commitPendingProposals

    var mockCommitPendingProposals: ((ConversationId) throws -> CommitBundle?)?

    func commitPendingProposals(conversationId: ConversationId) throws -> CommitBundle? {
        guard let mock = mockCommitPendingProposals else {
            fatalError("no mock for `commitPendingProposals`")
        }
    }

    // MARK: - createConversation

    public var createConversationConversationIdCreatorCredentialTypeConfig_Invocations: [(conversationId: Data, creatorCredentialType: WireCoreCrypto.MlsCredentialType, config: WireCoreCrypto.ConversationConfiguration)] = []
    public var createConversationConversationIdCreatorCredentialTypeConfig_MockError: Error?
    public var createConversationConversationIdCreatorCredentialTypeConfig_MockMethod: ((Data, WireCoreCrypto.MlsCredentialType, WireCoreCrypto.ConversationConfiguration) async throws -> Void)?

    public func createConversation(conversationId: Data, creatorCredentialType: WireCoreCrypto.MlsCredentialType, config: WireCoreCrypto.ConversationConfiguration) async throws {
        createConversationConversationIdCreatorCredentialTypeConfig_Invocations.append((conversationId: conversationId, creatorCredentialType: creatorCredentialType, config: config))

        if let error = createConversationConversationIdCreatorCredentialTypeConfig_MockError {
            throw error
        }

        guard let mock = createConversationConversationIdCreatorCredentialTypeConfig_MockMethod else {
            fatalError("no mock for `createConversationConversationIdCreatorCredentialTypeConfig`")
        }

        try await mock(conversationId, creatorCredentialType, config)
    }

    // MARK: - decryptMessage

    public var decryptMessageConversationIdPayload_Invocations: [(conversationId: Data, payload: Data)] = []
    public var decryptMessageConversationIdPayload_MockError: Error?
    public var decryptMessageConversationIdPayload_MockMethod: ((Data, Data) async throws -> WireCoreCrypto.DecryptedMessage)?
    public var decryptMessageConversationIdPayload_MockValue: WireCoreCrypto.DecryptedMessage?

    public func decryptMessage(conversationId: Data, payload: Data) async throws -> WireCoreCrypto.DecryptedMessage {
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

    // MARK: - deleteKeypackages

    public var deleteKeypackagesRefs_Invocations: [[Data]] = []
    public var deleteKeypackagesRefs_MockError: Error?
    public var deleteKeypackagesRefs_MockMethod: (([Data]) async throws -> Void)?

    public func deleteKeypackages(refs: [Data]) async throws {
        deleteKeypackagesRefs_Invocations.append(refs)

        if let error = deleteKeypackagesRefs_MockError {
            throw error
        }

        guard let mock = deleteKeypackagesRefs_MockMethod else {
            fatalError("no mock for `deleteKeypackagesRefs`")
        }

        try await mock(refs)
    }

    // MARK: - e2eiConversationState

    public var e2eiConversationStateConversationId_Invocations: [Data] = []
    public var e2eiConversationStateConversationId_MockError: Error?
    public var e2eiConversationStateConversationId_MockMethod: ((Data) async throws -> WireCoreCrypto.E2eiConversationState)?
    public var e2eiConversationStateConversationId_MockValue: WireCoreCrypto.E2eiConversationState?

    public func e2eiConversationState(conversationId: Data) async throws -> WireCoreCrypto.E2eiConversationState {
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

    // MARK: - e2eiEnrollmentStash

    public var e2eiEnrollmentStashEnrollment_Invocations: [WireCoreCrypto.E2eiEnrollment] = []
    public var e2eiEnrollmentStashEnrollment_MockError: Error?
    public var e2eiEnrollmentStashEnrollment_MockMethod: ((WireCoreCrypto.E2eiEnrollment) async throws -> Data)?
    public var e2eiEnrollmentStashEnrollment_MockValue: Data?

    public func e2eiEnrollmentStash(enrollment: WireCoreCrypto.E2eiEnrollment) async throws -> Data {
        e2eiEnrollmentStashEnrollment_Invocations.append(enrollment)

        if let error = e2eiEnrollmentStashEnrollment_MockError {
            throw error
        }

        if let mock = e2eiEnrollmentStashEnrollment_MockMethod {
            return try await mock(enrollment)
        } else if let mock = e2eiEnrollmentStashEnrollment_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiEnrollmentStashEnrollment`")
        }
    }

    // MARK: - e2eiEnrollmentStashPop

    public var e2eiEnrollmentStashPopHandle_Invocations: [Data] = []
    public var e2eiEnrollmentStashPopHandle_MockError: Error?
    public var e2eiEnrollmentStashPopHandle_MockMethod: ((Data) async throws -> WireCoreCrypto.E2eiEnrollment)?
    public var e2eiEnrollmentStashPopHandle_MockValue: WireCoreCrypto.E2eiEnrollment?

    public func e2eiEnrollmentStashPop(handle: Data) async throws -> WireCoreCrypto.E2eiEnrollment {
        e2eiEnrollmentStashPopHandle_Invocations.append(handle)

        if let error = e2eiEnrollmentStashPopHandle_MockError {
            throw error
        }

        if let mock = e2eiEnrollmentStashPopHandle_MockMethod {
            return try await mock(handle)
        } else if let mock = e2eiEnrollmentStashPopHandle_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiEnrollmentStashPopHandle`")
        }
    }

    // MARK: - e2eiIsEnabled

    public var e2eiIsEnabledCiphersuite_Invocations: [WireCoreCrypto.Ciphersuite] = []
    public var e2eiIsEnabledCiphersuite_MockError: Error?
    public var e2eiIsEnabledCiphersuite_MockMethod: ((WireCoreCrypto.Ciphersuite) async throws -> Bool)?
    public var e2eiIsEnabledCiphersuite_MockValue: Bool?

    public func e2eiIsEnabled(ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> Bool {
        e2eiIsEnabledCiphersuite_Invocations.append(ciphersuite)

        if let error = e2eiIsEnabledCiphersuite_MockError {
            throw error
        }

        if let mock = e2eiIsEnabledCiphersuite_MockMethod {
            return try await mock(ciphersuite)
        } else if let mock = e2eiIsEnabledCiphersuite_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiIsEnabledCiphersuite`")
        }
    }

    // MARK: - e2eiMlsInitOnly

    public var e2eiMlsInitOnlyEnrollmentCertificateChain_Invocations: [(enrollment: WireCoreCrypto.E2eiEnrollment, certificateChain: String)] = []
    public var e2eiMlsInitOnlyEnrollmentCertificateChain_MockError: Error?
    public var e2eiMlsInitOnlyEnrollmentCertificateChain_MockMethod: ((WireCoreCrypto.E2eiEnrollment, String) async throws -> Void)?

    public func e2eiMlsInitOnly(enrollment: WireCoreCrypto.E2eiEnrollment, certificateChain: String) async throws {
        e2eiMlsInitOnlyEnrollmentCertificateChain_Invocations.append((enrollment: enrollment, certificateChain: certificateChain))

        if let error = e2eiMlsInitOnlyEnrollmentCertificateChain_MockError {
            throw error
        }

        guard let mock = e2eiMlsInitOnlyEnrollmentCertificateChain_MockMethod else {
            fatalError("no mock for `e2eiMlsInitOnlyEnrollmentCertificateChain`")
        }

        try await mock(enrollment, certificateChain)
    }

    // MARK: - e2eiNewActivationEnrollment

    public var e2eiNewActivationEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_Invocations: [(clientId: String, displayName: String, handle: String, expiryDays: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite)] = []
    public var e2eiNewActivationEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockError: Error?
    public var e2eiNewActivationEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockMethod: ((String, String, String, UInt32, WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment)?
    public var e2eiNewActivationEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockValue: WireCoreCrypto.E2eiEnrollment?

    public func e2eiNewActivationEnrollment(clientId: String, displayName: String, handle: String, expiryDays: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment {
        e2eiNewActivationEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_Invocations.append((clientId: clientId, displayName: displayName, handle: handle, expiryDays: expiryDays, ciphersuite: ciphersuite))

        if let error = e2eiNewActivationEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockError {
            throw error
        }

        if let mock = e2eiNewActivationEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockMethod {
            return try await mock(clientId, displayName, handle, expiryDays, ciphersuite)
        } else if let mock = e2eiNewActivationEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiNewActivationEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite`")
        }
    }

    // MARK: - e2eiNewEnrollment

    public var e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_Invocations: [(clientId: String, displayName: String, handle: String, expiryDays: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite)] = []
    public var e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockError: Error?
    public var e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockMethod: ((String, String, String, UInt32, WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment)?
    public var e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockValue: WireCoreCrypto.E2eiEnrollment?

    public func e2eiNewEnrollment(clientId: String, displayName: String, handle: String, expiryDays: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment {
        e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_Invocations.append((clientId: clientId, displayName: displayName, handle: handle, expiryDays: expiryDays, ciphersuite: ciphersuite))

        if let error = e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockError {
            throw error
        }

        if let mock = e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockMethod {
            return try await mock(clientId, displayName, handle, expiryDays, ciphersuite)
        } else if let mock = e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite`")
        }
    }

    // MARK: - e2eiNewRotateEnrollment

    public var e2eiNewRotateEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_Invocations: [(clientId: String, displayName: String?, handle: String?, expiryDays: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite)] = []
    public var e2eiNewRotateEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockError: Error?
    public var e2eiNewRotateEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockMethod: ((String, String?, String?, UInt32, WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment)?
    public var e2eiNewRotateEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockValue: WireCoreCrypto.E2eiEnrollment?

    public func e2eiNewRotateEnrollment(clientId: String, displayName: String?, handle: String?, expiryDays: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment {
        e2eiNewRotateEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_Invocations.append((clientId: clientId, displayName: displayName, handle: handle, expiryDays: expiryDays, ciphersuite: ciphersuite))

        if let error = e2eiNewRotateEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockError {
            throw error
        }

        if let mock = e2eiNewRotateEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockMethod {
            return try await mock(clientId, displayName, handle, expiryDays, ciphersuite)
        } else if let mock = e2eiNewRotateEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiNewRotateEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite`")
        }
    }

    // MARK: - e2eiRotateAll

    public var e2eiRotateAllEnrollmentCertificateChainNewKeyPackagesCount_Invocations: [(enrollment: WireCoreCrypto.E2eiEnrollment, certificateChain: String, newKeyPackagesCount: UInt32)] = []
    public var e2eiRotateAllEnrollmentCertificateChainNewKeyPackagesCount_MockError: Error?
    public var e2eiRotateAllEnrollmentCertificateChainNewKeyPackagesCount_MockMethod: ((WireCoreCrypto.E2eiEnrollment, String, UInt32) async throws -> WireCoreCrypto.RotateBundle)?
    public var e2eiRotateAllEnrollmentCertificateChainNewKeyPackagesCount_MockValue: WireCoreCrypto.RotateBundle?

    public func e2eiRotateAll(enrollment: WireCoreCrypto.E2eiEnrollment, certificateChain: String, newKeyPackagesCount: UInt32) async throws -> WireCoreCrypto.RotateBundle {
        e2eiRotateAllEnrollmentCertificateChainNewKeyPackagesCount_Invocations.append((enrollment: enrollment, certificateChain: certificateChain, newKeyPackagesCount: newKeyPackagesCount))

        if let error = e2eiRotateAllEnrollmentCertificateChainNewKeyPackagesCount_MockError {
            throw error
        }

        if let mock = e2eiRotateAllEnrollmentCertificateChainNewKeyPackagesCount_MockMethod {
            return try await mock(enrollment, certificateChain, newKeyPackagesCount)
        } else if let mock = e2eiRotateAllEnrollmentCertificateChainNewKeyPackagesCount_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiRotateAllEnrollmentCertificateChainNewKeyPackagesCount`")
        }
    }

    // MARK: - encryptMessage

    public var encryptMessageConversationIdMessage_Invocations: [(conversationId: Data, message: Data)] = []
    public var encryptMessageConversationIdMessage_MockError: Error?
    public var encryptMessageConversationIdMessage_MockMethod: ((Data, Data) async throws -> Data)?
    public var encryptMessageConversationIdMessage_MockValue: Data?

    public func encryptMessage(conversationId: Data, message: Data) async throws -> Data {
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

    public var exportSecretKeyConversationIdKeyLength_Invocations: [(conversationId: Data, keyLength: UInt32)] = []
    public var exportSecretKeyConversationIdKeyLength_MockError: Error?
    public var exportSecretKeyConversationIdKeyLength_MockMethod: ((Data, UInt32) async throws -> Data)?
    public var exportSecretKeyConversationIdKeyLength_MockValue: Data?

    public func exportSecretKey(conversationId: Data, keyLength: UInt32) async throws -> Data {
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

    // MARK: - getClientIds

    public var getClientIdsConversationId_Invocations: [Data] = []
    public var getClientIdsConversationId_MockError: Error?
    public var getClientIdsConversationId_MockMethod: ((Data) async throws -> [WireCoreCrypto.ClientId])?
    public var getClientIdsConversationId_MockValue: [WireCoreCrypto.ClientId]?

    public func getClientIds(conversationId: Data) async throws -> [WireCoreCrypto.ClientId] {
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

    // MARK: - getUserIdentities

    public var getUserIdentitiesConversationIdClientIds_Invocations: [(conversationId: Data, clientIds: [WireCoreCrypto.ClientId])] = []
    public var getUserIdentitiesConversationIdClientIds_MockError: Error?
    public var getUserIdentitiesConversationIdClientIds_MockMethod: ((Data, [WireCoreCrypto.ClientId]) async throws -> [WireCoreCrypto.WireIdentity])?
    public var getUserIdentitiesConversationIdClientIds_MockValue: [WireCoreCrypto.WireIdentity]?

    public func getUserIdentities(conversationId: Data, clientIds: [WireCoreCrypto.ClientId]) async throws -> [WireCoreCrypto.WireIdentity] {
        getUserIdentitiesConversationIdClientIds_Invocations.append((conversationId: conversationId, clientIds: clientIds))

        if let error = getUserIdentitiesConversationIdClientIds_MockError {
            throw error
        }

        if let mock = getUserIdentitiesConversationIdClientIds_MockMethod {
            return try await mock(conversationId, clientIds)
        } else if let mock = getUserIdentitiesConversationIdClientIds_MockValue {
            return mock
        } else {
            fatalError("no mock for `getUserIdentitiesConversationIdClientIds`")
        }
    }

    // MARK: - joinByExternalCommit

    public var joinByExternalCommitGroupInfoCustomConfigurationCredentialType_Invocations: [(groupInfo: Data, customConfiguration: WireCoreCrypto.CustomConfiguration, credentialType: WireCoreCrypto.MlsCredentialType)] = []
    public var joinByExternalCommitGroupInfoCustomConfigurationCredentialType_MockError: Error?
    public var joinByExternalCommitGroupInfoCustomConfigurationCredentialType_MockMethod: ((Data, WireCoreCrypto.CustomConfiguration, WireCoreCrypto.MlsCredentialType) async throws -> WireCoreCrypto.ConversationInitBundle)?
    public var joinByExternalCommitGroupInfoCustomConfigurationCredentialType_MockValue: WireCoreCrypto.ConversationInitBundle?

    public func joinByExternalCommit(groupInfo: Data, customConfiguration: WireCoreCrypto.CustomConfiguration, credentialType: WireCoreCrypto.MlsCredentialType) async throws -> WireCoreCrypto.ConversationInitBundle {
        joinByExternalCommitGroupInfoCustomConfigurationCredentialType_Invocations.append((groupInfo: groupInfo, customConfiguration: customConfiguration, credentialType: credentialType))

        if let error = joinByExternalCommitGroupInfoCustomConfigurationCredentialType_MockError {
            throw error
        }

        if let mock = joinByExternalCommitGroupInfoCustomConfigurationCredentialType_MockMethod {
            return try await mock(groupInfo, customConfiguration, credentialType)
        } else if let mock = joinByExternalCommitGroupInfoCustomConfigurationCredentialType_MockValue {
            return mock
        } else {
            fatalError("no mock for `joinByExternalCommitGroupInfoCustomConfigurationCredentialType`")
        }
    }

    // MARK: - markConversationAsChildOf

    public var markConversationAsChildOfChildIdParentId_Invocations: [(childId: Data, parentId: Data)] = []
    public var markConversationAsChildOfChildIdParentId_MockError: Error?
    public var markConversationAsChildOfChildIdParentId_MockMethod: ((Data, Data) async throws -> Void)?

    public func markConversationAsChildOf(childId: Data, parentId: Data) async throws {
        markConversationAsChildOfChildIdParentId_Invocations.append((childId: childId, parentId: parentId))

        if let error = markConversationAsChildOfChildIdParentId_MockError {
            throw error
        }

        guard let mock = markConversationAsChildOfChildIdParentId_MockMethod else {
            fatalError("no mock for `markConversationAsChildOfChildIdParentId`")
        }

        try await mock(childId, parentId)
    }

    // MARK: - mergePendingGroupFromExternalCommit

    public var mergePendingGroupFromExternalCommitConversationId_Invocations: [Data] = []
    public var mergePendingGroupFromExternalCommitConversationId_MockError: Error?
    public var mergePendingGroupFromExternalCommitConversationId_MockMethod: ((Data) async throws -> [WireCoreCrypto.BufferedDecryptedMessage]?)?
    public var mergePendingGroupFromExternalCommitConversationId_MockValue: [WireCoreCrypto.BufferedDecryptedMessage]??

    public func mergePendingGroupFromExternalCommit(conversationId: Data) async throws -> [WireCoreCrypto.BufferedDecryptedMessage]? {
        mergePendingGroupFromExternalCommitConversationId_Invocations.append(conversationId)

        if let error = mergePendingGroupFromExternalCommitConversationId_MockError {
            throw error
        }

        if let mock = mergePendingGroupFromExternalCommitConversationId_MockMethod {
            return try await mock(conversationId)
        } else if let mock = mergePendingGroupFromExternalCommitConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `mergePendingGroupFromExternalCommitConversationId`")
        }
    }

    // MARK: - mlsGenerateKeypairs

    public var mlsGenerateKeypairsCiphersuites_Invocations: [WireCoreCrypto.Ciphersuites] = []
    public var mlsGenerateKeypairsCiphersuites_MockError: Error?
    public var mlsGenerateKeypairsCiphersuites_MockMethod: ((WireCoreCrypto.Ciphersuites) async throws -> [WireCoreCrypto.ClientId])?
    public var mlsGenerateKeypairsCiphersuites_MockValue: [WireCoreCrypto.ClientId]?

    public func mlsGenerateKeypairs(ciphersuites: WireCoreCrypto.Ciphersuites) async throws -> [WireCoreCrypto.ClientId] {
        mlsGenerateKeypairsCiphersuites_Invocations.append(ciphersuites)

        if let error = mlsGenerateKeypairsCiphersuites_MockError {
            throw error
        }

        if let mock = mlsGenerateKeypairsCiphersuites_MockMethod {
            return try await mock(ciphersuites)
        } else if let mock = mlsGenerateKeypairsCiphersuites_MockValue {
            return mock
        } else {
            fatalError("no mock for `mlsGenerateKeypairsCiphersuites`")
        }
    }

    // MARK: - mlsInit

    public var mlsInitClientIdCiphersuites_Invocations: [(clientId: WireCoreCrypto.ClientId, ciphersuites: WireCoreCrypto.Ciphersuites)] = []
    public var mlsInitClientIdCiphersuites_MockError: Error?
    public var mlsInitClientIdCiphersuites_MockMethod: ((WireCoreCrypto.ClientId, WireCoreCrypto.Ciphersuites) async throws -> Void)?

    public func mlsInit(clientId: WireCoreCrypto.ClientId, ciphersuites: WireCoreCrypto.Ciphersuites) async throws {
        mlsInitClientIdCiphersuites_Invocations.append((clientId: clientId, ciphersuites: ciphersuites))

        if let error = mlsInitClientIdCiphersuites_MockError {
            throw error
        }

        guard let mock = mlsInitClientIdCiphersuites_MockMethod else {
            fatalError("no mock for `mlsInitClientIdCiphersuites`")
        }

        try await mock(clientId, ciphersuites)
    }

    // MARK: - mlsInitWithClientId

    public var mlsInitWithClientIdClientIdTmpClientIdsCiphersuites_Invocations: [(clientId: WireCoreCrypto.ClientId, tmpClientIds: [WireCoreCrypto.ClientId], ciphersuites: WireCoreCrypto.Ciphersuites)] = []
    public var mlsInitWithClientIdClientIdTmpClientIdsCiphersuites_MockError: Error?
    public var mlsInitWithClientIdClientIdTmpClientIdsCiphersuites_MockMethod: ((WireCoreCrypto.ClientId, [WireCoreCrypto.ClientId], WireCoreCrypto.Ciphersuites) async throws -> Void)?

    public func mlsInitWithClientId(clientId: WireCoreCrypto.ClientId, tmpClientIds: [WireCoreCrypto.ClientId], ciphersuites: WireCoreCrypto.Ciphersuites) async throws {
        mlsInitWithClientIdClientIdTmpClientIdsCiphersuites_Invocations.append((clientId: clientId, tmpClientIds: tmpClientIds, ciphersuites: ciphersuites))

        if let error = mlsInitWithClientIdClientIdTmpClientIdsCiphersuites_MockError {
            throw error
        }

        guard let mock = mlsInitWithClientIdClientIdTmpClientIdsCiphersuites_MockMethod else {
            fatalError("no mock for `mlsInitWithClientIdClientIdTmpClientIdsCiphersuites`")
        }

        try await mock(clientId, tmpClientIds, ciphersuites)
    }

    // MARK: - newAddProposal

    public var newAddProposalConversationIdKeypackage_Invocations: [(conversationId: Data, keypackage: Data)] = []
    public var newAddProposalConversationIdKeypackage_MockError: Error?
    public var newAddProposalConversationIdKeypackage_MockMethod: ((Data, Data) async throws -> WireCoreCrypto.ProposalBundle)?
    public var newAddProposalConversationIdKeypackage_MockValue: WireCoreCrypto.ProposalBundle?

    public func newAddProposal(conversationId: Data, keypackage: Data) async throws -> WireCoreCrypto.ProposalBundle {
        newAddProposalConversationIdKeypackage_Invocations.append((conversationId: conversationId, keypackage: keypackage))

        if let error = newAddProposalConversationIdKeypackage_MockError {
            throw error
        }

        if let mock = newAddProposalConversationIdKeypackage_MockMethod {
            return try await mock(conversationId, keypackage)
        } else if let mock = newAddProposalConversationIdKeypackage_MockValue {
            return mock
        } else {
            fatalError("no mock for `newAddProposalConversationIdKeypackage`")
        }
    }

    // MARK: - newExternalAddProposal

    public var newExternalAddProposalConversationIdEpochCiphersuiteCredentialType_Invocations: [(conversationId: Data, epoch: UInt64, ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType)] = []
    public var newExternalAddProposalConversationIdEpochCiphersuiteCredentialType_MockError: Error?
    public var newExternalAddProposalConversationIdEpochCiphersuiteCredentialType_MockMethod: ((Data, UInt64, WireCoreCrypto.Ciphersuite, WireCoreCrypto.MlsCredentialType) async throws -> Data)?
    public var newExternalAddProposalConversationIdEpochCiphersuiteCredentialType_MockValue: Data?

    public func newExternalAddProposal(conversationId: Data, epoch: UInt64, ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType) async throws -> Data {
        newExternalAddProposalConversationIdEpochCiphersuiteCredentialType_Invocations.append((conversationId: conversationId, epoch: epoch, ciphersuite: ciphersuite, credentialType: credentialType))

        if let error = newExternalAddProposalConversationIdEpochCiphersuiteCredentialType_MockError {
            throw error
        }

        if let mock = newExternalAddProposalConversationIdEpochCiphersuiteCredentialType_MockMethod {
            return try await mock(conversationId, epoch, ciphersuite, credentialType)
        } else if let mock = newExternalAddProposalConversationIdEpochCiphersuiteCredentialType_MockValue {
            return mock
        } else {
            fatalError("no mock for `newExternalAddProposalConversationIdEpochCiphersuiteCredentialType`")
        }
    }

    // MARK: - newRemoveProposal

    public var newRemoveProposalConversationIdClientId_Invocations: [(conversationId: Data, clientId: WireCoreCrypto.ClientId)] = []
    public var newRemoveProposalConversationIdClientId_MockError: Error?
    public var newRemoveProposalConversationIdClientId_MockMethod: ((Data, WireCoreCrypto.ClientId) async throws -> WireCoreCrypto.ProposalBundle)?
    public var newRemoveProposalConversationIdClientId_MockValue: WireCoreCrypto.ProposalBundle?

    public func newRemoveProposal(conversationId: Data, clientId: WireCoreCrypto.ClientId) async throws -> WireCoreCrypto.ProposalBundle {
        newRemoveProposalConversationIdClientId_Invocations.append((conversationId: conversationId, clientId: clientId))

        if let error = newRemoveProposalConversationIdClientId_MockError {
            throw error
        }

        if let mock = newRemoveProposalConversationIdClientId_MockMethod {
            return try await mock(conversationId, clientId)
        } else if let mock = newRemoveProposalConversationIdClientId_MockValue {
            return mock
        } else {
            fatalError("no mock for `newRemoveProposalConversationIdClientId`")
        }
    }

    // MARK: - newUpdateProposal

    public var newUpdateProposalConversationId_Invocations: [Data] = []
    public var newUpdateProposalConversationId_MockError: Error?
    public var newUpdateProposalConversationId_MockMethod: ((Data) async throws -> WireCoreCrypto.ProposalBundle)?
    public var newUpdateProposalConversationId_MockValue: WireCoreCrypto.ProposalBundle?

    public func newUpdateProposal(conversationId: Data) async throws -> WireCoreCrypto.ProposalBundle {
        newUpdateProposalConversationId_Invocations.append(conversationId)

        if let error = newUpdateProposalConversationId_MockError {
            throw error
        }

        if let mock = newUpdateProposalConversationId_MockMethod {
            return try await mock(conversationId)
        } else if let mock = newUpdateProposalConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `newUpdateProposalConversationId`")
        }
    }

    // MARK: - processWelcomeMessage

    public var processWelcomeMessageWelcomeMessageCustomConfiguration_Invocations: [(welcomeMessage: Data, customConfiguration: WireCoreCrypto.CustomConfiguration)] = []
    public var processWelcomeMessageWelcomeMessageCustomConfiguration_MockError: Error?
    public var processWelcomeMessageWelcomeMessageCustomConfiguration_MockMethod: ((Data, WireCoreCrypto.CustomConfiguration) async throws -> Data)?
    public var processWelcomeMessageWelcomeMessageCustomConfiguration_MockValue: Data?

    public func processWelcomeMessage(welcomeMessage: Data, customConfiguration: WireCoreCrypto.CustomConfiguration) async throws -> Data {
        processWelcomeMessageWelcomeMessageCustomConfiguration_Invocations.append((welcomeMessage: welcomeMessage, customConfiguration: customConfiguration))

        if let error = processWelcomeMessageWelcomeMessageCustomConfiguration_MockError {
            throw error
        }

        if let mock = processWelcomeMessageWelcomeMessageCustomConfiguration_MockMethod {
            return try await mock(welcomeMessage, customConfiguration)
        } else if let mock = processWelcomeMessageWelcomeMessageCustomConfiguration_MockValue {
            return mock
        } else {
            fatalError("no mock for `processWelcomeMessageWelcomeMessageCustomConfiguration`")
        }
    }

    // MARK: - proteusCryptoboxMigrate

    public var proteusCryptoboxMigratePath_Invocations: [String] = []
    public var proteusCryptoboxMigratePath_MockError: Error?
    public var proteusCryptoboxMigratePath_MockMethod: ((String) async throws -> Void)?

    public func proteusCryptoboxMigrate(path: String) async throws {
        proteusCryptoboxMigratePath_Invocations.append(path)

        if let error = proteusCryptoboxMigratePath_MockError {
            throw error
        }

        guard let mock = proteusCryptoboxMigratePath_MockMethod else {
            fatalError("no mock for `proteusCryptoboxMigratePath`")
        }

        try await mock(path)
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

    // MARK: - proteusFingerprintPrekeybundle

    public var proteusFingerprintPrekeybundlePrekey_Invocations: [Data] = []
    public var proteusFingerprintPrekeybundlePrekey_MockError: Error?
    public var proteusFingerprintPrekeybundlePrekey_MockMethod: ((Data) throws -> String)?
    public var proteusFingerprintPrekeybundlePrekey_MockValue: String?

    public func proteusFingerprintPrekeybundle(prekey: Data) throws -> String {
        proteusFingerprintPrekeybundlePrekey_Invocations.append(prekey)

        if let error = proteusFingerprintPrekeybundlePrekey_MockError {
            throw error
        }

        if let mock = proteusFingerprintPrekeybundlePrekey_MockMethod {
            return try mock(prekey)
        } else if let mock = proteusFingerprintPrekeybundlePrekey_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusFingerprintPrekeybundlePrekey`")
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

    // MARK: - proteusLastErrorCode

    public var proteusLastErrorCode_Invocations: [Void] = []
    public var proteusLastErrorCode_MockMethod: (() -> UInt32)?
    public var proteusLastErrorCode_MockValue: UInt32?

    public func proteusLastErrorCode() -> UInt32 {
        proteusLastErrorCode_Invocations.append(())

        if let mock = proteusLastErrorCode_MockMethod {
            return mock()
        } else if let mock = proteusLastErrorCode_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusLastErrorCode`")
        }
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

    // MARK: - proteusLastResortPrekeyId

    public var proteusLastResortPrekeyId_Invocations: [Void] = []
    public var proteusLastResortPrekeyId_MockError: Error?
    public var proteusLastResortPrekeyId_MockMethod: (() throws -> UInt16)?
    public var proteusLastResortPrekeyId_MockValue: UInt16?

    public func proteusLastResortPrekeyId() throws -> UInt16 {
        proteusLastResortPrekeyId_Invocations.append(())

        if let error = proteusLastResortPrekeyId_MockError {
            throw error
        }

        if let mock = proteusLastResortPrekeyId_MockMethod {
            return try mock()
        } else if let mock = proteusLastResortPrekeyId_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusLastResortPrekeyId`")
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
    public var proteusNewPrekeyAuto_MockMethod: (() async throws -> WireCoreCrypto.ProteusAutoPrekeyBundle)?
    public var proteusNewPrekeyAuto_MockValue: WireCoreCrypto.ProteusAutoPrekeyBundle?

    public func proteusNewPrekeyAuto() async throws -> WireCoreCrypto.ProteusAutoPrekeyBundle {
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

    public var removeClientsFromConversationConversationIdClients_Invocations: [(conversationId: Data, clients: [WireCoreCrypto.ClientId])] = []
    public var removeClientsFromConversationConversationIdClients_MockError: Error?
    public var removeClientsFromConversationConversationIdClients_MockMethod: ((Data, [WireCoreCrypto.ClientId]) async throws -> WireCoreCrypto.CommitBundle)?
    public var removeClientsFromConversationConversationIdClients_MockValue: WireCoreCrypto.CommitBundle?

    public func removeClientsFromConversation(conversationId: Data, clients: [WireCoreCrypto.ClientId]) async throws -> WireCoreCrypto.CommitBundle {
        removeClientsFromConversationConversationIdClients_Invocations.append((conversationId: conversationId, clients: clients))

        if let error = removeClientsFromConversationConversationIdClients_MockError {
            throw error
        }

        if let mock = removeClientsFromConversationConversationIdClients_MockMethod {
            return try await mock(conversationId, clients)
        } else if let mock = removeClientsFromConversationConversationIdClients_MockValue {
            return mock
        } else {
            fatalError("no mock for `removeClientsFromConversationConversationIdClients`")
        }
    }

    // MARK: - reseedRng

    public var reseedRngSeed_Invocations: [Data] = []
    public var reseedRngSeed_MockError: Error?
    public var reseedRngSeed_MockMethod: ((Data) async throws -> Void)?

    public func reseedRng(seed: Data) async throws {
        reseedRngSeed_Invocations.append(seed)

        if let error = reseedRngSeed_MockError {
            throw error
        }

        guard let mock = reseedRngSeed_MockMethod else {
            fatalError("no mock for `reseedRngSeed`")
        }

        try await mock(seed)
    }

    // MARK: - restoreFromDisk

    public var restoreFromDisk_Invocations: [Void] = []
    public var restoreFromDisk_MockError: Error?
    public var restoreFromDisk_MockMethod: (() async throws -> Void)?

    public func restoreFromDisk() async throws {
        restoreFromDisk_Invocations.append(())

        if let error = restoreFromDisk_MockError {
            throw error
        }

        guard let mock = restoreFromDisk_MockMethod else {
            fatalError("no mock for `restoreFromDisk`")
        }

        try await mock()
    }

    // MARK: - setCallbacks

    public var setCallbacksCallbacks_Invocations: [WireCoreCrypto.CoreCryptoCallbacks] = []
    public var setCallbacksCallbacks_MockError: Error?
    public var setCallbacksCallbacks_MockMethod: ((WireCoreCrypto.CoreCryptoCallbacks) async throws -> Void)?

    public func setCallbacks(callbacks: WireCoreCrypto.CoreCryptoCallbacks) async throws {
        setCallbacksCallbacks_Invocations.append(callbacks)

        if let error = setCallbacksCallbacks_MockError {
            throw error
        }

        guard let mock = setCallbacksCallbacks_MockMethod else {
            fatalError("no mock for `setCallbacksCallbacks`")
        }

        try await mock(callbacks)
    }

    // MARK: - unload

    public var unload_Invocations: [Void] = []
    public var unload_MockError: Error?
    public var unload_MockMethod: (() async throws -> Void)?

    public func unload() async throws {
        unload_Invocations.append(())

        if let error = unload_MockError {
            throw error
        }

        guard let mock = unload_MockMethod else {
            fatalError("no mock for `unload`")
        }

        try await mock()
    }

    // MARK: - updateKeyingMaterial

    public var updateKeyingMaterialConversationId_Invocations: [Data] = []
    public var updateKeyingMaterialConversationId_MockError: Error?
    public var updateKeyingMaterialConversationId_MockMethod: ((Data) async throws -> WireCoreCrypto.CommitBundle)?
    public var updateKeyingMaterialConversationId_MockValue: WireCoreCrypto.CommitBundle?

    public func updateKeyingMaterial(conversationId: Data) async throws -> WireCoreCrypto.CommitBundle {
        updateKeyingMaterialConversationId_Invocations.append(conversationId)

        if let error = updateKeyingMaterialConversationId_MockError {
            throw error
        }

        if let mock = updateKeyingMaterialConversationId_MockMethod {
            return try await mock(conversationId)
        } else if let mock = updateKeyingMaterialConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `updateKeyingMaterialConversationId`")
        }
    }

    // MARK: - updateTrustAnchorsFromConversation

    public var updateTrustAnchorsFromConversationIdRemoveDomainNamesAddTrustAnchors_Invocations: [(id: Data, removeDomainNames: [String], addTrustAnchors: [WireCoreCrypto.PerDomainTrustAnchor])] = []
    public var updateTrustAnchorsFromConversationIdRemoveDomainNamesAddTrustAnchors_MockError: Error?
    public var updateTrustAnchorsFromConversationIdRemoveDomainNamesAddTrustAnchors_MockMethod: ((Data, [String], [WireCoreCrypto.PerDomainTrustAnchor]) async throws -> WireCoreCrypto.CommitBundle)?
    public var updateTrustAnchorsFromConversationIdRemoveDomainNamesAddTrustAnchors_MockValue: WireCoreCrypto.CommitBundle?

    public func updateTrustAnchorsFromConversation(id: Data, removeDomainNames: [String], addTrustAnchors: [WireCoreCrypto.PerDomainTrustAnchor]) async throws -> WireCoreCrypto.CommitBundle {
        updateTrustAnchorsFromConversationIdRemoveDomainNamesAddTrustAnchors_Invocations.append((id: id, removeDomainNames: removeDomainNames, addTrustAnchors: addTrustAnchors))

        if let error = updateTrustAnchorsFromConversationIdRemoveDomainNamesAddTrustAnchors_MockError {
            throw error
        }

        if let mock = updateTrustAnchorsFromConversationIdRemoveDomainNamesAddTrustAnchors_MockMethod {
            return try await mock(id, removeDomainNames, addTrustAnchors)
        } else if let mock = updateTrustAnchorsFromConversationIdRemoveDomainNamesAddTrustAnchors_MockValue {
            return mock
        } else {
            fatalError("no mock for `updateTrustAnchorsFromConversationIdRemoveDomainNamesAddTrustAnchors`")
        }
    }

    // MARK: - wipe

    public var wipe_Invocations: [Void] = []
    public var wipe_MockError: Error?
    public var wipe_MockMethod: (() async throws -> Void)?

    public func wipe() async throws {
        wipe_Invocations.append(())

        if let error = wipe_MockError {
            throw error
        }

        guard let mock = wipe_MockMethod else {
            fatalError("no mock for `wipe`")
        }

        try await mock()
    }

    // MARK: - wipeConversation

    public var wipeConversationConversationId_Invocations: [Data] = []
    public var wipeConversationConversationId_MockError: Error?
    public var wipeConversationConversationId_MockMethod: ((Data) async throws -> Void)?

    public func wipeConversation(conversationId: Data) async throws {
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
