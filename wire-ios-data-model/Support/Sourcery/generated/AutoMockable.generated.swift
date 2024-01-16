// Generated using Sourcery 2.1.2 — https://github.com/krzysztofzablocki/Sourcery
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

import LocalAuthentication
import Combine
import WireCoreCrypto

@testable import WireDataModel





















public class MockCommitSending: CommitSending {

    // MARK: - Life cycle

    public init() {}


    // MARK: - sendCommitBundle

    public var sendCommitBundleFor_Invocations: [(bundle: CommitBundle, groupID: MLSGroupID)] = []
    public var sendCommitBundleFor_MockError: Error?
    public var sendCommitBundleFor_MockMethod: ((CommitBundle, MLSGroupID) async throws -> [ZMUpdateEvent])?
    public var sendCommitBundleFor_MockValue: [ZMUpdateEvent]?

    public func sendCommitBundle(_ bundle: CommitBundle, for groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        sendCommitBundleFor_Invocations.append((bundle: bundle, groupID: groupID))

        if let error = sendCommitBundleFor_MockError {
            throw error
        }

        if let mock = sendCommitBundleFor_MockMethod {
            return try await mock(bundle, groupID)
        } else if let mock = sendCommitBundleFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendCommitBundleFor`")
        }
    }

    // MARK: - sendExternalCommitBundle

    public var sendExternalCommitBundleFor_Invocations: [(bundle: CommitBundle, groupID: MLSGroupID)] = []
    public var sendExternalCommitBundleFor_MockError: Error?
    public var sendExternalCommitBundleFor_MockMethod: ((CommitBundle, MLSGroupID) async throws -> [ZMUpdateEvent])?
    public var sendExternalCommitBundleFor_MockValue: [ZMUpdateEvent]?

    public func sendExternalCommitBundle(_ bundle: CommitBundle, for groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        sendExternalCommitBundleFor_Invocations.append((bundle: bundle, groupID: groupID))

        if let error = sendExternalCommitBundleFor_MockError {
            throw error
        }

        if let mock = sendExternalCommitBundleFor_MockMethod {
            return try await mock(bundle, groupID)
        } else if let mock = sendExternalCommitBundleFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendExternalCommitBundleFor`")
        }
    }

    // MARK: - onEpochChanged

    public var onEpochChanged_Invocations: [Void] = []
    public var onEpochChanged_MockMethod: (() -> AnyPublisher<MLSGroupID, Never>)?
    public var onEpochChanged_MockValue: AnyPublisher<MLSGroupID, Never>?

    public func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        onEpochChanged_Invocations.append(())

        if let mock = onEpochChanged_MockMethod {
            return mock()
        } else if let mock = onEpochChanged_MockValue {
            return mock
        } else {
            fatalError("no mock for `onEpochChanged`")
        }
    }

}

public class MockConversationEventProcessorProtocol: ConversationEventProcessorProtocol {

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

    // MARK: - processPayload

    public var processPayload_Invocations: [ZMTransportData] = []
    public var processPayload_MockMethod: ((ZMTransportData) -> Void)?

    public func processPayload(_ payload: ZMTransportData) {
        processPayload_Invocations.append(payload)

        guard let mock = processPayload_MockMethod else {
            fatalError("no mock for `processPayload`")
        }

        mock(payload)
    }

}

