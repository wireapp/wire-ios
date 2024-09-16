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

public class MockCRLExpirationDatesRepositoryProtocol: CRLExpirationDatesRepositoryProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - crlExpirationDateExists

    public var crlExpirationDateExistsFor_Invocations: [URL] = []
    public var crlExpirationDateExistsFor_MockMethod: ((URL) -> Bool)?
    public var crlExpirationDateExistsFor_MockValue: Bool?

    public func crlExpirationDateExists(for distributionPoint: URL) -> Bool {
        crlExpirationDateExistsFor_Invocations.append(distributionPoint)

        if let mock = crlExpirationDateExistsFor_MockMethod {
            return mock(distributionPoint)
        } else if let mock = crlExpirationDateExistsFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `crlExpirationDateExistsFor`")
        }
    }

    // MARK: - storeCRLExpirationDate

    public var storeCRLExpirationDateFor_Invocations: [(expirationDate: Date, distributionPoint: URL)] = []
    public var storeCRLExpirationDateFor_MockMethod: ((Date, URL) -> Void)?

    public func storeCRLExpirationDate(_ expirationDate: Date, for distributionPoint: URL) {
        storeCRLExpirationDateFor_Invocations.append((expirationDate: expirationDate, distributionPoint: distributionPoint))

        guard let mock = storeCRLExpirationDateFor_MockMethod else {
            fatalError("no mock for `storeCRLExpirationDateFor`")
        }

        mock(expirationDate, distributionPoint)
    }

    // MARK: - fetchAllCRLExpirationDates

    public var fetchAllCRLExpirationDates_Invocations: [Void] = []
    public var fetchAllCRLExpirationDates_MockMethod: (() -> [URL: Date])?
    public var fetchAllCRLExpirationDates_MockValue: [URL: Date]?

    public func fetchAllCRLExpirationDates() -> [URL: Date] {
        fetchAllCRLExpirationDates_Invocations.append(())

        if let mock = fetchAllCRLExpirationDates_MockMethod {
            return mock()
        } else if let mock = fetchAllCRLExpirationDates_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchAllCRLExpirationDates`")
        }
    }

}

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

public class MockConversationLike: ConversationLike {

    // MARK: - Life cycle

    public init() {}

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

    // MARK: - allowServices

    public var allowServices: Bool {
        get { return underlyingAllowServices }
        set(value) { underlyingAllowServices = value }
    }

    public var underlyingAllowServices: Bool!

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

    // MARK: - areServicesPresent

    public var areServicesPresent: Bool {
        get { return underlyingAreServicesPresent }
        set(value) { underlyingAreServicesPresent = value }
    }

    public var underlyingAreServicesPresent: Bool!

    // MARK: - domain

    public var domain: String?


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

    public var clientPublicKeyCiphersuiteCredentialType_Invocations: [(ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType)] = []
    public var clientPublicKeyCiphersuiteCredentialType_MockError: Error?
    public var clientPublicKeyCiphersuiteCredentialType_MockMethod: ((WireCoreCrypto.Ciphersuite, WireCoreCrypto.MlsCredentialType) async throws -> Data)?
    public var clientPublicKeyCiphersuiteCredentialType_MockValue: Data?

    public func clientPublicKey(ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType) async throws -> Data {
        clientPublicKeyCiphersuiteCredentialType_Invocations.append((ciphersuite: ciphersuite, credentialType: credentialType))

        if let error = clientPublicKeyCiphersuiteCredentialType_MockError {
            throw error
        }

        if let mock = clientPublicKeyCiphersuiteCredentialType_MockMethod {
            return try await mock(ciphersuite, credentialType)
        } else if let mock = clientPublicKeyCiphersuiteCredentialType_MockValue {
            return mock
        } else {
            fatalError("no mock for `clientPublicKeyCiphersuiteCredentialType`")
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

    // MARK: - conversationCiphersuite

    public var conversationCiphersuiteConversationId_Invocations: [Data] = []
    public var conversationCiphersuiteConversationId_MockError: Error?
    public var conversationCiphersuiteConversationId_MockMethod: ((Data) async throws -> WireCoreCrypto.Ciphersuite)?
    public var conversationCiphersuiteConversationId_MockValue: WireCoreCrypto.Ciphersuite?

    public func conversationCiphersuite(conversationId: Data) async throws -> WireCoreCrypto.Ciphersuite {
        conversationCiphersuiteConversationId_Invocations.append(conversationId)

        if let error = conversationCiphersuiteConversationId_MockError {
            throw error
        }

        if let mock = conversationCiphersuiteConversationId_MockMethod {
            return try await mock(conversationId)
        } else if let mock = conversationCiphersuiteConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationCiphersuiteConversationId`")
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

    // MARK: - e2eiDumpPkiEnv

    public var e2eiDumpPkiEnv_Invocations: [Void] = []
    public var e2eiDumpPkiEnv_MockError: Error?
    public var e2eiDumpPkiEnv_MockMethod: (() async throws -> WireCoreCrypto.E2eiDumpedPkiEnv?)?
    public var e2eiDumpPkiEnv_MockValue: WireCoreCrypto.E2eiDumpedPkiEnv??

    public func e2eiDumpPkiEnv() async throws -> WireCoreCrypto.E2eiDumpedPkiEnv? {
        e2eiDumpPkiEnv_Invocations.append(())

        if let error = e2eiDumpPkiEnv_MockError {
            throw error
        }

        if let mock = e2eiDumpPkiEnv_MockMethod {
            return try await mock()
        } else if let mock = e2eiDumpPkiEnv_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiDumpPkiEnv`")
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

    // MARK: - e2eiIsPkiEnvSetup

    public var e2eiIsPkiEnvSetup_Invocations: [Void] = []
    public var e2eiIsPkiEnvSetup_MockMethod: (() async -> Bool)?
    public var e2eiIsPkiEnvSetup_MockValue: Bool?

    public func e2eiIsPkiEnvSetup() async -> Bool {
        e2eiIsPkiEnvSetup_Invocations.append(())

        if let mock = e2eiIsPkiEnvSetup_MockMethod {
            return await mock()
        } else if let mock = e2eiIsPkiEnvSetup_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiIsPkiEnvSetup`")
        }
    }

    // MARK: - e2eiMlsInitOnly

    public var e2eiMlsInitOnlyEnrollmentCertificateChainNbKeyPackage_Invocations: [(enrollment: WireCoreCrypto.E2eiEnrollment, certificateChain: String, nbKeyPackage: UInt32?)] = []
    public var e2eiMlsInitOnlyEnrollmentCertificateChainNbKeyPackage_MockError: Error?
    public var e2eiMlsInitOnlyEnrollmentCertificateChainNbKeyPackage_MockMethod: ((WireCoreCrypto.E2eiEnrollment, String, UInt32?) async throws -> [String]?)?
    public var e2eiMlsInitOnlyEnrollmentCertificateChainNbKeyPackage_MockValue: [String]??

    public func e2eiMlsInitOnly(enrollment: WireCoreCrypto.E2eiEnrollment, certificateChain: String, nbKeyPackage: UInt32?) async throws -> [String]? {
        e2eiMlsInitOnlyEnrollmentCertificateChainNbKeyPackage_Invocations.append((enrollment: enrollment, certificateChain: certificateChain, nbKeyPackage: nbKeyPackage))

        if let error = e2eiMlsInitOnlyEnrollmentCertificateChainNbKeyPackage_MockError {
            throw error
        }

        if let mock = e2eiMlsInitOnlyEnrollmentCertificateChainNbKeyPackage_MockMethod {
            return try await mock(enrollment, certificateChain, nbKeyPackage)
        } else if let mock = e2eiMlsInitOnlyEnrollmentCertificateChainNbKeyPackage_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiMlsInitOnlyEnrollmentCertificateChainNbKeyPackage`")
        }
    }

    // MARK: - e2eiNewActivationEnrollment

    public var e2eiNewActivationEnrollmentDisplayNameHandleTeamExpirySecCiphersuite_Invocations: [(displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite)] = []
    public var e2eiNewActivationEnrollmentDisplayNameHandleTeamExpirySecCiphersuite_MockError: Error?
    public var e2eiNewActivationEnrollmentDisplayNameHandleTeamExpirySecCiphersuite_MockMethod: ((String, String, String?, UInt32, WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment)?
    public var e2eiNewActivationEnrollmentDisplayNameHandleTeamExpirySecCiphersuite_MockValue: WireCoreCrypto.E2eiEnrollment?

    public func e2eiNewActivationEnrollment(displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment {
        e2eiNewActivationEnrollmentDisplayNameHandleTeamExpirySecCiphersuite_Invocations.append((displayName: displayName, handle: handle, team: team, expirySec: expirySec, ciphersuite: ciphersuite))

        if let error = e2eiNewActivationEnrollmentDisplayNameHandleTeamExpirySecCiphersuite_MockError {
            throw error
        }

        if let mock = e2eiNewActivationEnrollmentDisplayNameHandleTeamExpirySecCiphersuite_MockMethod {
            return try await mock(displayName, handle, team, expirySec, ciphersuite)
        } else if let mock = e2eiNewActivationEnrollmentDisplayNameHandleTeamExpirySecCiphersuite_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiNewActivationEnrollmentDisplayNameHandleTeamExpirySecCiphersuite`")
        }
    }

    // MARK: - e2eiNewEnrollment

    public var e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpirySecCiphersuite_Invocations: [(clientId: String, displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite)] = []
    public var e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpirySecCiphersuite_MockError: Error?
    public var e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpirySecCiphersuite_MockMethod: ((String, String, String, String?, UInt32, WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment)?
    public var e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpirySecCiphersuite_MockValue: WireCoreCrypto.E2eiEnrollment?

    public func e2eiNewEnrollment(clientId: String, displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment {
        e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpirySecCiphersuite_Invocations.append((clientId: clientId, displayName: displayName, handle: handle, team: team, expirySec: expirySec, ciphersuite: ciphersuite))

        if let error = e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpirySecCiphersuite_MockError {
            throw error
        }

        if let mock = e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpirySecCiphersuite_MockMethod {
            return try await mock(clientId, displayName, handle, team, expirySec, ciphersuite)
        } else if let mock = e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpirySecCiphersuite_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiNewEnrollmentClientIdDisplayNameHandleTeamExpirySecCiphersuite`")
        }
    }

    // MARK: - e2eiNewRotateEnrollment

    public var e2eiNewRotateEnrollmentDisplayNameHandleTeamExpirySecCiphersuite_Invocations: [(displayName: String?, handle: String?, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite)] = []
    public var e2eiNewRotateEnrollmentDisplayNameHandleTeamExpirySecCiphersuite_MockError: Error?
    public var e2eiNewRotateEnrollmentDisplayNameHandleTeamExpirySecCiphersuite_MockMethod: ((String?, String?, String?, UInt32, WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment)?
    public var e2eiNewRotateEnrollmentDisplayNameHandleTeamExpirySecCiphersuite_MockValue: WireCoreCrypto.E2eiEnrollment?

    public func e2eiNewRotateEnrollment(displayName: String?, handle: String?, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment {
        e2eiNewRotateEnrollmentDisplayNameHandleTeamExpirySecCiphersuite_Invocations.append((displayName: displayName, handle: handle, team: team, expirySec: expirySec, ciphersuite: ciphersuite))

        if let error = e2eiNewRotateEnrollmentDisplayNameHandleTeamExpirySecCiphersuite_MockError {
            throw error
        }

        if let mock = e2eiNewRotateEnrollmentDisplayNameHandleTeamExpirySecCiphersuite_MockMethod {
            return try await mock(displayName, handle, team, expirySec, ciphersuite)
        } else if let mock = e2eiNewRotateEnrollmentDisplayNameHandleTeamExpirySecCiphersuite_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiNewRotateEnrollmentDisplayNameHandleTeamExpirySecCiphersuite`")
        }
    }

    // MARK: - e2eiRegisterAcmeCa

    public var e2eiRegisterAcmeCaTrustAnchorPem_Invocations: [String] = []
    public var e2eiRegisterAcmeCaTrustAnchorPem_MockError: Error?
    public var e2eiRegisterAcmeCaTrustAnchorPem_MockMethod: ((String) async throws -> Void)?

    public func e2eiRegisterAcmeCa(trustAnchorPem: String) async throws {
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

    public var e2eiRegisterCrlCrlDpCrlDer_Invocations: [(crlDp: String, crlDer: Data)] = []
    public var e2eiRegisterCrlCrlDpCrlDer_MockError: Error?
    public var e2eiRegisterCrlCrlDpCrlDer_MockMethod: ((String, Data) async throws -> WireCoreCrypto.CrlRegistration)?
    public var e2eiRegisterCrlCrlDpCrlDer_MockValue: WireCoreCrypto.CrlRegistration?

    public func e2eiRegisterCrl(crlDp: String, crlDer: Data) async throws -> WireCoreCrypto.CrlRegistration {
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

    public var e2eiRegisterIntermediateCaCertPem_Invocations: [String] = []
    public var e2eiRegisterIntermediateCaCertPem_MockError: Error?
    public var e2eiRegisterIntermediateCaCertPem_MockMethod: ((String) async throws -> [String]?)?
    public var e2eiRegisterIntermediateCaCertPem_MockValue: [String]??

    public func e2eiRegisterIntermediateCa(certPem: String) async throws -> [String]? {
        e2eiRegisterIntermediateCaCertPem_Invocations.append(certPem)

        if let error = e2eiRegisterIntermediateCaCertPem_MockError {
            throw error
        }

        if let mock = e2eiRegisterIntermediateCaCertPem_MockMethod {
            return try await mock(certPem)
        } else if let mock = e2eiRegisterIntermediateCaCertPem_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiRegisterIntermediateCaCertPem`")
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

    // MARK: - getExternalSender

    public var getExternalSenderConversationId_Invocations: [Data] = []
    public var getExternalSenderConversationId_MockError: Error?
    public var getExternalSenderConversationId_MockMethod: ((Data) async throws -> Data)?
    public var getExternalSenderConversationId_MockValue: Data?

    public func getExternalSender(conversationId: Data) async throws -> Data {
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
    public var processWelcomeMessageWelcomeMessageCustomConfiguration_MockMethod: ((Data, WireCoreCrypto.CustomConfiguration) async throws -> WireCoreCrypto.WelcomeBundle)?
    public var processWelcomeMessageWelcomeMessageCustomConfiguration_MockValue: WireCoreCrypto.WelcomeBundle?

    public func processWelcomeMessage(welcomeMessage: Data, customConfiguration: WireCoreCrypto.CustomConfiguration) async throws -> WireCoreCrypto.WelcomeBundle {
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

    public var setCallbacksCallbacks_Invocations: [any WireCoreCrypto.CoreCryptoCallbacks] = []
    public var setCallbacksCallbacks_MockError: Error?
    public var setCallbacksCallbacks_MockMethod: ((any WireCoreCrypto.CoreCryptoCallbacks) async throws -> Void)?

    public func setCallbacks(callbacks: any WireCoreCrypto.CoreCryptoCallbacks) async throws {
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

    public var coreCrypto_Invocations: [Void] = []
    public var coreCrypto_MockError: Error?
    public var coreCrypto_MockMethod: (() async throws -> SafeCoreCryptoProtocol)?
    public var coreCrypto_MockValue: SafeCoreCryptoProtocol?

    public func coreCrypto() async throws -> SafeCoreCryptoProtocol {
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

    public var initialiseMLSWithEndToEndIdentityEnrollmentCertificateChain_Invocations: [(enrollment: E2eiEnrollment, certificateChain: String)] = []
    public var initialiseMLSWithEndToEndIdentityEnrollmentCertificateChain_MockError: Error?
    public var initialiseMLSWithEndToEndIdentityEnrollmentCertificateChain_MockMethod: ((E2eiEnrollment, String) async throws -> CRLsDistributionPoints?)?
    public var initialiseMLSWithEndToEndIdentityEnrollmentCertificateChain_MockValue: CRLsDistributionPoints??

    public func initialiseMLSWithEndToEndIdentity(enrollment: E2eiEnrollment, certificateChain: String) async throws -> CRLsDistributionPoints? {
        initialiseMLSWithEndToEndIdentityEnrollmentCertificateChain_Invocations.append((enrollment: enrollment, certificateChain: certificateChain))

        if let error = initialiseMLSWithEndToEndIdentityEnrollmentCertificateChain_MockError {
            throw error
        }

        if let mock = initialiseMLSWithEndToEndIdentityEnrollmentCertificateChain_MockMethod {
            return try await mock(enrollment, certificateChain)
        } else if let mock = initialiseMLSWithEndToEndIdentityEnrollmentCertificateChain_MockValue {
            return mock
        } else {
            fatalError("no mock for `initialiseMLSWithEndToEndIdentityEnrollmentCertificateChain`")
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

public class MockE2EIServiceInterface: E2EIServiceInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - e2eIdentity

    public var e2eIdentity: E2eiEnrollmentProtocol {
        get { return underlyingE2eIdentity }
        set(value) { underlyingE2eIdentity = value }
    }

    public var underlyingE2eIdentity: E2eiEnrollmentProtocol!


    // MARK: - getDirectoryResponse

    public var getDirectoryResponseDirectoryData_Invocations: [Data] = []
    public var getDirectoryResponseDirectoryData_MockError: Error?
    public var getDirectoryResponseDirectoryData_MockMethod: ((Data) async throws -> AcmeDirectory)?
    public var getDirectoryResponseDirectoryData_MockValue: AcmeDirectory?

    public func getDirectoryResponse(directoryData: Data) async throws -> AcmeDirectory {
        getDirectoryResponseDirectoryData_Invocations.append(directoryData)

        if let error = getDirectoryResponseDirectoryData_MockError {
            throw error
        }

        if let mock = getDirectoryResponseDirectoryData_MockMethod {
            return try await mock(directoryData)
        } else if let mock = getDirectoryResponseDirectoryData_MockValue {
            return mock
        } else {
            fatalError("no mock for `getDirectoryResponseDirectoryData`")
        }
    }

    // MARK: - getNewAccountRequest

    public var getNewAccountRequestNonce_Invocations: [String] = []
    public var getNewAccountRequestNonce_MockError: Error?
    public var getNewAccountRequestNonce_MockMethod: ((String) async throws -> Data)?
    public var getNewAccountRequestNonce_MockValue: Data?

    public func getNewAccountRequest(nonce: String) async throws -> Data {
        getNewAccountRequestNonce_Invocations.append(nonce)

        if let error = getNewAccountRequestNonce_MockError {
            throw error
        }

        if let mock = getNewAccountRequestNonce_MockMethod {
            return try await mock(nonce)
        } else if let mock = getNewAccountRequestNonce_MockValue {
            return mock
        } else {
            fatalError("no mock for `getNewAccountRequestNonce`")
        }
    }

    // MARK: - setAccountResponse

    public var setAccountResponseAccountData_Invocations: [Data] = []
    public var setAccountResponseAccountData_MockError: Error?
    public var setAccountResponseAccountData_MockMethod: ((Data) async throws -> Void)?

    public func setAccountResponse(accountData: Data) async throws {
        setAccountResponseAccountData_Invocations.append(accountData)

        if let error = setAccountResponseAccountData_MockError {
            throw error
        }

        guard let mock = setAccountResponseAccountData_MockMethod else {
            fatalError("no mock for `setAccountResponseAccountData`")
        }

        try await mock(accountData)
    }

    // MARK: - getNewOrderRequest

    public var getNewOrderRequestNonce_Invocations: [String] = []
    public var getNewOrderRequestNonce_MockError: Error?
    public var getNewOrderRequestNonce_MockMethod: ((String) async throws -> Data)?
    public var getNewOrderRequestNonce_MockValue: Data?

    public func getNewOrderRequest(nonce: String) async throws -> Data {
        getNewOrderRequestNonce_Invocations.append(nonce)

        if let error = getNewOrderRequestNonce_MockError {
            throw error
        }

        if let mock = getNewOrderRequestNonce_MockMethod {
            return try await mock(nonce)
        } else if let mock = getNewOrderRequestNonce_MockValue {
            return mock
        } else {
            fatalError("no mock for `getNewOrderRequestNonce`")
        }
    }

    // MARK: - setOrderResponse

    public var setOrderResponseOrder_Invocations: [Data] = []
    public var setOrderResponseOrder_MockError: Error?
    public var setOrderResponseOrder_MockMethod: ((Data) async throws -> NewAcmeOrder)?
    public var setOrderResponseOrder_MockValue: NewAcmeOrder?

    public func setOrderResponse(order: Data) async throws -> NewAcmeOrder {
        setOrderResponseOrder_Invocations.append(order)

        if let error = setOrderResponseOrder_MockError {
            throw error
        }

        if let mock = setOrderResponseOrder_MockMethod {
            return try await mock(order)
        } else if let mock = setOrderResponseOrder_MockValue {
            return mock
        } else {
            fatalError("no mock for `setOrderResponseOrder`")
        }
    }

    // MARK: - getNewAuthzRequest

    public var getNewAuthzRequestUrlPreviousNonce_Invocations: [(url: String, previousNonce: String)] = []
    public var getNewAuthzRequestUrlPreviousNonce_MockError: Error?
    public var getNewAuthzRequestUrlPreviousNonce_MockMethod: ((String, String) async throws -> Data)?
    public var getNewAuthzRequestUrlPreviousNonce_MockValue: Data?

    public func getNewAuthzRequest(url: String, previousNonce: String) async throws -> Data {
        getNewAuthzRequestUrlPreviousNonce_Invocations.append((url: url, previousNonce: previousNonce))

        if let error = getNewAuthzRequestUrlPreviousNonce_MockError {
            throw error
        }

        if let mock = getNewAuthzRequestUrlPreviousNonce_MockMethod {
            return try await mock(url, previousNonce)
        } else if let mock = getNewAuthzRequestUrlPreviousNonce_MockValue {
            return mock
        } else {
            fatalError("no mock for `getNewAuthzRequestUrlPreviousNonce`")
        }
    }

    // MARK: - setAuthzResponse

    public var setAuthzResponseAuthz_Invocations: [Data] = []
    public var setAuthzResponseAuthz_MockError: Error?
    public var setAuthzResponseAuthz_MockMethod: ((Data) async throws -> NewAcmeAuthz)?
    public var setAuthzResponseAuthz_MockValue: NewAcmeAuthz?

    public func setAuthzResponse(authz: Data) async throws -> NewAcmeAuthz {
        setAuthzResponseAuthz_Invocations.append(authz)

        if let error = setAuthzResponseAuthz_MockError {
            throw error
        }

        if let mock = setAuthzResponseAuthz_MockMethod {
            return try await mock(authz)
        } else if let mock = setAuthzResponseAuthz_MockValue {
            return mock
        } else {
            fatalError("no mock for `setAuthzResponseAuthz`")
        }
    }

    // MARK: - getOAuthRefreshToken

    public var getOAuthRefreshToken_Invocations: [Void] = []
    public var getOAuthRefreshToken_MockError: Error?
    public var getOAuthRefreshToken_MockMethod: (() async throws -> String)?
    public var getOAuthRefreshToken_MockValue: String?

    public func getOAuthRefreshToken() async throws -> String {
        getOAuthRefreshToken_Invocations.append(())

        if let error = getOAuthRefreshToken_MockError {
            throw error
        }

        if let mock = getOAuthRefreshToken_MockMethod {
            return try await mock()
        } else if let mock = getOAuthRefreshToken_MockValue {
            return mock
        } else {
            fatalError("no mock for `getOAuthRefreshToken`")
        }
    }

    // MARK: - createDpopToken

    public var createDpopTokenNonce_Invocations: [String] = []
    public var createDpopTokenNonce_MockError: Error?
    public var createDpopTokenNonce_MockMethod: ((String) async throws -> String)?
    public var createDpopTokenNonce_MockValue: String?

    public func createDpopToken(nonce: String) async throws -> String {
        createDpopTokenNonce_Invocations.append(nonce)

        if let error = createDpopTokenNonce_MockError {
            throw error
        }

        if let mock = createDpopTokenNonce_MockMethod {
            return try await mock(nonce)
        } else if let mock = createDpopTokenNonce_MockValue {
            return mock
        } else {
            fatalError("no mock for `createDpopTokenNonce`")
        }
    }

    // MARK: - getNewDpopChallengeRequest

    public var getNewDpopChallengeRequestAccessTokenNonce_Invocations: [(accessToken: String, nonce: String)] = []
    public var getNewDpopChallengeRequestAccessTokenNonce_MockError: Error?
    public var getNewDpopChallengeRequestAccessTokenNonce_MockMethod: ((String, String) async throws -> Data)?
    public var getNewDpopChallengeRequestAccessTokenNonce_MockValue: Data?

    public func getNewDpopChallengeRequest(accessToken: String, nonce: String) async throws -> Data {
        getNewDpopChallengeRequestAccessTokenNonce_Invocations.append((accessToken: accessToken, nonce: nonce))

        if let error = getNewDpopChallengeRequestAccessTokenNonce_MockError {
            throw error
        }

        if let mock = getNewDpopChallengeRequestAccessTokenNonce_MockMethod {
            return try await mock(accessToken, nonce)
        } else if let mock = getNewDpopChallengeRequestAccessTokenNonce_MockValue {
            return mock
        } else {
            fatalError("no mock for `getNewDpopChallengeRequestAccessTokenNonce`")
        }
    }

    // MARK: - getNewOidcChallengeRequest

    public var getNewOidcChallengeRequestIdTokenRefreshTokenNonce_Invocations: [(idToken: String, refreshToken: String, nonce: String)] = []
    public var getNewOidcChallengeRequestIdTokenRefreshTokenNonce_MockError: Error?
    public var getNewOidcChallengeRequestIdTokenRefreshTokenNonce_MockMethod: ((String, String, String) async throws -> Data)?
    public var getNewOidcChallengeRequestIdTokenRefreshTokenNonce_MockValue: Data?

    public func getNewOidcChallengeRequest(idToken: String, refreshToken: String, nonce: String) async throws -> Data {
        getNewOidcChallengeRequestIdTokenRefreshTokenNonce_Invocations.append((idToken: idToken, refreshToken: refreshToken, nonce: nonce))

        if let error = getNewOidcChallengeRequestIdTokenRefreshTokenNonce_MockError {
            throw error
        }

        if let mock = getNewOidcChallengeRequestIdTokenRefreshTokenNonce_MockMethod {
            return try await mock(idToken, refreshToken, nonce)
        } else if let mock = getNewOidcChallengeRequestIdTokenRefreshTokenNonce_MockValue {
            return mock
        } else {
            fatalError("no mock for `getNewOidcChallengeRequestIdTokenRefreshTokenNonce`")
        }
    }

    // MARK: - setDPoPChallengeResponse

    public var setDPoPChallengeResponseChallenge_Invocations: [Data] = []
    public var setDPoPChallengeResponseChallenge_MockError: Error?
    public var setDPoPChallengeResponseChallenge_MockMethod: ((Data) async throws -> Void)?

    public func setDPoPChallengeResponse(challenge: Data) async throws {
        setDPoPChallengeResponseChallenge_Invocations.append(challenge)

        if let error = setDPoPChallengeResponseChallenge_MockError {
            throw error
        }

        guard let mock = setDPoPChallengeResponseChallenge_MockMethod else {
            fatalError("no mock for `setDPoPChallengeResponseChallenge`")
        }

        try await mock(challenge)
    }

    // MARK: - setOIDCChallengeResponse

    public var setOIDCChallengeResponseChallenge_Invocations: [Data] = []
    public var setOIDCChallengeResponseChallenge_MockError: Error?
    public var setOIDCChallengeResponseChallenge_MockMethod: ((Data) async throws -> Void)?

    public func setOIDCChallengeResponse(challenge: Data) async throws {
        setOIDCChallengeResponseChallenge_Invocations.append(challenge)

        if let error = setOIDCChallengeResponseChallenge_MockError {
            throw error
        }

        guard let mock = setOIDCChallengeResponseChallenge_MockMethod else {
            fatalError("no mock for `setOIDCChallengeResponseChallenge`")
        }

        try await mock(challenge)
    }

    // MARK: - checkOrderRequest

    public var checkOrderRequestOrderUrlNonce_Invocations: [(orderUrl: String, nonce: String)] = []
    public var checkOrderRequestOrderUrlNonce_MockError: Error?
    public var checkOrderRequestOrderUrlNonce_MockMethod: ((String, String) async throws -> Data)?
    public var checkOrderRequestOrderUrlNonce_MockValue: Data?

    public func checkOrderRequest(orderUrl: String, nonce: String) async throws -> Data {
        checkOrderRequestOrderUrlNonce_Invocations.append((orderUrl: orderUrl, nonce: nonce))

        if let error = checkOrderRequestOrderUrlNonce_MockError {
            throw error
        }

        if let mock = checkOrderRequestOrderUrlNonce_MockMethod {
            return try await mock(orderUrl, nonce)
        } else if let mock = checkOrderRequestOrderUrlNonce_MockValue {
            return mock
        } else {
            fatalError("no mock for `checkOrderRequestOrderUrlNonce`")
        }
    }

    // MARK: - checkOrderResponse

    public var checkOrderResponseOrder_Invocations: [Data] = []
    public var checkOrderResponseOrder_MockError: Error?
    public var checkOrderResponseOrder_MockMethod: ((Data) async throws -> String)?
    public var checkOrderResponseOrder_MockValue: String?

    public func checkOrderResponse(order: Data) async throws -> String {
        checkOrderResponseOrder_Invocations.append(order)

        if let error = checkOrderResponseOrder_MockError {
            throw error
        }

        if let mock = checkOrderResponseOrder_MockMethod {
            return try await mock(order)
        } else if let mock = checkOrderResponseOrder_MockValue {
            return mock
        } else {
            fatalError("no mock for `checkOrderResponseOrder`")
        }
    }

    // MARK: - finalizeRequest

    public var finalizeRequestNonce_Invocations: [String] = []
    public var finalizeRequestNonce_MockError: Error?
    public var finalizeRequestNonce_MockMethod: ((String) async throws -> Data)?
    public var finalizeRequestNonce_MockValue: Data?

    public func finalizeRequest(nonce: String) async throws -> Data {
        finalizeRequestNonce_Invocations.append(nonce)

        if let error = finalizeRequestNonce_MockError {
            throw error
        }

        if let mock = finalizeRequestNonce_MockMethod {
            return try await mock(nonce)
        } else if let mock = finalizeRequestNonce_MockValue {
            return mock
        } else {
            fatalError("no mock for `finalizeRequestNonce`")
        }
    }

    // MARK: - finalizeResponse

    public var finalizeResponseFinalize_Invocations: [Data] = []
    public var finalizeResponseFinalize_MockError: Error?
    public var finalizeResponseFinalize_MockMethod: ((Data) async throws -> String)?
    public var finalizeResponseFinalize_MockValue: String?

    public func finalizeResponse(finalize: Data) async throws -> String {
        finalizeResponseFinalize_Invocations.append(finalize)

        if let error = finalizeResponseFinalize_MockError {
            throw error
        }

        if let mock = finalizeResponseFinalize_MockMethod {
            return try await mock(finalize)
        } else if let mock = finalizeResponseFinalize_MockValue {
            return mock
        } else {
            fatalError("no mock for `finalizeResponseFinalize`")
        }
    }

    // MARK: - certificateRequest

    public var certificateRequestNonce_Invocations: [String] = []
    public var certificateRequestNonce_MockError: Error?
    public var certificateRequestNonce_MockMethod: ((String) async throws -> Data)?
    public var certificateRequestNonce_MockValue: Data?

    public func certificateRequest(nonce: String) async throws -> Data {
        certificateRequestNonce_Invocations.append(nonce)

        if let error = certificateRequestNonce_MockError {
            throw error
        }

        if let mock = certificateRequestNonce_MockMethod {
            return try await mock(nonce)
        } else if let mock = certificateRequestNonce_MockValue {
            return mock
        } else {
            fatalError("no mock for `certificateRequestNonce`")
        }
    }

    // MARK: - createNewClient

    public var createNewClientCertificateChain_Invocations: [String] = []
    public var createNewClientCertificateChain_MockError: Error?
    public var createNewClientCertificateChain_MockMethod: ((String) async throws -> Void)?

    public func createNewClient(certificateChain: String) async throws {
        createNewClientCertificateChain_Invocations.append(certificateChain)

        if let error = createNewClientCertificateChain_MockError {
            throw error
        }

        guard let mock = createNewClientCertificateChain_MockMethod else {
            fatalError("no mock for `createNewClientCertificateChain`")
        }

        try await mock(certificateChain)
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

    var claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_Invocations: [(userID: UUID, domain: String?, ciphersuite: MLSCipherSuite, excludedSelfClientID: String?, context: NotificationContext)] = []
    var claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockError: Error?
    var claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockMethod: ((UUID, String?, MLSCipherSuite, String?, NotificationContext) async throws -> [KeyPackage])?
    var claimKeyPackagesUserIDDomainCiphersuiteExcludedSelfClientIDIn_MockValue: [KeyPackage]?

    func claimKeyPackages(userID: UUID, domain: String?, ciphersuite: MLSCipherSuite, excludedSelfClientID: String?, in context: NotificationContext) async throws -> [KeyPackage] {
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


    // MARK: - createGroup

    public var createGroupForParentGroupID_Invocations: [(groupID: MLSGroupID, parentGroupID: MLSGroupID?)] = []
    public var createGroupForParentGroupID_MockError: Error?
    public var createGroupForParentGroupID_MockMethod: ((MLSGroupID, MLSGroupID?) async throws -> MLSCipherSuite)?
    public var createGroupForParentGroupID_MockValue: MLSCipherSuite?

    public func createGroup(for groupID: MLSGroupID, parentGroupID: MLSGroupID?) async throws -> MLSCipherSuite {
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

    public var establishGroupForWith_Invocations: [(groupID: MLSGroupID, users: [MLSUser])] = []
    public var establishGroupForWith_MockError: Error?
    public var establishGroupForWith_MockMethod: ((MLSGroupID, [MLSUser]) async throws -> MLSCipherSuite)?
    public var establishGroupForWith_MockValue: MLSCipherSuite?

    public func establishGroup(for groupID: MLSGroupID, with users: [MLSUser]) async throws -> MLSCipherSuite {
        establishGroupForWith_Invocations.append((groupID: groupID, users: users))

        if let error = establishGroupForWith_MockError {
            throw error
        }

        if let mock = establishGroupForWith_MockMethod {
            return try await mock(groupID, users)
        } else if let mock = establishGroupForWith_MockValue {
            return mock
        } else {
            fatalError("no mock for `establishGroupForWith`")
        }
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

<<<<<<< HEAD
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
=======
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
>>>>>>> a43e45b27b (feat: Use proper MLS removal key with federated 1:1 conversations - WPB-10745 (#1868))
        }

        try await mock()
    }

    // MARK: - wipeGroup

<<<<<<< HEAD
    public var wipeGroup_Invocations: [MLSGroupID] = []
    public var wipeGroup_MockError: Error?
    public var wipeGroup_MockMethod: ((MLSGroupID) async throws -> Void)?

    public func wipeGroup(_ groupID: MLSGroupID) async throws {
        wipeGroup_Invocations.append(groupID)
=======
    public var createGroupForParentGroupID_Invocations: [(groupID: MLSGroupID, parentGroupID: MLSGroupID)] = []
    public var createGroupForParentGroupID_MockError: Error?
    public var createGroupForParentGroupID_MockMethod: ((MLSGroupID, MLSGroupID) async throws -> MLSCipherSuite)?
    public var createGroupForParentGroupID_MockValue: MLSCipherSuite?

    public func createGroup(for groupID: MLSGroupID, parentGroupID: MLSGroupID) async throws -> MLSCipherSuite {
        createGroupForParentGroupID_Invocations.append((groupID: groupID, parentGroupID: parentGroupID))
>>>>>>> a43e45b27b (feat: Use proper MLS removal key with federated 1:1 conversations - WPB-10745 (#1868))

        if let error = wipeGroup_MockError {
            throw error
        }

        guard let mock = wipeGroup_MockMethod else {
            fatalError("no mock for `wipeGroup`")
        }

        try await mock(groupID)
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

    // MARK: - commitPendingProposalsIfNeeded

    public var commitPendingProposalsIfNeeded_Invocations: [Void] = []
    public var commitPendingProposalsIfNeeded_MockMethod: (() -> Void)?

    public func commitPendingProposalsIfNeeded() {
        commitPendingProposalsIfNeeded_Invocations.append(())

        guard let mock = commitPendingProposalsIfNeeded_MockMethod else {
            fatalError("no mock for `commitPendingProposalsIfNeeded`")
        }

        mock()
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