public class MockCoreCryptoProtocol: CoreCryptoProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - addClientsToConversation

    public var addClientsToConversationConversationIdKeyPackages_Invocations: [(conversationId: Data, keyPackages: [Data])] = []
    public var addClientsToConversationConversationIdKeyPackages_MockError: Error?
    public var addClientsToConversationConversationIdKeyPackages_MockMethod: ((Data, [Data]) async throws -> WireCoreCrypto.MemberAddedMessages)?
    public var addClientsToConversationConversationIdKeyPackages_MockValue: WireCoreCrypto.MemberAddedMessages?

    public func addClientsToConversation(conversationId: Data, keyPackages: [Data]) async throws -> WireCoreCrypto.MemberAddedMessages {
        addClientsToConversationConversationIdKeyPackages_Invocations.append((conversationId: conversationId, keyPackages: keyPackages))

        if let error = addClientsToConversationConversationIdKeyPackages_MockError {
            throw error
        }

        if let mock = addClientsToConversationConversationIdKeyPackages_MockMethod {
            return try await mock(conversationId, keyPackages)
        } else if let mock = addClientsToConversationConversationIdKeyPackages_MockValue {
            return mock
        } else {
            fatalError("no mock for `addClientsToConversationConversationIdKeyPackages`")
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

    public var commitPendingProposalsConversationId_Invocations: [Data] = []
    public var commitPendingProposalsConversationId_MockError: Error?
    public var commitPendingProposalsConversationId_MockMethod: ((Data) async throws -> WireCoreCrypto.CommitBundle?)?
    public var commitPendingProposalsConversationId_MockValue: WireCoreCrypto.CommitBundle??

    public func commitPendingProposals(conversationId: Data) async throws -> WireCoreCrypto.CommitBundle? {
        commitPendingProposalsConversationId_Invocations.append(conversationId)

        if let error = commitPendingProposalsConversationId_MockError {
            throw error
        }

        if let mock = commitPendingProposalsConversationId_MockMethod {
            return try await mock(conversationId)
        } else if let mock = commitPendingProposalsConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `commitPendingProposalsConversationId`")
        }
    }

    // MARK: - conversationEpoch

    public var conversationEpochConversationId_Invocations: [Data] = []
    public var conversationEpochConversationId_MockError: Error?
    public var conversationEpochConversationId_MockMethod: ((Data) async throws -> UInt64)?
    public var conversationEpochConversationId_MockValue: UInt64?

    public func conversationEpoch(conversationId: Data) async throws -> UInt64 {
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

    public var conversationExistsConversationId_Invocations: [Data] = []
    public var conversationExistsConversationId_MockMethod: ((Data) async -> Bool)?
    public var conversationExistsConversationId_MockValue: Bool?

    public func conversationExists(conversationId: Data) async -> Bool {
        conversationExistsConversationId_Invocations.append(conversationId)

        if let mock = conversationExistsConversationId_MockMethod {
            return await mock(conversationId)
        } else if let mock = conversationExistsConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationExistsConversationId`")
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

    public var e2eiMlsInitOnlyEnrollmentCertificateChainNbKeyPackage_Invocations: [(enrollment: WireCoreCrypto.E2eiEnrollment, certificateChain: String, nbKeyPackage: UInt32?)] = []
    public var e2eiMlsInitOnlyEnrollmentCertificateChainNbKeyPackage_MockError: Error?
    public var e2eiMlsInitOnlyEnrollmentCertificateChainNbKeyPackage_MockMethod: ((WireCoreCrypto.E2eiEnrollment, String, UInt32?) async throws -> Void)?

    public func e2eiMlsInitOnly(enrollment: WireCoreCrypto.E2eiEnrollment, certificateChain: String, nbKeyPackage: UInt32?) async throws {
        e2eiMlsInitOnlyEnrollmentCertificateChainNbKeyPackage_Invocations.append((enrollment: enrollment, certificateChain: certificateChain, nbKeyPackage: nbKeyPackage))

        if let error = e2eiMlsInitOnlyEnrollmentCertificateChainNbKeyPackage_MockError {
            throw error
        }

        guard let mock = e2eiMlsInitOnlyEnrollmentCertificateChainNbKeyPackage_MockMethod else {
            fatalError("no mock for `e2eiMlsInitOnlyEnrollmentCertificateChainNbKeyPackage`")
        }

        try await mock(enrollment, certificateChain, nbKeyPackage)
    }

    // MARK: - e2eiNewActivationEnrollment

    public var e2eiNewActivationEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite_Invocations: [(displayName: String, handle: String, team: String?, expiryDays: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite)] = []
    public var e2eiNewActivationEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite_MockError: Error?
    public var e2eiNewActivationEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite_MockMethod: ((String, String, String?, UInt32, WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment)?
    public var e2eiNewActivationEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite_MockValue: WireCoreCrypto.E2eiEnrollment?

    public func e2eiNewActivationEnrollment(displayName: String, handle: String, team: String?, expiryDays: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment {
        e2eiNewActivationEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite_Invocations.append((displayName: displayName, handle: handle, team: team, expiryDays: expiryDays, ciphersuite: ciphersuite))

        if let error = e2eiNewActivationEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite_MockError {
            throw error
        }

        if let mock = e2eiNewActivationEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite_MockMethod {
            return try await mock(displayName, handle, team, expiryDays, ciphersuite)
        } else if let mock = e2eiNewActivationEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiNewActivationEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite`")
        }
    }

    // MARK: - e2eiNewEnrollment

    public var e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpiryDaysCiphersuite_Invocations: [(clientId: String, displayName: String, handle: String, team: String?, expiryDays: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite)] = []
    public var e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpiryDaysCiphersuite_MockError: Error?
    public var e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpiryDaysCiphersuite_MockMethod: ((String, String, String, String?, UInt32, WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment)?
    public var e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpiryDaysCiphersuite_MockValue: WireCoreCrypto.E2eiEnrollment?

    public func e2eiNewEnrollment(clientId: String, displayName: String, handle: String, team: String?, expiryDays: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment {
        e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpiryDaysCiphersuite_Invocations.append((clientId: clientId, displayName: displayName, handle: handle, team: team, expiryDays: expiryDays, ciphersuite: ciphersuite))

        if let error = e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpiryDaysCiphersuite_MockError {
            throw error
        }

        if let mock = e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpiryDaysCiphersuite_MockMethod {
            return try await mock(clientId, displayName, handle, team, expiryDays, ciphersuite)
        } else if let mock = e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpiryDaysCiphersuite_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpiryDaysCiphersuite`")
        }
    }

    // MARK: - e2eiNewRotateEnrollment

    public var e2eiNewRotateEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite_Invocations: [(displayName: String?, handle: String?, team: String?, expiryDays: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite)] = []
    public var e2eiNewRotateEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite_MockError: Error?
    public var e2eiNewRotateEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite_MockMethod: ((String?, String?, String?, UInt32, WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment)?
    public var e2eiNewRotateEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite_MockValue: WireCoreCrypto.E2eiEnrollment?

    public func e2eiNewRotateEnrollment(displayName: String?, handle: String?, team: String?, expiryDays: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment {
        e2eiNewRotateEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite_Invocations.append((displayName: displayName, handle: handle, team: team, expiryDays: expiryDays, ciphersuite: ciphersuite))

        if let error = e2eiNewRotateEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite_MockError {
            throw error
        }

        if let mock = e2eiNewRotateEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite_MockMethod {
            return try await mock(displayName, handle, team, expiryDays, ciphersuite)
        } else if let mock = e2eiNewRotateEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiNewRotateEnrollmentDisplayNameHandleTeamExpiryDaysCiphersuite`")
        }
    }

    // MARK: - e2eiRegisterAcmeCa

    var e2eiRegisterAcmeCaTrustAnchorPem_Invocations: [String] = []
    var e2eiRegisterAcmeCaTrustAnchorPem_MockError: Error?
    var e2eiRegisterAcmeCaTrustAnchorPem_MockMethod: ((String) async throws -> Void)?

    func e2eiRegisterAcmeCa(trustAnchorPem: String) async throws {
        e2eiRegisterAcmeCaTrustAnchorPem_Invocations.append(trustAnchorPem)

        if let error = e2eiRegisterAcmeCaTrustAnchorPem_MockError {
            throw error
        }

        guard let mock = e2eiRegisterAcmeCaTrustAnchorPem_MockMethod else {
            fatalError("no mock for `e2eiRegisterAcmeCaTrustAnchorPem`")
        }

        try await mock(trustAnchorPem)
    }

    // MARK: - e2eiRegisterCrl

    var e2eiRegisterCrlCrlDpCrlDer_Invocations: [(crlDp: String, crlDer: Data)] = []
    var e2eiRegisterCrlCrlDpCrlDer_MockError: Error?
    var e2eiRegisterCrlCrlDpCrlDer_MockMethod: ((String, Data) async throws -> WireCoreCrypto.CrlRegistration)?
    var e2eiRegisterCrlCrlDpCrlDer_MockValue: WireCoreCrypto.CrlRegistration?

    func e2eiRegisterCrl(crlDp: String, crlDer: Data) async throws -> WireCoreCrypto.CrlRegistration {
        e2eiRegisterCrlCrlDpCrlDer_Invocations.append((crlDp: crlDp, crlDer: crlDer))

        if let error = e2eiRegisterCrlCrlDpCrlDer_MockError {
            throw error
        }

        if let mock = e2eiRegisterCrlCrlDpCrlDer_MockMethod {
            return try await mock(crlDp, crlDer)
        } else if let mock = e2eiRegisterCrlCrlDpCrlDer_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiRegisterCrlCrlDpCrlDer`")
        }
    }

    // MARK: - e2eiRegisterIntermediateCa

    var e2eiRegisterIntermediateCaCertPem_Invocations: [String] = []
    var e2eiRegisterIntermediateCaCertPem_MockError: Error?
    var e2eiRegisterIntermediateCaCertPem_MockMethod: ((String) async throws -> Void)?

    func e2eiRegisterIntermediateCa(certPem: String) async throws {
        e2eiRegisterIntermediateCaCertPem_Invocations.append(certPem)

        if let error = e2eiRegisterIntermediateCaCertPem_MockError {
            throw error
        }

        guard let mock = e2eiRegisterIntermediateCaCertPem_MockMethod else {
            fatalError("no mock for `e2eiRegisterIntermediateCaCertPem`")
        }

        try await mock(certPem)
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

    // MARK: - getCredentialInUse

    public var getCredentialInUseGroupInfoCredentialType_Invocations: [(groupInfo: Data, credentialType: WireCoreCrypto.MlsCredentialType)] = []
    public var getCredentialInUseGroupInfoCredentialType_MockError: Error?
    public var getCredentialInUseGroupInfoCredentialType_MockMethod: ((Data, WireCoreCrypto.MlsCredentialType) async throws -> WireCoreCrypto.E2eiConversationState)?
    public var getCredentialInUseGroupInfoCredentialType_MockValue: WireCoreCrypto.E2eiConversationState?

    public func getCredentialInUse(groupInfo: Data, credentialType: WireCoreCrypto.MlsCredentialType) async throws -> WireCoreCrypto.E2eiConversationState {
        getCredentialInUseGroupInfoCredentialType_Invocations.append((groupInfo: groupInfo, credentialType: credentialType))

        if let error = getCredentialInUseGroupInfoCredentialType_MockError {
            throw error
        }

        if let mock = getCredentialInUseGroupInfoCredentialType_MockMethod {
            return try await mock(groupInfo, credentialType)
        } else if let mock = getCredentialInUseGroupInfoCredentialType_MockValue {
            return mock
        } else {
            fatalError("no mock for `getCredentialInUseGroupInfoCredentialType`")
        }
    }

    // MARK: - getDeviceIdentities

    public var getDeviceIdentitiesConversationIdDeviceIds_Invocations: [(conversationId: Data, deviceIds: [WireCoreCrypto.ClientId])] = []
    public var getDeviceIdentitiesConversationIdDeviceIds_MockError: Error?
    public var getDeviceIdentitiesConversationIdDeviceIds_MockMethod: ((Data, [WireCoreCrypto.ClientId]) async throws -> [WireCoreCrypto.WireIdentity])?
    public var getDeviceIdentitiesConversationIdDeviceIds_MockValue: [WireCoreCrypto.WireIdentity]?

    public func getDeviceIdentities(conversationId: Data, deviceIds: [WireCoreCrypto.ClientId]) async throws -> [WireCoreCrypto.WireIdentity] {
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

    // MARK: - getUserIdentities

    public var getUserIdentitiesConversationIdUserIds_Invocations: [(conversationId: Data, userIds: [String])] = []
    public var getUserIdentitiesConversationIdUserIds_MockError: Error?
    public var getUserIdentitiesConversationIdUserIds_MockMethod: ((Data, [String]) async throws -> [String: [WireCoreCrypto.WireIdentity]])?
    public var getUserIdentitiesConversationIdUserIds_MockValue: [String: [WireCoreCrypto.WireIdentity]]?

    public func getUserIdentities(conversationId: Data, userIds: [String]) async throws -> [String: [WireCoreCrypto.WireIdentity]] {
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

    public var mlsInitClientIdCiphersuitesNbKeyPackage_Invocations: [(clientId: WireCoreCrypto.ClientId, ciphersuites: WireCoreCrypto.Ciphersuites, nbKeyPackage: UInt32?)] = []
    public var mlsInitClientIdCiphersuitesNbKeyPackage_MockError: Error?
    public var mlsInitClientIdCiphersuitesNbKeyPackage_MockMethod: ((WireCoreCrypto.ClientId, WireCoreCrypto.Ciphersuites, UInt32?) async throws -> Void)?

    public func mlsInit(clientId: WireCoreCrypto.ClientId, ciphersuites: WireCoreCrypto.Ciphersuites, nbKeyPackage: UInt32?) async throws {
        mlsInitClientIdCiphersuitesNbKeyPackage_Invocations.append((clientId: clientId, ciphersuites: ciphersuites, nbKeyPackage: nbKeyPackage))

        if let error = mlsInitClientIdCiphersuitesNbKeyPackage_MockError {
            throw error
        }

        guard let mock = mlsInitClientIdCiphersuitesNbKeyPackage_MockMethod else {
            fatalError("no mock for `mlsInitClientIdCiphersuitesNbKeyPackage`")
        }

        try await mock(clientId, ciphersuites, nbKeyPackage)
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

public class MockCoreCryptoProviderProtocol: CoreCryptoProviderProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - coreCrypto

    public var coreCryptoRequireMLS_Invocations: [Bool] = []
    public var coreCryptoRequireMLS_MockError: Error?
    public var coreCryptoRequireMLS_MockMethod: ((Bool) async throws -> SafeCoreCryptoProtocol)?
    public var coreCryptoRequireMLS_MockValue: SafeCoreCryptoProtocol?

    public func coreCrypto(requireMLS: Bool) async throws -> SafeCoreCryptoProtocol {
        coreCryptoRequireMLS_Invocations.append(requireMLS)

        if let error = coreCryptoRequireMLS_MockError {
            throw error
        }

        if let mock = coreCryptoRequireMLS_MockMethod {
            return try await mock(requireMLS)
        } else if let mock = coreCryptoRequireMLS_MockValue {
            return mock
        } else {
            fatalError("no mock for `coreCryptoRequireMLS`")
        }
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

public class MockCryptoboxMigrationManagerInterface: CryptoboxMigrationManagerInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - isMigrationNeeded

    public var isMigrationNeededAccountDirectory_Invocations: [URL] = []
    public var isMigrationNeededAccountDirectory_MockMethod: ((URL) -> Bool)?
    public var isMigrationNeededAccountDirectory_MockValue: Bool?

    public func isMigrationNeeded(accountDirectory: URL) -> Bool {
        isMigrationNeededAccountDirectory_Invocations.append(accountDirectory)

        if let mock = isMigrationNeededAccountDirectory_MockMethod {
            return mock(accountDirectory)
        } else if let mock = isMigrationNeededAccountDirectory_MockValue {
            return mock
        } else {
            fatalError("no mock for `isMigrationNeededAccountDirectory`")
        }
    }

    // MARK: - performMigration

    public var performMigrationAccountDirectoryCoreCrypto_Invocations: [(accountDirectory: URL, coreCrypto: SafeCoreCryptoProtocol)] = []
    public var performMigrationAccountDirectoryCoreCrypto_MockError: Error?
    public var performMigrationAccountDirectoryCoreCrypto_MockMethod: ((URL, SafeCoreCryptoProtocol) async throws -> Void)?

    public func performMigration(accountDirectory: URL, coreCrypto: SafeCoreCryptoProtocol) async throws {
        performMigrationAccountDirectoryCoreCrypto_Invocations.append((accountDirectory: accountDirectory, coreCrypto: coreCrypto))

        if let error = performMigrationAccountDirectoryCoreCrypto_MockError {
            throw error
        }

        guard let mock = performMigrationAccountDirectoryCoreCrypto_MockMethod else {
            fatalError("no mock for `performMigrationAccountDirectoryCoreCrypto`")
        }

        try await mock(accountDirectory, coreCrypto)
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

public class MockEARKeyRepositoryInterface: EARKeyRepositoryInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - storePublicKey

    public var storePublicKeyDescriptionKey_Invocations: [(description: PublicEARKeyDescription, key: SecKey)] = []
    public var storePublicKeyDescriptionKey_MockError: Error?
    public var storePublicKeyDescriptionKey_MockMethod: ((PublicEARKeyDescription, SecKey) throws -> Void)?

    public func storePublicKey(description: PublicEARKeyDescription, key: SecKey) throws {
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

    public var fetchPublicKeyDescription_Invocations: [PublicEARKeyDescription] = []
    public var fetchPublicKeyDescription_MockError: Error?
    public var fetchPublicKeyDescription_MockMethod: ((PublicEARKeyDescription) throws -> SecKey)?
    public var fetchPublicKeyDescription_MockValue: SecKey?

    public func fetchPublicKey(description: PublicEARKeyDescription) throws -> SecKey {
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

    public var deletePublicKeyDescription_Invocations: [PublicEARKeyDescription] = []
    public var deletePublicKeyDescription_MockError: Error?
    public var deletePublicKeyDescription_MockMethod: ((PublicEARKeyDescription) throws -> Void)?

    public func deletePublicKey(description: PublicEARKeyDescription) throws {
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

    public var fetchPrivateKeyDescription_Invocations: [PrivateEARKeyDescription] = []
    public var fetchPrivateKeyDescription_MockError: Error?
    public var fetchPrivateKeyDescription_MockMethod: ((PrivateEARKeyDescription) throws -> SecKey)?
    public var fetchPrivateKeyDescription_MockValue: SecKey?

    public func fetchPrivateKey(description: PrivateEARKeyDescription) throws -> SecKey {
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

    public var deletePrivateKeyDescription_Invocations: [PrivateEARKeyDescription] = []
    public var deletePrivateKeyDescription_MockError: Error?
    public var deletePrivateKeyDescription_MockMethod: ((PrivateEARKeyDescription) throws -> Void)?

    public func deletePrivateKey(description: PrivateEARKeyDescription) throws {
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

    public var storeDatabaseKeyDescriptionKey_Invocations: [(description: DatabaseEARKeyDescription, key: Data)] = []
    public var storeDatabaseKeyDescriptionKey_MockError: Error?
    public var storeDatabaseKeyDescriptionKey_MockMethod: ((DatabaseEARKeyDescription, Data) throws -> Void)?

    public func storeDatabaseKey(description: DatabaseEARKeyDescription, key: Data) throws {
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

    public var fetchDatabaseKeyDescription_Invocations: [DatabaseEARKeyDescription] = []
    public var fetchDatabaseKeyDescription_MockError: Error?
    public var fetchDatabaseKeyDescription_MockMethod: ((DatabaseEARKeyDescription) throws -> Data)?
    public var fetchDatabaseKeyDescription_MockValue: Data?

    public func fetchDatabaseKey(description: DatabaseEARKeyDescription) throws -> Data {
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

    public var deleteDatabaseKeyDescription_Invocations: [DatabaseEARKeyDescription] = []
    public var deleteDatabaseKeyDescription_MockError: Error?
    public var deleteDatabaseKeyDescription_MockMethod: ((DatabaseEARKeyDescription) throws -> Void)?

    public func deleteDatabaseKey(description: DatabaseEARKeyDescription) throws {
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

    public var clearCache_Invocations: [Void] = []
    public var clearCache_MockMethod: (() -> Void)?

    public func clearCache() {
        clearCache_Invocations.append(())

        guard let mock = clearCache_MockMethod else {
            fatalError("no mock for `clearCache`")
        }

        mock()
    }

}

public class MockEARServiceInterface: EARServiceInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - delegate

    public var delegate: EARServiceDelegate?


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

    public var unlockDatabaseContext_Invocations: [LAContext] = []
    public var unlockDatabaseContext_MockError: Error?
    public var unlockDatabaseContext_MockMethod: ((LAContext) throws -> Void)?

    public func unlockDatabase(context: LAContext) throws {
        unlockDatabaseContext_Invocations.append(context)

        if let error = unlockDatabaseContext_MockError {
            throw error
        }

        guard let mock = unlockDatabaseContext_MockMethod else {
            fatalError("no mock for `unlockDatabaseContext`")
        }

        try mock(context)
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

public class MockFeatureRepositoryInterface: FeatureRepositoryInterface {

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

    // MARK: - fetchSelfDeletingMesssages

    public var fetchSelfDeletingMesssages_Invocations: [Void] = []
    public var fetchSelfDeletingMesssages_MockMethod: (() -> Feature.SelfDeletingMessages)?
    public var fetchSelfDeletingMesssages_MockValue: Feature.SelfDeletingMessages?

    public func fetchSelfDeletingMesssages() -> Feature.SelfDeletingMessages {
        fetchSelfDeletingMesssages_Invocations.append(())

        if let mock = fetchSelfDeletingMesssages_MockMethod {
            return mock()
        } else if let mock = fetchSelfDeletingMesssages_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfDeletingMesssages`")
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

}

class MockFileManagerInterface: FileManagerInterface {

    // MARK: - Life cycle



    // MARK: - fileExists

    var fileExistsAtPath_Invocations: [String] = []
    var fileExistsAtPath_MockMethod: ((String) -> Bool)?
    var fileExistsAtPath_MockValue: Bool?

    func fileExists(atPath path: String) -> Bool {
        fileExistsAtPath_Invocations.append(path)

        if let mock = fileExistsAtPath_MockMethod {
            return mock(path)
        } else if let mock = fileExistsAtPath_MockValue {
            return mock
        } else {
            fatalError("no mock for `fileExistsAtPath`")
        }
    }

    // MARK: - removeItem

    var removeItemAt_Invocations: [URL] = []
    var removeItemAt_MockError: Error?
    var removeItemAt_MockMethod: ((URL) throws -> Void)?

    func removeItem(at url: URL) throws {
        removeItemAt_Invocations.append(url)

        if let error = removeItemAt_MockError {
            throw error
        }

        guard let mock = removeItemAt_MockMethod else {
            fatalError("no mock for `removeItemAt`")
        }

        try mock(url)
    }

    // MARK: - cryptoboxDirectory

    var cryptoboxDirectoryIn_Invocations: [URL] = []
    var cryptoboxDirectoryIn_MockMethod: ((URL) -> URL)?
    var cryptoboxDirectoryIn_MockValue: URL?

    func cryptoboxDirectory(in accountDirectory: URL) -> URL {
        cryptoboxDirectoryIn_Invocations.append(accountDirectory)

        if let mock = cryptoboxDirectoryIn_MockMethod {
            return mock(accountDirectory)
        } else if let mock = cryptoboxDirectoryIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `cryptoboxDirectoryIn`")
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

    var countUnclaimedKeyPackagesClientIDContext_Invocations: [(clientID: String, context: NotificationContext)] = []
    var countUnclaimedKeyPackagesClientIDContext_MockError: Error?
    var countUnclaimedKeyPackagesClientIDContext_MockMethod: ((String, NotificationContext) async throws -> Int)?
    var countUnclaimedKeyPackagesClientIDContext_MockValue: Int?

    func countUnclaimedKeyPackages(clientID: String, context: NotificationContext) async throws -> Int {
        countUnclaimedKeyPackagesClientIDContext_Invocations.append((clientID: clientID, context: context))

        if let error = countUnclaimedKeyPackagesClientIDContext_MockError {
            throw error
        }

        if let mock = countUnclaimedKeyPackagesClientIDContext_MockMethod {
            return try await mock(clientID, context)
        } else if let mock = countUnclaimedKeyPackagesClientIDContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `countUnclaimedKeyPackagesClientIDContext`")
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

    var claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_Invocations: [(userID: UUID, domain: String?, excludedSelfClientID: String?, context: NotificationContext)] = []
    var claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockError: Error?
    var claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockMethod: ((UUID, String?, String?, NotificationContext) async throws -> [KeyPackage])?
    var claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockValue: [KeyPackage]?

    func claimKeyPackages(userID: UUID, domain: String?, excludedSelfClientID: String?, in context: NotificationContext) async throws -> [KeyPackage] {
        claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_Invocations.append((userID: userID, domain: domain, excludedSelfClientID: excludedSelfClientID, context: context))

        if let error = claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockError {
            throw error
        }

        if let mock = claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockMethod {
            return try await mock(userID, domain, excludedSelfClientID, context)
        } else if let mock = claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `claimKeyPackagesUserIDDomainExcludedSelfClientIDIn`")
        }
    }

    // MARK: - sendMessage

    var sendMessageIn_Invocations: [(message: Data, context: NotificationContext)] = []
    var sendMessageIn_MockError: Error?
    var sendMessageIn_MockMethod: ((Data, NotificationContext) async throws -> [ZMUpdateEvent])?
    var sendMessageIn_MockValue: [ZMUpdateEvent]?

    func sendMessage(_ message: Data, in context: NotificationContext) async throws -> [ZMUpdateEvent] {
        sendMessageIn_Invocations.append((message: message, context: context))

        if let error = sendMessageIn_MockError {
            throw error
        }

        if let mock = sendMessageIn_MockMethod {
            return try await mock(message, context)
        } else if let mock = sendMessageIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendMessageIn`")
        }
    }

    // MARK: - sendCommitBundle

    var sendCommitBundleIn_Invocations: [(bundle: Data, context: NotificationContext)] = []
    var sendCommitBundleIn_MockError: Error?
    var sendCommitBundleIn_MockMethod: ((Data, NotificationContext) async throws -> [ZMUpdateEvent])?
    var sendCommitBundleIn_MockValue: [ZMUpdateEvent]?

    func sendCommitBundle(_ bundle: Data, in context: NotificationContext) async throws -> [ZMUpdateEvent] {
        sendCommitBundleIn_Invocations.append((bundle: bundle, context: context))

        if let error = sendCommitBundleIn_MockError {
            throw error
        }

        if let mock = sendCommitBundleIn_MockMethod {
            return try await mock(bundle, context)
        } else if let mock = sendCommitBundleIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendCommitBundleIn`")
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

    var deleteSubgroupConversationIDDomainSubgroupTypeContext_Invocations: [(conversationID: UUID, domain: String, subgroupType: SubgroupType, context: NotificationContext)] = []
    var deleteSubgroupConversationIDDomainSubgroupTypeContext_MockError: Error?
    var deleteSubgroupConversationIDDomainSubgroupTypeContext_MockMethod: ((UUID, String, SubgroupType, NotificationContext) async throws -> Void)?

    func deleteSubgroup(conversationID: UUID, domain: String, subgroupType: SubgroupType, context: NotificationContext) async throws {
        deleteSubgroupConversationIDDomainSubgroupTypeContext_Invocations.append((conversationID: conversationID, domain: domain, subgroupType: subgroupType, context: context))

        if let error = deleteSubgroupConversationIDDomainSubgroupTypeContext_MockError {
            throw error
        }

        guard let mock = deleteSubgroupConversationIDDomainSubgroupTypeContext_MockMethod else {
            fatalError("no mock for `deleteSubgroupConversationIDDomainSubgroupTypeContext`")
        }

        try await mock(conversationID, domain, subgroupType, context)
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

public class MockMLSDecryptionServiceInterface: MLSDecryptionServiceInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - onEpochChanged

    public var onEpochChanged_Invocations: [Void] = []
    public var onEpochChanged_MockMethod: (() -> AnyPublisher<MLSGroupID, Never>)?
    public var onEpochChanged_MockValue: AnyPublisher<MLSGroupID, Never>?

    public func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        onEpochChanged_Invocations.append(())

        if let mock = onEpochChanged_MockMethod {
            return mock()
        } else if let mock = onEpochChanged_MockValue {
            return mock
        } else {
            fatalError("no mock for `onEpochChanged`")
        }
    }

    // MARK: - decrypt

    public var decryptMessageForSubconversationType_Invocations: [(message: String, groupID: MLSGroupID, subconversationType: SubgroupType?)] = []
    public var decryptMessageForSubconversationType_MockError: Error?
    public var decryptMessageForSubconversationType_MockMethod: ((String, MLSGroupID, SubgroupType?) async throws -> [MLSDecryptResult])?
    public var decryptMessageForSubconversationType_MockValue: [MLSDecryptResult]?

    public func decrypt(message: String, for groupID: MLSGroupID, subconversationType: SubgroupType?) async throws -> [MLSDecryptResult] {
        decryptMessageForSubconversationType_Invocations.append((message: message, groupID: groupID, subconversationType: subconversationType))

        if let error = decryptMessageForSubconversationType_MockError {
            throw error
        }

        if let mock = decryptMessageForSubconversationType_MockMethod {
            return try await mock(message, groupID, subconversationType)
        } else if let mock = decryptMessageForSubconversationType_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptMessageForSubconversationType`")
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

public class MockMLSServiceInterface: MLSServiceInterface {

    // MARK: - Life cycle

    public init() {}


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

    // MARK: - createSelfGroup

    public var createSelfGroupFor_Invocations: [MLSGroupID] = []
    public var createSelfGroupFor_MockMethod: ((MLSGroupID) async -> Void)?

    public func createSelfGroup(for groupID: MLSGroupID) async {
        createSelfGroupFor_Invocations.append(groupID)

        guard let mock = createSelfGroupFor_MockMethod else {
            fatalError("no mock for `createSelfGroupFor`")
        }

        await mock(groupID)
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

    // MARK: - createGroup

    public var createGroupForWith_Invocations: [(groupID: MLSGroupID, users: [MLSUser])] = []
    public var createGroupForWith_MockError: Error?
    public var createGroupForWith_MockMethod: ((MLSGroupID, [MLSUser]) async throws -> Void)?

    public func createGroup(for groupID: MLSGroupID, with users: [MLSUser]) async throws {
        createGroupForWith_Invocations.append((groupID: groupID, users: users))

        if let error = createGroupForWith_MockError {
            throw error
        }

        guard let mock = createGroupForWith_MockMethod else {
            fatalError("no mock for `createGroupForWith`")
        }

        try await mock(groupID, users)
    }

    // MARK: - conversationExists

    public var conversationExistsGroupID_Invocations: [MLSGroupID] = []
    public var conversationExistsGroupID_MockMethod: ((MLSGroupID) async -> Bool)?
    public var conversationExistsGroupID_MockValue: Bool?

    public func conversationExists(groupID: MLSGroupID) async -> Bool {
        conversationExistsGroupID_Invocations.append(groupID)

        if let mock = conversationExistsGroupID_MockMethod {
            return await mock(groupID)
        } else if let mock = conversationExistsGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationExistsGroupID`")
        }
    }

    // MARK: - processWelcomeMessage

    public var processWelcomeMessageWelcomeMessage_Invocations: [String] = []
    public var processWelcomeMessageWelcomeMessage_MockError: Error?
    public var processWelcomeMessageWelcomeMessage_MockMethod: ((String) async throws -> MLSGroupID)?
    public var processWelcomeMessageWelcomeMessage_MockValue: MLSGroupID?

    public func processWelcomeMessage(welcomeMessage: String) async throws -> MLSGroupID {
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

    // MARK: - commitPendingProposals

    public var commitPendingProposals_Invocations: [Void] = []
    public var commitPendingProposals_MockError: Error?
    public var commitPendingProposals_MockMethod: (() async throws -> Void)?

    public func commitPendingProposals() async throws {
        commitPendingProposals_Invocations.append(())

        if let error = commitPendingProposals_MockError {
            throw error
        }

        guard let mock = commitPendingProposals_MockMethod else {
            fatalError("no mock for `commitPendingProposals`")
        }

        try await mock()
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

    // MARK: - generateNewEpoch

    public var generateNewEpochGroupID_Invocations: [MLSGroupID] = []
    public var generateNewEpochGroupID_MockError: Error?
    public var generateNewEpochGroupID_MockMethod: ((MLSGroupID) async throws -> Void)?

    public func generateNewEpoch(groupID: MLSGroupID) async throws {
        generateNewEpochGroupID_Invocations.append(groupID)

        if let error = generateNewEpochGroupID_MockError {
            throw error
        }

        guard let mock = generateNewEpochGroupID_MockMethod else {
            fatalError("no mock for `generateNewEpochGroupID`")
        }

        try await mock(groupID)
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

    // MARK: - repairOutOfSyncConversations

    public var repairOutOfSyncConversations_Invocations: [Void] = []
    public var repairOutOfSyncConversations_MockMethod: (() async -> Void)?

    public func repairOutOfSyncConversations() async {
        repairOutOfSyncConversations_Invocations.append(())

        guard let mock = repairOutOfSyncConversations_MockMethod else {
            fatalError("no mock for `repairOutOfSyncConversations`")
        }

        await mock()
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

    // MARK: - onEpochChanged

    public var onEpochChanged_Invocations: [Void] = []
    public var onEpochChanged_MockMethod: (() -> AnyPublisher<MLSGroupID, Never>)?
    public var onEpochChanged_MockValue: AnyPublisher<MLSGroupID, Never>?

    public func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        onEpochChanged_Invocations.append(())

        if let mock = onEpochChanged_MockMethod {
            return mock()
        } else if let mock = onEpochChanged_MockValue {
            return mock
        } else {
            fatalError("no mock for `onEpochChanged`")
        }
    }

    // MARK: - decrypt

    public var decryptMessageForSubconversationType_Invocations: [(message: String, groupID: MLSGroupID, subconversationType: SubgroupType?)] = []
    public var decryptMessageForSubconversationType_MockError: Error?
    public var decryptMessageForSubconversationType_MockMethod: ((String, MLSGroupID, SubgroupType?) async throws -> [MLSDecryptResult])?
    public var decryptMessageForSubconversationType_MockValue: [MLSDecryptResult]?

    public func decrypt(message: String, for groupID: MLSGroupID, subconversationType: SubgroupType?) async throws -> [MLSDecryptResult] {
        decryptMessageForSubconversationType_Invocations.append((message: message, groupID: groupID, subconversationType: subconversationType))

        if let error = decryptMessageForSubconversationType_MockError {
            throw error
        }

        if let mock = decryptMessageForSubconversationType_MockMethod {
            return try await mock(message, groupID, subconversationType)
        } else if let mock = decryptMessageForSubconversationType_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptMessageForSubconversationType`")
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
    public var migrateToMLSUserIDIn_MockMethod: ((QualifiedID, NSManagedObjectContext) async throws -> Void)?

    public func migrateToMLS(userID: QualifiedID, in context: NSManagedObjectContext) async throws {
        migrateToMLSUserIDIn_Invocations.append((userID: userID, context: context))

        if let error = migrateToMLSUserIDIn_MockError {
            throw error
        }

        guard let mock = migrateToMLSUserIDIn_MockMethod else {
            fatalError("no mock for `migrateToMLSUserIDIn`")
        }

        try await mock(userID, context)
    }

}

public class MockOneOnOneProtocolSelectorInterface: OneOnOneProtocolSelectorInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - getProtocolForUser

    public var getProtocolForUserWithIn_Invocations: [(id: QualifiedID, context: NSManagedObjectContext)] = []
    public var getProtocolForUserWithIn_MockMethod: ((QualifiedID, NSManagedObjectContext) -> MessageProtocol?)?
    public var getProtocolForUserWithIn_MockValue: MessageProtocol??

    public func getProtocolForUser(with id: QualifiedID, in context: NSManagedObjectContext) -> MessageProtocol? {
        getProtocolForUserWithIn_Invocations.append((id: id, context: context))

        if let mock = getProtocolForUserWithIn_MockMethod {
            return mock(id, context)
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


    // MARK: - resolveOneOnOneConversation

    public var resolveOneOnOneConversationWithIn_Invocations: [(userID: QualifiedID, context: NSManagedObjectContext)] = []
    public var resolveOneOnOneConversationWithIn_MockError: Error?
    public var resolveOneOnOneConversationWithIn_MockMethod: ((QualifiedID, NSManagedObjectContext) async throws -> Void)?

    public func resolveOneOnOneConversation(with userID: QualifiedID, in context: NSManagedObjectContext) async throws {
        resolveOneOnOneConversationWithIn_Invocations.append((userID: userID, context: context))

        if let error = resolveOneOnOneConversationWithIn_MockError {
            throw error
        }

        guard let mock = resolveOneOnOneConversationWithIn_MockMethod else {
            fatalError("no mock for `resolveOneOnOneConversationWithIn`")
        }

        try await mock(userID, context)
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
            if let lastPrekeyIDClosure = lastPrekeyIDClosure {
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

    public var decryptDataForSession_Invocations: [(data: Data, id: ProteusSessionID)] = []
    public var decryptDataForSession_MockError: Error?
    public var decryptDataForSession_MockMethod: ((Data, ProteusSessionID) async throws -> (didCreateNewSession: Bool, decryptedData: Data))?
    public var decryptDataForSession_MockValue: (didCreateNewSession: Bool, decryptedData: Data)?

    public func decrypt(data: Data, forSession id: ProteusSessionID) async throws -> (didCreateNewSession: Bool, decryptedData: Data) {
        decryptDataForSession_Invocations.append((data: data, id: id))

        if let error = decryptDataForSession_MockError {
            throw error
        }

        if let mock = decryptDataForSession_MockMethod {
            return try await mock(data, id)
        } else if let mock = decryptDataForSession_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptDataForSession`")
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

class MockProteusToMLSMigrationStorageInterface: ProteusToMLSMigrationStorageInterface {

    // MARK: - Life cycle


    // MARK: - migrationStatus

    var migrationStatus: ProteusToMLSMigrationCoordinator.MigrationStatus {
        get { return underlyingMigrationStatus }
        set(value) { underlyingMigrationStatus = value }
    }

    var underlyingMigrationStatus: ProteusToMLSMigrationCoordinator.MigrationStatus!


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

public class MockUserRepositoryInterface: UserRepositoryInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - selfUser

    public var selfUser_Invocations: [Void] = []
    public var selfUser_MockMethod: (() -> ZMUser)?
    public var selfUser_MockValue: ZMUser?

    public func selfUser() -> ZMUser {
        selfUser_Invocations.append(())

        if let mock = selfUser_MockMethod {
            return mock()
        } else if let mock = selfUser_MockValue {
            return mock
        } else {
            fatalError("no mock for `selfUser`")
        }
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
