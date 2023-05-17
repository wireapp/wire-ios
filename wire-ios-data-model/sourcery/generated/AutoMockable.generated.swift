// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

import LocalAuthentication

@testable import WireDataModel





















public class MockCoreCryptoProtocol: CoreCryptoProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - `mlsInit`

    public var mlsInitClientIdCiphersuites_Invocations: [(`clientId`: ClientId, `ciphersuites`: [CiphersuiteName])] = []
    public var mlsInitClientIdCiphersuites_MockError: Error?
    public var mlsInitClientIdCiphersuites_MockMethod: ((ClientId, [CiphersuiteName]) throws -> Void)?

    public func `mlsInit`(`clientId`: ClientId, `ciphersuites`: [CiphersuiteName]) throws {
        mlsInitClientIdCiphersuites_Invocations.append((`clientId`: `clientId`, `ciphersuites`: `ciphersuites`))

        if let error = mlsInitClientIdCiphersuites_MockError {
            throw error
        }

        guard let mock = mlsInitClientIdCiphersuites_MockMethod else {
            fatalError("no mock for `mlsInitClientIdCiphersuites`")
        }

        try mock(`clientId`, `ciphersuites`)            
    }

    // MARK: - `mlsGenerateKeypairs`

    public var mlsGenerateKeypairsCiphersuites_Invocations: [[CiphersuiteName]] = []
    public var mlsGenerateKeypairsCiphersuites_MockError: Error?
    public var mlsGenerateKeypairsCiphersuites_MockMethod: (([CiphersuiteName]) throws -> [[UInt8]])?
    public var mlsGenerateKeypairsCiphersuites_MockValue: [[UInt8]]?

    public func `mlsGenerateKeypairs`(`ciphersuites`: [CiphersuiteName]) throws -> [[UInt8]] {
        mlsGenerateKeypairsCiphersuites_Invocations.append(`ciphersuites`)

        if let error = mlsGenerateKeypairsCiphersuites_MockError {
            throw error
        }

        if let mock = mlsGenerateKeypairsCiphersuites_MockMethod {
            return try mock(`ciphersuites`)
        } else if let mock = mlsGenerateKeypairsCiphersuites_MockValue {
            return mock
        } else {
            fatalError("no mock for `mlsGenerateKeypairsCiphersuites`")
        }
    }

    // MARK: - `mlsInitWithClientId`

    public var mlsInitWithClientIdClientIdSignaturePublicKeysCiphersuites_Invocations: [(`clientId`: ClientId, `signaturePublicKeys`: [[UInt8]], `ciphersuites`: [CiphersuiteName])] = []
    public var mlsInitWithClientIdClientIdSignaturePublicKeysCiphersuites_MockError: Error?
    public var mlsInitWithClientIdClientIdSignaturePublicKeysCiphersuites_MockMethod: ((ClientId, [[UInt8]], [CiphersuiteName]) throws -> Void)?

    public func `mlsInitWithClientId`(`clientId`: ClientId, `signaturePublicKeys`: [[UInt8]], `ciphersuites`: [CiphersuiteName]) throws {
        mlsInitWithClientIdClientIdSignaturePublicKeysCiphersuites_Invocations.append((`clientId`: `clientId`, `signaturePublicKeys`: `signaturePublicKeys`, `ciphersuites`: `ciphersuites`))

        if let error = mlsInitWithClientIdClientIdSignaturePublicKeysCiphersuites_MockError {
            throw error
        }

        guard let mock = mlsInitWithClientIdClientIdSignaturePublicKeysCiphersuites_MockMethod else {
            fatalError("no mock for `mlsInitWithClientIdClientIdSignaturePublicKeysCiphersuites`")
        }

        try mock(`clientId`, `signaturePublicKeys`, `ciphersuites`)            
    }

    // MARK: - `restoreFromDisk`

    public var restoreFromDisk_Invocations: [Void] = []
    public var restoreFromDisk_MockError: Error?
    public var restoreFromDisk_MockMethod: (() throws -> Void)?

    public func `restoreFromDisk`() throws {
        restoreFromDisk_Invocations.append(())

        if let error = restoreFromDisk_MockError {
            throw error
        }

        guard let mock = restoreFromDisk_MockMethod else {
            fatalError("no mock for `restoreFromDisk`")
        }

        try mock()            
    }

    // MARK: - `setCallbacks`

    public var setCallbacksCallbacks_Invocations: [CoreCryptoCallbacks] = []
    public var setCallbacksCallbacks_MockError: Error?
    public var setCallbacksCallbacks_MockMethod: ((CoreCryptoCallbacks) throws -> Void)?

    public func `setCallbacks`(`callbacks`: CoreCryptoCallbacks) throws {
        setCallbacksCallbacks_Invocations.append(`callbacks`)

        if let error = setCallbacksCallbacks_MockError {
            throw error
        }

        guard let mock = setCallbacksCallbacks_MockMethod else {
            fatalError("no mock for `setCallbacksCallbacks`")
        }

        try mock(`callbacks`)            
    }

    // MARK: - `clientPublicKey`

    public var clientPublicKeyCiphersuite_Invocations: [CiphersuiteName] = []
    public var clientPublicKeyCiphersuite_MockError: Error?
    public var clientPublicKeyCiphersuite_MockMethod: ((CiphersuiteName) throws -> [UInt8])?
    public var clientPublicKeyCiphersuite_MockValue: [UInt8]?

    public func `clientPublicKey`(`ciphersuite`: CiphersuiteName) throws -> [UInt8] {
        clientPublicKeyCiphersuite_Invocations.append(`ciphersuite`)

        if let error = clientPublicKeyCiphersuite_MockError {
            throw error
        }

        if let mock = clientPublicKeyCiphersuite_MockMethod {
            return try mock(`ciphersuite`)
        } else if let mock = clientPublicKeyCiphersuite_MockValue {
            return mock
        } else {
            fatalError("no mock for `clientPublicKeyCiphersuite`")
        }
    }

    // MARK: - `clientKeypackages`

    public var clientKeypackagesCiphersuiteAmountRequested_Invocations: [(`ciphersuite`: CiphersuiteName, `amountRequested`: UInt32)] = []
    public var clientKeypackagesCiphersuiteAmountRequested_MockError: Error?
    public var clientKeypackagesCiphersuiteAmountRequested_MockMethod: ((CiphersuiteName, UInt32) throws -> [[UInt8]])?
    public var clientKeypackagesCiphersuiteAmountRequested_MockValue: [[UInt8]]?

    public func `clientKeypackages`(`ciphersuite`: CiphersuiteName, `amountRequested`: UInt32) throws -> [[UInt8]] {
        clientKeypackagesCiphersuiteAmountRequested_Invocations.append((`ciphersuite`: `ciphersuite`, `amountRequested`: `amountRequested`))

        if let error = clientKeypackagesCiphersuiteAmountRequested_MockError {
            throw error
        }

        if let mock = clientKeypackagesCiphersuiteAmountRequested_MockMethod {
            return try mock(`ciphersuite`, `amountRequested`)
        } else if let mock = clientKeypackagesCiphersuiteAmountRequested_MockValue {
            return mock
        } else {
            fatalError("no mock for `clientKeypackagesCiphersuiteAmountRequested`")
        }
    }

    // MARK: - `clientValidKeypackagesCount`

    public var clientValidKeypackagesCountCiphersuite_Invocations: [CiphersuiteName] = []
    public var clientValidKeypackagesCountCiphersuite_MockError: Error?
    public var clientValidKeypackagesCountCiphersuite_MockMethod: ((CiphersuiteName) throws -> UInt64)?
    public var clientValidKeypackagesCountCiphersuite_MockValue: UInt64?

    public func `clientValidKeypackagesCount`(`ciphersuite`: CiphersuiteName) throws -> UInt64 {
        clientValidKeypackagesCountCiphersuite_Invocations.append(`ciphersuite`)

        if let error = clientValidKeypackagesCountCiphersuite_MockError {
            throw error
        }

        if let mock = clientValidKeypackagesCountCiphersuite_MockMethod {
            return try mock(`ciphersuite`)
        } else if let mock = clientValidKeypackagesCountCiphersuite_MockValue {
            return mock
        } else {
            fatalError("no mock for `clientValidKeypackagesCountCiphersuite`")
        }
    }

    // MARK: - `createConversation`

    public var createConversationConversationIdConfig_Invocations: [(`conversationId`: ConversationId, `config`: ConversationConfiguration)] = []
    public var createConversationConversationIdConfig_MockError: Error?
    public var createConversationConversationIdConfig_MockMethod: ((ConversationId, ConversationConfiguration) throws -> Void)?

    public func `createConversation`(`conversationId`: ConversationId, `config`: ConversationConfiguration) throws {
        createConversationConversationIdConfig_Invocations.append((`conversationId`: `conversationId`, `config`: `config`))

        if let error = createConversationConversationIdConfig_MockError {
            throw error
        }

        guard let mock = createConversationConversationIdConfig_MockMethod else {
            fatalError("no mock for `createConversationConversationIdConfig`")
        }

        try mock(`conversationId`, `config`)            
    }

    // MARK: - `conversationEpoch`

    public var conversationEpochConversationId_Invocations: [ConversationId] = []
    public var conversationEpochConversationId_MockError: Error?
    public var conversationEpochConversationId_MockMethod: ((ConversationId) throws -> UInt64)?
    public var conversationEpochConversationId_MockValue: UInt64?

    public func `conversationEpoch`(`conversationId`: ConversationId) throws -> UInt64 {
        conversationEpochConversationId_Invocations.append(`conversationId`)

        if let error = conversationEpochConversationId_MockError {
            throw error
        }

        if let mock = conversationEpochConversationId_MockMethod {
            return try mock(`conversationId`)
        } else if let mock = conversationEpochConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationEpochConversationId`")
        }
    }

    // MARK: - `conversationExists`

    public var conversationExistsConversationId_Invocations: [ConversationId] = []
    public var conversationExistsConversationId_MockMethod: ((ConversationId) -> Bool)?
    public var conversationExistsConversationId_MockValue: Bool?

    public func `conversationExists`(`conversationId`: ConversationId) -> Bool {
        conversationExistsConversationId_Invocations.append(`conversationId`)

        if let mock = conversationExistsConversationId_MockMethod {
            return mock(`conversationId`)
        } else if let mock = conversationExistsConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationExistsConversationId`")
        }
    }

    // MARK: - `processWelcomeMessage`

    public var processWelcomeMessageWelcomeMessageCustomConfiguration_Invocations: [(`welcomeMessage`: [UInt8], `customConfiguration`: CustomConfiguration)] = []
    public var processWelcomeMessageWelcomeMessageCustomConfiguration_MockError: Error?
    public var processWelcomeMessageWelcomeMessageCustomConfiguration_MockMethod: (([UInt8], CustomConfiguration) throws -> ConversationId)?
    public var processWelcomeMessageWelcomeMessageCustomConfiguration_MockValue: ConversationId?

    public func `processWelcomeMessage`(`welcomeMessage`: [UInt8], `customConfiguration`: CustomConfiguration) throws -> ConversationId {
        processWelcomeMessageWelcomeMessageCustomConfiguration_Invocations.append((`welcomeMessage`: `welcomeMessage`, `customConfiguration`: `customConfiguration`))

        if let error = processWelcomeMessageWelcomeMessageCustomConfiguration_MockError {
            throw error
        }

        if let mock = processWelcomeMessageWelcomeMessageCustomConfiguration_MockMethod {
            return try mock(`welcomeMessage`, `customConfiguration`)
        } else if let mock = processWelcomeMessageWelcomeMessageCustomConfiguration_MockValue {
            return mock
        } else {
            fatalError("no mock for `processWelcomeMessageWelcomeMessageCustomConfiguration`")
        }
    }

    // MARK: - `addClientsToConversation`

    public var addClientsToConversationConversationIdClients_Invocations: [(`conversationId`: ConversationId, `clients`: [Invitee])] = []
    public var addClientsToConversationConversationIdClients_MockError: Error?
    public var addClientsToConversationConversationIdClients_MockMethod: ((ConversationId, [Invitee]) throws -> MemberAddedMessages)?
    public var addClientsToConversationConversationIdClients_MockValue: MemberAddedMessages?

    public func `addClientsToConversation`(`conversationId`: ConversationId, `clients`: [Invitee]) throws -> MemberAddedMessages {
        addClientsToConversationConversationIdClients_Invocations.append((`conversationId`: `conversationId`, `clients`: `clients`))

        if let error = addClientsToConversationConversationIdClients_MockError {
            throw error
        }

        if let mock = addClientsToConversationConversationIdClients_MockMethod {
            return try mock(`conversationId`, `clients`)
        } else if let mock = addClientsToConversationConversationIdClients_MockValue {
            return mock
        } else {
            fatalError("no mock for `addClientsToConversationConversationIdClients`")
        }
    }

    // MARK: - `removeClientsFromConversation`

    public var removeClientsFromConversationConversationIdClients_Invocations: [(`conversationId`: ConversationId, `clients`: [ClientId])] = []
    public var removeClientsFromConversationConversationIdClients_MockError: Error?
    public var removeClientsFromConversationConversationIdClients_MockMethod: ((ConversationId, [ClientId]) throws -> CommitBundle)?
    public var removeClientsFromConversationConversationIdClients_MockValue: CommitBundle?

    public func `removeClientsFromConversation`(`conversationId`: ConversationId, `clients`: [ClientId]) throws -> CommitBundle {
        removeClientsFromConversationConversationIdClients_Invocations.append((`conversationId`: `conversationId`, `clients`: `clients`))

        if let error = removeClientsFromConversationConversationIdClients_MockError {
            throw error
        }

        if let mock = removeClientsFromConversationConversationIdClients_MockMethod {
            return try mock(`conversationId`, `clients`)
        } else if let mock = removeClientsFromConversationConversationIdClients_MockValue {
            return mock
        } else {
            fatalError("no mock for `removeClientsFromConversationConversationIdClients`")
        }
    }

    // MARK: - `markConversationAsChildOf`

    public var markConversationAsChildOfChildIdParentId_Invocations: [(`childId`: ConversationId, `parentId`: ConversationId)] = []
    public var markConversationAsChildOfChildIdParentId_MockError: Error?
    public var markConversationAsChildOfChildIdParentId_MockMethod: ((ConversationId, ConversationId) throws -> Void)?

    public func `markConversationAsChildOf`(`childId`: ConversationId, `parentId`: ConversationId) throws {
        markConversationAsChildOfChildIdParentId_Invocations.append((`childId`: `childId`, `parentId`: `parentId`))

        if let error = markConversationAsChildOfChildIdParentId_MockError {
            throw error
        }

        guard let mock = markConversationAsChildOfChildIdParentId_MockMethod else {
            fatalError("no mock for `markConversationAsChildOfChildIdParentId`")
        }

        try mock(`childId`, `parentId`)            
    }

    // MARK: - `updateKeyingMaterial`

    public var updateKeyingMaterialConversationId_Invocations: [ConversationId] = []
    public var updateKeyingMaterialConversationId_MockError: Error?
    public var updateKeyingMaterialConversationId_MockMethod: ((ConversationId) throws -> CommitBundle)?
    public var updateKeyingMaterialConversationId_MockValue: CommitBundle?

    public func `updateKeyingMaterial`(`conversationId`: ConversationId) throws -> CommitBundle {
        updateKeyingMaterialConversationId_Invocations.append(`conversationId`)

        if let error = updateKeyingMaterialConversationId_MockError {
            throw error
        }

        if let mock = updateKeyingMaterialConversationId_MockMethod {
            return try mock(`conversationId`)
        } else if let mock = updateKeyingMaterialConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `updateKeyingMaterialConversationId`")
        }
    }

    // MARK: - `commitPendingProposals`

    public var commitPendingProposalsConversationId_Invocations: [ConversationId] = []
    public var commitPendingProposalsConversationId_MockError: Error?
    public var commitPendingProposalsConversationId_MockMethod: ((ConversationId) throws -> CommitBundle?)?
    public var commitPendingProposalsConversationId_MockValue: CommitBundle??

    public func `commitPendingProposals`(`conversationId`: ConversationId) throws -> CommitBundle? {
        commitPendingProposalsConversationId_Invocations.append(`conversationId`)

        if let error = commitPendingProposalsConversationId_MockError {
            throw error
        }

        if let mock = commitPendingProposalsConversationId_MockMethod {
            return try mock(`conversationId`)
        } else if let mock = commitPendingProposalsConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `commitPendingProposalsConversationId`")
        }
    }

    // MARK: - `wipeConversation`

    public var wipeConversationConversationId_Invocations: [ConversationId] = []
    public var wipeConversationConversationId_MockError: Error?
    public var wipeConversationConversationId_MockMethod: ((ConversationId) throws -> Void)?

    public func `wipeConversation`(`conversationId`: ConversationId) throws {
        wipeConversationConversationId_Invocations.append(`conversationId`)

        if let error = wipeConversationConversationId_MockError {
            throw error
        }

        guard let mock = wipeConversationConversationId_MockMethod else {
            fatalError("no mock for `wipeConversationConversationId`")
        }

        try mock(`conversationId`)            
    }

    // MARK: - `decryptMessage`

    public var decryptMessageConversationIdPayload_Invocations: [(`conversationId`: ConversationId, `payload`: [UInt8])] = []
    public var decryptMessageConversationIdPayload_MockError: Error?
    public var decryptMessageConversationIdPayload_MockMethod: ((ConversationId, [UInt8]) throws -> DecryptedMessage)?
    public var decryptMessageConversationIdPayload_MockValue: DecryptedMessage?

    public func `decryptMessage`(`conversationId`: ConversationId, `payload`: [UInt8]) throws -> DecryptedMessage {
        decryptMessageConversationIdPayload_Invocations.append((`conversationId`: `conversationId`, `payload`: `payload`))

        if let error = decryptMessageConversationIdPayload_MockError {
            throw error
        }

        if let mock = decryptMessageConversationIdPayload_MockMethod {
            return try mock(`conversationId`, `payload`)
        } else if let mock = decryptMessageConversationIdPayload_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptMessageConversationIdPayload`")
        }
    }

    // MARK: - `encryptMessage`

    public var encryptMessageConversationIdMessage_Invocations: [(`conversationId`: ConversationId, `message`: [UInt8])] = []
    public var encryptMessageConversationIdMessage_MockError: Error?
    public var encryptMessageConversationIdMessage_MockMethod: ((ConversationId, [UInt8]) throws -> [UInt8])?
    public var encryptMessageConversationIdMessage_MockValue: [UInt8]?

    public func `encryptMessage`(`conversationId`: ConversationId, `message`: [UInt8]) throws -> [UInt8] {
        encryptMessageConversationIdMessage_Invocations.append((`conversationId`: `conversationId`, `message`: `message`))

        if let error = encryptMessageConversationIdMessage_MockError {
            throw error
        }

        if let mock = encryptMessageConversationIdMessage_MockMethod {
            return try mock(`conversationId`, `message`)
        } else if let mock = encryptMessageConversationIdMessage_MockValue {
            return mock
        } else {
            fatalError("no mock for `encryptMessageConversationIdMessage`")
        }
    }

    // MARK: - `newAddProposal`

    public var newAddProposalConversationIdKeyPackage_Invocations: [(`conversationId`: ConversationId, `keyPackage`: [UInt8])] = []
    public var newAddProposalConversationIdKeyPackage_MockError: Error?
    public var newAddProposalConversationIdKeyPackage_MockMethod: ((ConversationId, [UInt8]) throws -> ProposalBundle)?
    public var newAddProposalConversationIdKeyPackage_MockValue: ProposalBundle?

    public func `newAddProposal`(`conversationId`: ConversationId, `keyPackage`: [UInt8]) throws -> ProposalBundle {
        newAddProposalConversationIdKeyPackage_Invocations.append((`conversationId`: `conversationId`, `keyPackage`: `keyPackage`))

        if let error = newAddProposalConversationIdKeyPackage_MockError {
            throw error
        }

        if let mock = newAddProposalConversationIdKeyPackage_MockMethod {
            return try mock(`conversationId`, `keyPackage`)
        } else if let mock = newAddProposalConversationIdKeyPackage_MockValue {
            return mock
        } else {
            fatalError("no mock for `newAddProposalConversationIdKeyPackage`")
        }
    }

    // MARK: - `newUpdateProposal`

    public var newUpdateProposalConversationId_Invocations: [ConversationId] = []
    public var newUpdateProposalConversationId_MockError: Error?
    public var newUpdateProposalConversationId_MockMethod: ((ConversationId) throws -> ProposalBundle)?
    public var newUpdateProposalConversationId_MockValue: ProposalBundle?

    public func `newUpdateProposal`(`conversationId`: ConversationId) throws -> ProposalBundle {
        newUpdateProposalConversationId_Invocations.append(`conversationId`)

        if let error = newUpdateProposalConversationId_MockError {
            throw error
        }

        if let mock = newUpdateProposalConversationId_MockMethod {
            return try mock(`conversationId`)
        } else if let mock = newUpdateProposalConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `newUpdateProposalConversationId`")
        }
    }

    // MARK: - `newRemoveProposal`

    public var newRemoveProposalConversationIdClientId_Invocations: [(`conversationId`: ConversationId, `clientId`: ClientId)] = []
    public var newRemoveProposalConversationIdClientId_MockError: Error?
    public var newRemoveProposalConversationIdClientId_MockMethod: ((ConversationId, ClientId) throws -> ProposalBundle)?
    public var newRemoveProposalConversationIdClientId_MockValue: ProposalBundle?

    public func `newRemoveProposal`(`conversationId`: ConversationId, `clientId`: ClientId) throws -> ProposalBundle {
        newRemoveProposalConversationIdClientId_Invocations.append((`conversationId`: `conversationId`, `clientId`: `clientId`))

        if let error = newRemoveProposalConversationIdClientId_MockError {
            throw error
        }

        if let mock = newRemoveProposalConversationIdClientId_MockMethod {
            return try mock(`conversationId`, `clientId`)
        } else if let mock = newRemoveProposalConversationIdClientId_MockValue {
            return mock
        } else {
            fatalError("no mock for `newRemoveProposalConversationIdClientId`")
        }
    }

    // MARK: - `newExternalAddProposal`

    public var newExternalAddProposalConversationIdEpochCiphersuiteCredentialType_Invocations: [(`conversationId`: ConversationId, `epoch`: UInt64, `ciphersuite`: CiphersuiteName, `credentialType`: MlsCredentialType)] = []
    public var newExternalAddProposalConversationIdEpochCiphersuiteCredentialType_MockError: Error?
    public var newExternalAddProposalConversationIdEpochCiphersuiteCredentialType_MockMethod: ((ConversationId, UInt64, CiphersuiteName, MlsCredentialType) throws -> [UInt8])?
    public var newExternalAddProposalConversationIdEpochCiphersuiteCredentialType_MockValue: [UInt8]?

    public func `newExternalAddProposal`(`conversationId`: ConversationId, `epoch`: UInt64, `ciphersuite`: CiphersuiteName, `credentialType`: MlsCredentialType) throws -> [UInt8] {
        newExternalAddProposalConversationIdEpochCiphersuiteCredentialType_Invocations.append((`conversationId`: `conversationId`, `epoch`: `epoch`, `ciphersuite`: `ciphersuite`, `credentialType`: `credentialType`))

        if let error = newExternalAddProposalConversationIdEpochCiphersuiteCredentialType_MockError {
            throw error
        }

        if let mock = newExternalAddProposalConversationIdEpochCiphersuiteCredentialType_MockMethod {
            return try mock(`conversationId`, `epoch`, `ciphersuite`, `credentialType`)
        } else if let mock = newExternalAddProposalConversationIdEpochCiphersuiteCredentialType_MockValue {
            return mock
        } else {
            fatalError("no mock for `newExternalAddProposalConversationIdEpochCiphersuiteCredentialType`")
        }
    }

    // MARK: - `newExternalRemoveProposal`

    public var newExternalRemoveProposalConversationIdEpochKeyPackageRef_Invocations: [(`conversationId`: ConversationId, `epoch`: UInt64, `keyPackageRef`: [UInt8])] = []
    public var newExternalRemoveProposalConversationIdEpochKeyPackageRef_MockError: Error?
    public var newExternalRemoveProposalConversationIdEpochKeyPackageRef_MockMethod: ((ConversationId, UInt64, [UInt8]) throws -> [UInt8])?
    public var newExternalRemoveProposalConversationIdEpochKeyPackageRef_MockValue: [UInt8]?

    public func `newExternalRemoveProposal`(`conversationId`: ConversationId, `epoch`: UInt64, `keyPackageRef`: [UInt8]) throws -> [UInt8] {
        newExternalRemoveProposalConversationIdEpochKeyPackageRef_Invocations.append((`conversationId`: `conversationId`, `epoch`: `epoch`, `keyPackageRef`: `keyPackageRef`))

        if let error = newExternalRemoveProposalConversationIdEpochKeyPackageRef_MockError {
            throw error
        }

        if let mock = newExternalRemoveProposalConversationIdEpochKeyPackageRef_MockMethod {
            return try mock(`conversationId`, `epoch`, `keyPackageRef`)
        } else if let mock = newExternalRemoveProposalConversationIdEpochKeyPackageRef_MockValue {
            return mock
        } else {
            fatalError("no mock for `newExternalRemoveProposalConversationIdEpochKeyPackageRef`")
        }
    }

    // MARK: - `joinByExternalCommit`

    public var joinByExternalCommitPublicGroupStateCustomConfigurationCredentialType_Invocations: [(`publicGroupState`: [UInt8], `customConfiguration`: CustomConfiguration, `credentialType`: MlsCredentialType)] = []
    public var joinByExternalCommitPublicGroupStateCustomConfigurationCredentialType_MockError: Error?
    public var joinByExternalCommitPublicGroupStateCustomConfigurationCredentialType_MockMethod: (([UInt8], CustomConfiguration, MlsCredentialType) throws -> ConversationInitBundle)?
    public var joinByExternalCommitPublicGroupStateCustomConfigurationCredentialType_MockValue: ConversationInitBundle?

    public func `joinByExternalCommit`(`publicGroupState`: [UInt8], `customConfiguration`: CustomConfiguration, `credentialType`: MlsCredentialType) throws -> ConversationInitBundle {
        joinByExternalCommitPublicGroupStateCustomConfigurationCredentialType_Invocations.append((`publicGroupState`: `publicGroupState`, `customConfiguration`: `customConfiguration`, `credentialType`: `credentialType`))

        if let error = joinByExternalCommitPublicGroupStateCustomConfigurationCredentialType_MockError {
            throw error
        }

        if let mock = joinByExternalCommitPublicGroupStateCustomConfigurationCredentialType_MockMethod {
            return try mock(`publicGroupState`, `customConfiguration`, `credentialType`)
        } else if let mock = joinByExternalCommitPublicGroupStateCustomConfigurationCredentialType_MockValue {
            return mock
        } else {
            fatalError("no mock for `joinByExternalCommitPublicGroupStateCustomConfigurationCredentialType`")
        }
    }

    // MARK: - `mergePendingGroupFromExternalCommit`

    public var mergePendingGroupFromExternalCommitConversationId_Invocations: [ConversationId] = []
    public var mergePendingGroupFromExternalCommitConversationId_MockError: Error?
    public var mergePendingGroupFromExternalCommitConversationId_MockMethod: ((ConversationId) throws -> Void)?

    public func `mergePendingGroupFromExternalCommit`(`conversationId`: ConversationId) throws {
        mergePendingGroupFromExternalCommitConversationId_Invocations.append(`conversationId`)

        if let error = mergePendingGroupFromExternalCommitConversationId_MockError {
            throw error
        }

        guard let mock = mergePendingGroupFromExternalCommitConversationId_MockMethod else {
            fatalError("no mock for `mergePendingGroupFromExternalCommitConversationId`")
        }

        try mock(`conversationId`)            
    }

    // MARK: - `clearPendingGroupFromExternalCommit`

    public var clearPendingGroupFromExternalCommitConversationId_Invocations: [ConversationId] = []
    public var clearPendingGroupFromExternalCommitConversationId_MockError: Error?
    public var clearPendingGroupFromExternalCommitConversationId_MockMethod: ((ConversationId) throws -> Void)?

    public func `clearPendingGroupFromExternalCommit`(`conversationId`: ConversationId) throws {
        clearPendingGroupFromExternalCommitConversationId_Invocations.append(`conversationId`)

        if let error = clearPendingGroupFromExternalCommitConversationId_MockError {
            throw error
        }

        guard let mock = clearPendingGroupFromExternalCommitConversationId_MockMethod else {
            fatalError("no mock for `clearPendingGroupFromExternalCommitConversationId`")
        }

        try mock(`conversationId`)            
    }

    // MARK: - `exportGroupState`

    public var exportGroupStateConversationId_Invocations: [ConversationId] = []
    public var exportGroupStateConversationId_MockError: Error?
    public var exportGroupStateConversationId_MockMethod: ((ConversationId) throws -> [UInt8])?
    public var exportGroupStateConversationId_MockValue: [UInt8]?

    public func `exportGroupState`(`conversationId`: ConversationId) throws -> [UInt8] {
        exportGroupStateConversationId_Invocations.append(`conversationId`)

        if let error = exportGroupStateConversationId_MockError {
            throw error
        }

        if let mock = exportGroupStateConversationId_MockMethod {
            return try mock(`conversationId`)
        } else if let mock = exportGroupStateConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `exportGroupStateConversationId`")
        }
    }

    // MARK: - `exportSecretKey`

    public var exportSecretKeyConversationIdKeyLength_Invocations: [(`conversationId`: ConversationId, `keyLength`: UInt32)] = []
    public var exportSecretKeyConversationIdKeyLength_MockError: Error?
    public var exportSecretKeyConversationIdKeyLength_MockMethod: ((ConversationId, UInt32) throws -> [UInt8])?
    public var exportSecretKeyConversationIdKeyLength_MockValue: [UInt8]?

    public func `exportSecretKey`(`conversationId`: ConversationId, `keyLength`: UInt32) throws -> [UInt8] {
        exportSecretKeyConversationIdKeyLength_Invocations.append((`conversationId`: `conversationId`, `keyLength`: `keyLength`))

        if let error = exportSecretKeyConversationIdKeyLength_MockError {
            throw error
        }

        if let mock = exportSecretKeyConversationIdKeyLength_MockMethod {
            return try mock(`conversationId`, `keyLength`)
        } else if let mock = exportSecretKeyConversationIdKeyLength_MockValue {
            return mock
        } else {
            fatalError("no mock for `exportSecretKeyConversationIdKeyLength`")
        }
    }

    // MARK: - `getClientIds`

    public var getClientIdsConversationId_Invocations: [ConversationId] = []
    public var getClientIdsConversationId_MockError: Error?
    public var getClientIdsConversationId_MockMethod: ((ConversationId) throws -> [ClientId])?
    public var getClientIdsConversationId_MockValue: [ClientId]?

    public func `getClientIds`(`conversationId`: ConversationId) throws -> [ClientId] {
        getClientIdsConversationId_Invocations.append(`conversationId`)

        if let error = getClientIdsConversationId_MockError {
            throw error
        }

        if let mock = getClientIdsConversationId_MockMethod {
            return try mock(`conversationId`)
        } else if let mock = getClientIdsConversationId_MockValue {
            return mock
        } else {
            fatalError("no mock for `getClientIdsConversationId`")
        }
    }

    // MARK: - `randomBytes`

    public var randomBytesLength_Invocations: [UInt32] = []
    public var randomBytesLength_MockError: Error?
    public var randomBytesLength_MockMethod: ((UInt32) throws -> [UInt8])?
    public var randomBytesLength_MockValue: [UInt8]?

    public func `randomBytes`(`length`: UInt32) throws -> [UInt8] {
        randomBytesLength_Invocations.append(`length`)

        if let error = randomBytesLength_MockError {
            throw error
        }

        if let mock = randomBytesLength_MockMethod {
            return try mock(`length`)
        } else if let mock = randomBytesLength_MockValue {
            return mock
        } else {
            fatalError("no mock for `randomBytesLength`")
        }
    }

    // MARK: - `reseedRng`

    public var reseedRngSeed_Invocations: [[UInt8]] = []
    public var reseedRngSeed_MockError: Error?
    public var reseedRngSeed_MockMethod: (([UInt8]) throws -> Void)?

    public func `reseedRng`(`seed`: [UInt8]) throws {
        reseedRngSeed_Invocations.append(`seed`)

        if let error = reseedRngSeed_MockError {
            throw error
        }

        guard let mock = reseedRngSeed_MockMethod else {
            fatalError("no mock for `reseedRngSeed`")
        }

        try mock(`seed`)            
    }

    // MARK: - `commitAccepted`

    public var commitAcceptedConversationId_Invocations: [ConversationId] = []
    public var commitAcceptedConversationId_MockError: Error?
    public var commitAcceptedConversationId_MockMethod: ((ConversationId) throws -> Void)?

    public func `commitAccepted`(`conversationId`: ConversationId) throws {
        commitAcceptedConversationId_Invocations.append(`conversationId`)

        if let error = commitAcceptedConversationId_MockError {
            throw error
        }

        guard let mock = commitAcceptedConversationId_MockMethod else {
            fatalError("no mock for `commitAcceptedConversationId`")
        }

        try mock(`conversationId`)            
    }

    // MARK: - `clearPendingProposal`

    public var clearPendingProposalConversationIdProposalRef_Invocations: [(`conversationId`: ConversationId, `proposalRef`: [UInt8])] = []
    public var clearPendingProposalConversationIdProposalRef_MockError: Error?
    public var clearPendingProposalConversationIdProposalRef_MockMethod: ((ConversationId, [UInt8]) throws -> Void)?

    public func `clearPendingProposal`(`conversationId`: ConversationId, `proposalRef`: [UInt8]) throws {
        clearPendingProposalConversationIdProposalRef_Invocations.append((`conversationId`: `conversationId`, `proposalRef`: `proposalRef`))

        if let error = clearPendingProposalConversationIdProposalRef_MockError {
            throw error
        }

        guard let mock = clearPendingProposalConversationIdProposalRef_MockMethod else {
            fatalError("no mock for `clearPendingProposalConversationIdProposalRef`")
        }

        try mock(`conversationId`, `proposalRef`)            
    }

    // MARK: - `clearPendingCommit`

    public var clearPendingCommitConversationId_Invocations: [ConversationId] = []
    public var clearPendingCommitConversationId_MockError: Error?
    public var clearPendingCommitConversationId_MockMethod: ((ConversationId) throws -> Void)?

    public func `clearPendingCommit`(`conversationId`: ConversationId) throws {
        clearPendingCommitConversationId_Invocations.append(`conversationId`)

        if let error = clearPendingCommitConversationId_MockError {
            throw error
        }

        guard let mock = clearPendingCommitConversationId_MockMethod else {
            fatalError("no mock for `clearPendingCommitConversationId`")
        }

        try mock(`conversationId`)            
    }

    // MARK: - `proteusInit`

    public var proteusInit_Invocations: [Void] = []
    public var proteusInit_MockError: Error?
    public var proteusInit_MockMethod: (() throws -> Void)?

    public func `proteusInit`() throws {
        proteusInit_Invocations.append(())

        if let error = proteusInit_MockError {
            throw error
        }

        guard let mock = proteusInit_MockMethod else {
            fatalError("no mock for `proteusInit`")
        }

        try mock()            
    }

    // MARK: - `proteusSessionFromPrekey`

    public var proteusSessionFromPrekeySessionIdPrekey_Invocations: [(`sessionId`: String, `prekey`: [UInt8])] = []
    public var proteusSessionFromPrekeySessionIdPrekey_MockError: Error?
    public var proteusSessionFromPrekeySessionIdPrekey_MockMethod: ((String, [UInt8]) throws -> Void)?

    public func `proteusSessionFromPrekey`(`sessionId`: String, `prekey`: [UInt8]) throws {
        proteusSessionFromPrekeySessionIdPrekey_Invocations.append((`sessionId`: `sessionId`, `prekey`: `prekey`))

        if let error = proteusSessionFromPrekeySessionIdPrekey_MockError {
            throw error
        }

        guard let mock = proteusSessionFromPrekeySessionIdPrekey_MockMethod else {
            fatalError("no mock for `proteusSessionFromPrekeySessionIdPrekey`")
        }

        try mock(`sessionId`, `prekey`)            
    }

    // MARK: - `proteusSessionFromMessage`

    public var proteusSessionFromMessageSessionIdEnvelope_Invocations: [(`sessionId`: String, `envelope`: [UInt8])] = []
    public var proteusSessionFromMessageSessionIdEnvelope_MockError: Error?
    public var proteusSessionFromMessageSessionIdEnvelope_MockMethod: ((String, [UInt8]) throws -> [UInt8])?
    public var proteusSessionFromMessageSessionIdEnvelope_MockValue: [UInt8]?

    public func `proteusSessionFromMessage`(`sessionId`: String, `envelope`: [UInt8]) throws -> [UInt8] {
        proteusSessionFromMessageSessionIdEnvelope_Invocations.append((`sessionId`: `sessionId`, `envelope`: `envelope`))

        if let error = proteusSessionFromMessageSessionIdEnvelope_MockError {
            throw error
        }

        if let mock = proteusSessionFromMessageSessionIdEnvelope_MockMethod {
            return try mock(`sessionId`, `envelope`)
        } else if let mock = proteusSessionFromMessageSessionIdEnvelope_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusSessionFromMessageSessionIdEnvelope`")
        }
    }

    // MARK: - `proteusSessionSave`

    public var proteusSessionSaveSessionId_Invocations: [String] = []
    public var proteusSessionSaveSessionId_MockError: Error?
    public var proteusSessionSaveSessionId_MockMethod: ((String) throws -> Void)?

    public func `proteusSessionSave`(`sessionId`: String) throws {
        proteusSessionSaveSessionId_Invocations.append(`sessionId`)

        if let error = proteusSessionSaveSessionId_MockError {
            throw error
        }

        guard let mock = proteusSessionSaveSessionId_MockMethod else {
            fatalError("no mock for `proteusSessionSaveSessionId`")
        }

        try mock(`sessionId`)            
    }

    // MARK: - `proteusSessionDelete`

    public var proteusSessionDeleteSessionId_Invocations: [String] = []
    public var proteusSessionDeleteSessionId_MockError: Error?
    public var proteusSessionDeleteSessionId_MockMethod: ((String) throws -> Void)?

    public func `proteusSessionDelete`(`sessionId`: String) throws {
        proteusSessionDeleteSessionId_Invocations.append(`sessionId`)

        if let error = proteusSessionDeleteSessionId_MockError {
            throw error
        }

        guard let mock = proteusSessionDeleteSessionId_MockMethod else {
            fatalError("no mock for `proteusSessionDeleteSessionId`")
        }

        try mock(`sessionId`)            
    }

    // MARK: - `proteusSessionExists`

    public var proteusSessionExistsSessionId_Invocations: [String] = []
    public var proteusSessionExistsSessionId_MockError: Error?
    public var proteusSessionExistsSessionId_MockMethod: ((String) throws -> Bool)?
    public var proteusSessionExistsSessionId_MockValue: Bool?

    public func `proteusSessionExists`(`sessionId`: String) throws -> Bool {
        proteusSessionExistsSessionId_Invocations.append(`sessionId`)

        if let error = proteusSessionExistsSessionId_MockError {
            throw error
        }

        if let mock = proteusSessionExistsSessionId_MockMethod {
            return try mock(`sessionId`)
        } else if let mock = proteusSessionExistsSessionId_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusSessionExistsSessionId`")
        }
    }

    // MARK: - `proteusDecrypt`

    public var proteusDecryptSessionIdCiphertext_Invocations: [(`sessionId`: String, `ciphertext`: [UInt8])] = []
    public var proteusDecryptSessionIdCiphertext_MockError: Error?
    public var proteusDecryptSessionIdCiphertext_MockMethod: ((String, [UInt8]) throws -> [UInt8])?
    public var proteusDecryptSessionIdCiphertext_MockValue: [UInt8]?

    public func `proteusDecrypt`(`sessionId`: String, `ciphertext`: [UInt8]) throws -> [UInt8] {
        proteusDecryptSessionIdCiphertext_Invocations.append((`sessionId`: `sessionId`, `ciphertext`: `ciphertext`))

        if let error = proteusDecryptSessionIdCiphertext_MockError {
            throw error
        }

        if let mock = proteusDecryptSessionIdCiphertext_MockMethod {
            return try mock(`sessionId`, `ciphertext`)
        } else if let mock = proteusDecryptSessionIdCiphertext_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusDecryptSessionIdCiphertext`")
        }
    }

    // MARK: - `proteusEncrypt`

    public var proteusEncryptSessionIdPlaintext_Invocations: [(`sessionId`: String, `plaintext`: [UInt8])] = []
    public var proteusEncryptSessionIdPlaintext_MockError: Error?
    public var proteusEncryptSessionIdPlaintext_MockMethod: ((String, [UInt8]) throws -> [UInt8])?
    public var proteusEncryptSessionIdPlaintext_MockValue: [UInt8]?

    public func `proteusEncrypt`(`sessionId`: String, `plaintext`: [UInt8]) throws -> [UInt8] {
        proteusEncryptSessionIdPlaintext_Invocations.append((`sessionId`: `sessionId`, `plaintext`: `plaintext`))

        if let error = proteusEncryptSessionIdPlaintext_MockError {
            throw error
        }

        if let mock = proteusEncryptSessionIdPlaintext_MockMethod {
            return try mock(`sessionId`, `plaintext`)
        } else if let mock = proteusEncryptSessionIdPlaintext_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusEncryptSessionIdPlaintext`")
        }
    }

    // MARK: - `proteusEncryptBatched`

    public var proteusEncryptBatchedSessionIdPlaintext_Invocations: [(`sessionId`: [String], `plaintext`: [UInt8])] = []
    public var proteusEncryptBatchedSessionIdPlaintext_MockError: Error?
    public var proteusEncryptBatchedSessionIdPlaintext_MockMethod: (([String], [UInt8]) throws -> [String: [UInt8]])?
    public var proteusEncryptBatchedSessionIdPlaintext_MockValue: [String: [UInt8]]?

    public func `proteusEncryptBatched`(`sessionId`: [String], `plaintext`: [UInt8]) throws -> [String: [UInt8]] {
        proteusEncryptBatchedSessionIdPlaintext_Invocations.append((`sessionId`: `sessionId`, `plaintext`: `plaintext`))

        if let error = proteusEncryptBatchedSessionIdPlaintext_MockError {
            throw error
        }

        if let mock = proteusEncryptBatchedSessionIdPlaintext_MockMethod {
            return try mock(`sessionId`, `plaintext`)
        } else if let mock = proteusEncryptBatchedSessionIdPlaintext_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusEncryptBatchedSessionIdPlaintext`")
        }
    }

    // MARK: - `proteusNewPrekey`

    public var proteusNewPrekeyPrekeyId_Invocations: [UInt16] = []
    public var proteusNewPrekeyPrekeyId_MockError: Error?
    public var proteusNewPrekeyPrekeyId_MockMethod: ((UInt16) throws -> [UInt8])?
    public var proteusNewPrekeyPrekeyId_MockValue: [UInt8]?

    public func `proteusNewPrekey`(`prekeyId`: UInt16) throws -> [UInt8] {
        proteusNewPrekeyPrekeyId_Invocations.append(`prekeyId`)

        if let error = proteusNewPrekeyPrekeyId_MockError {
            throw error
        }

        if let mock = proteusNewPrekeyPrekeyId_MockMethod {
            return try mock(`prekeyId`)
        } else if let mock = proteusNewPrekeyPrekeyId_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusNewPrekeyPrekeyId`")
        }
    }

    // MARK: - `proteusNewPrekeyAuto`

    public var proteusNewPrekeyAuto_Invocations: [Void] = []
    public var proteusNewPrekeyAuto_MockError: Error?
    public var proteusNewPrekeyAuto_MockMethod: (() throws -> ProteusAutoPrekeyBundle)?
    public var proteusNewPrekeyAuto_MockValue: ProteusAutoPrekeyBundle?

    public func `proteusNewPrekeyAuto`() throws -> ProteusAutoPrekeyBundle {
        proteusNewPrekeyAuto_Invocations.append(())

        if let error = proteusNewPrekeyAuto_MockError {
            throw error
        }

        if let mock = proteusNewPrekeyAuto_MockMethod {
            return try mock()
        } else if let mock = proteusNewPrekeyAuto_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusNewPrekeyAuto`")
        }
    }

    // MARK: - `proteusLastResortPrekey`

    public var proteusLastResortPrekey_Invocations: [Void] = []
    public var proteusLastResortPrekey_MockError: Error?
    public var proteusLastResortPrekey_MockMethod: (() throws -> [UInt8])?
    public var proteusLastResortPrekey_MockValue: [UInt8]?

    public func `proteusLastResortPrekey`() throws -> [UInt8] {
        proteusLastResortPrekey_Invocations.append(())

        if let error = proteusLastResortPrekey_MockError {
            throw error
        }

        if let mock = proteusLastResortPrekey_MockMethod {
            return try mock()
        } else if let mock = proteusLastResortPrekey_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusLastResortPrekey`")
        }
    }

    // MARK: - `proteusLastResortPrekeyId`

    public var proteusLastResortPrekeyId_Invocations: [Void] = []
    public var proteusLastResortPrekeyId_MockError: Error?
    public var proteusLastResortPrekeyId_MockMethod: (() throws -> UInt16)?
    public var proteusLastResortPrekeyId_MockValue: UInt16?

    public func `proteusLastResortPrekeyId`() throws -> UInt16 {
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

    // MARK: - `proteusFingerprint`

    public var proteusFingerprint_Invocations: [Void] = []
    public var proteusFingerprint_MockError: Error?
    public var proteusFingerprint_MockMethod: (() throws -> String)?
    public var proteusFingerprint_MockValue: String?

    public func `proteusFingerprint`() throws -> String {
        proteusFingerprint_Invocations.append(())

        if let error = proteusFingerprint_MockError {
            throw error
        }

        if let mock = proteusFingerprint_MockMethod {
            return try mock()
        } else if let mock = proteusFingerprint_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusFingerprint`")
        }
    }

    // MARK: - `proteusFingerprintLocal`

    public var proteusFingerprintLocalSessionId_Invocations: [String] = []
    public var proteusFingerprintLocalSessionId_MockError: Error?
    public var proteusFingerprintLocalSessionId_MockMethod: ((String) throws -> String)?
    public var proteusFingerprintLocalSessionId_MockValue: String?

    public func `proteusFingerprintLocal`(`sessionId`: String) throws -> String {
        proteusFingerprintLocalSessionId_Invocations.append(`sessionId`)

        if let error = proteusFingerprintLocalSessionId_MockError {
            throw error
        }

        if let mock = proteusFingerprintLocalSessionId_MockMethod {
            return try mock(`sessionId`)
        } else if let mock = proteusFingerprintLocalSessionId_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusFingerprintLocalSessionId`")
        }
    }

    // MARK: - `proteusFingerprintRemote`

    public var proteusFingerprintRemoteSessionId_Invocations: [String] = []
    public var proteusFingerprintRemoteSessionId_MockError: Error?
    public var proteusFingerprintRemoteSessionId_MockMethod: ((String) throws -> String)?
    public var proteusFingerprintRemoteSessionId_MockValue: String?

    public func `proteusFingerprintRemote`(`sessionId`: String) throws -> String {
        proteusFingerprintRemoteSessionId_Invocations.append(`sessionId`)

        if let error = proteusFingerprintRemoteSessionId_MockError {
            throw error
        }

        if let mock = proteusFingerprintRemoteSessionId_MockMethod {
            return try mock(`sessionId`)
        } else if let mock = proteusFingerprintRemoteSessionId_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusFingerprintRemoteSessionId`")
        }
    }

    // MARK: - `proteusFingerprintPrekeybundle`

    public var proteusFingerprintPrekeybundlePrekey_Invocations: [[UInt8]] = []
    public var proteusFingerprintPrekeybundlePrekey_MockError: Error?
    public var proteusFingerprintPrekeybundlePrekey_MockMethod: (([UInt8]) throws -> String)?
    public var proteusFingerprintPrekeybundlePrekey_MockValue: String?

    public func `proteusFingerprintPrekeybundle`(`prekey`: [UInt8]) throws -> String {
        proteusFingerprintPrekeybundlePrekey_Invocations.append(`prekey`)

        if let error = proteusFingerprintPrekeybundlePrekey_MockError {
            throw error
        }

        if let mock = proteusFingerprintPrekeybundlePrekey_MockMethod {
            return try mock(`prekey`)
        } else if let mock = proteusFingerprintPrekeybundlePrekey_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusFingerprintPrekeybundlePrekey`")
        }
    }

    // MARK: - `proteusCryptoboxMigrate`

    public var proteusCryptoboxMigratePath_Invocations: [String] = []
    public var proteusCryptoboxMigratePath_MockError: Error?
    public var proteusCryptoboxMigratePath_MockMethod: ((String) throws -> Void)?

    public func `proteusCryptoboxMigrate`(`path`: String) throws {
        proteusCryptoboxMigratePath_Invocations.append(`path`)

        if let error = proteusCryptoboxMigratePath_MockError {
            throw error
        }

        guard let mock = proteusCryptoboxMigratePath_MockMethod else {
            fatalError("no mock for `proteusCryptoboxMigratePath`")
        }

        try mock(`path`)            
    }

    // MARK: - `proteusLastErrorCode`

    public var proteusLastErrorCode_Invocations: [Void] = []
    public var proteusLastErrorCode_MockMethod: (() -> UInt32)?
    public var proteusLastErrorCode_MockValue: UInt32?

    public func `proteusLastErrorCode`() -> UInt32 {
        proteusLastErrorCode_Invocations.append(())

        if let mock = proteusLastErrorCode_MockMethod {
            return mock()
        } else if let mock = proteusLastErrorCode_MockValue {
            return mock
        } else {
            fatalError("no mock for `proteusLastErrorCode`")
        }
    }

    // MARK: - `e2eiNewEnrollment`

    public var e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_Invocations: [(`clientId`: String, `displayName`: String, `handle`: String, `expiryDays`: UInt32, `ciphersuite`: CiphersuiteName)] = []
    public var e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockError: Error?
    public var e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockMethod: ((String, String, String, UInt32, CiphersuiteName) throws -> WireE2eIdentity)?
    public var e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockValue: WireE2eIdentity?

    public func `e2eiNewEnrollment`(`clientId`: String, `displayName`: String, `handle`: String, `expiryDays`: UInt32, `ciphersuite`: CiphersuiteName) throws -> WireE2eIdentity {
        e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_Invocations.append((`clientId`: `clientId`, `displayName`: `displayName`, `handle`: `handle`, `expiryDays`: `expiryDays`, `ciphersuite`: `ciphersuite`))

        if let error = e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockError {
            throw error
        }

        if let mock = e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockMethod {
            return try mock(`clientId`, `displayName`, `handle`, `expiryDays`, `ciphersuite`)
        } else if let mock = e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiNewEnrollmentClientIdDisplayNameHandleExpiryDaysCiphersuite`")
        }
    }

    // MARK: - `e2eiMlsInit`

    public var e2eiMlsInitEnrollmentCertificateChain_Invocations: [(`enrollment`: WireE2eIdentity, `certificateChain`: String)] = []
    public var e2eiMlsInitEnrollmentCertificateChain_MockError: Error?
    public var e2eiMlsInitEnrollmentCertificateChain_MockMethod: ((WireE2eIdentity, String) throws -> Void)?

    public func `e2eiMlsInit`(`enrollment`: WireE2eIdentity, `certificateChain`: String) throws {
        e2eiMlsInitEnrollmentCertificateChain_Invocations.append((`enrollment`: `enrollment`, `certificateChain`: `certificateChain`))

        if let error = e2eiMlsInitEnrollmentCertificateChain_MockError {
            throw error
        }

        guard let mock = e2eiMlsInitEnrollmentCertificateChain_MockMethod else {
            fatalError("no mock for `e2eiMlsInitEnrollmentCertificateChain`")
        }

        try mock(`enrollment`, `certificateChain`)            
    }

    // MARK: - `e2eiEnrollmentStash`

    public var e2eiEnrollmentStashEnrollment_Invocations: [WireE2eIdentity] = []
    public var e2eiEnrollmentStashEnrollment_MockError: Error?
    public var e2eiEnrollmentStashEnrollment_MockMethod: ((WireE2eIdentity) throws -> [UInt8])?
    public var e2eiEnrollmentStashEnrollment_MockValue: [UInt8]?

    public func `e2eiEnrollmentStash`(`enrollment`: WireE2eIdentity) throws -> [UInt8] {
        e2eiEnrollmentStashEnrollment_Invocations.append(`enrollment`)

        if let error = e2eiEnrollmentStashEnrollment_MockError {
            throw error
        }

        if let mock = e2eiEnrollmentStashEnrollment_MockMethod {
            return try mock(`enrollment`)
        } else if let mock = e2eiEnrollmentStashEnrollment_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiEnrollmentStashEnrollment`")
        }
    }

    // MARK: - `e2eiEnrollmentStashPop`

    public var e2eiEnrollmentStashPopHandle_Invocations: [[UInt8]] = []
    public var e2eiEnrollmentStashPopHandle_MockError: Error?
    public var e2eiEnrollmentStashPopHandle_MockMethod: (([UInt8]) throws -> WireE2eIdentity)?
    public var e2eiEnrollmentStashPopHandle_MockValue: WireE2eIdentity?

    public func `e2eiEnrollmentStashPop`(`handle`: [UInt8]) throws -> WireE2eIdentity {
        e2eiEnrollmentStashPopHandle_Invocations.append(`handle`)

        if let error = e2eiEnrollmentStashPopHandle_MockError {
            throw error
        }

        if let mock = e2eiEnrollmentStashPopHandle_MockMethod {
            return try mock(`handle`)
        } else if let mock = e2eiEnrollmentStashPopHandle_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eiEnrollmentStashPopHandle`")
        }
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

    public var performMigrationAccountDirectorySyncContext_Invocations: [(accountDirectory: URL, syncContext: NSManagedObjectContext)] = []
    public var performMigrationAccountDirectorySyncContext_MockError: Error?
    public var performMigrationAccountDirectorySyncContext_MockMethod: ((URL, NSManagedObjectContext) throws -> Void)?

    public func performMigration(accountDirectory: URL, syncContext: NSManagedObjectContext) throws {
        performMigrationAccountDirectorySyncContext_Invocations.append((accountDirectory: accountDirectory, syncContext: syncContext))

        if let error = performMigrationAccountDirectorySyncContext_MockError {
            throw error
        }

        guard let mock = performMigrationAccountDirectorySyncContext_MockMethod else {
            fatalError("no mock for `performMigrationAccountDirectorySyncContext`")
        }

        try mock(accountDirectory, syncContext)            
    }

    // MARK: - completeMigration

    public var completeMigrationSyncContext_Invocations: [NSManagedObjectContext] = []
    public var completeMigrationSyncContext_MockError: Error?
    public var completeMigrationSyncContext_MockMethod: ((NSManagedObjectContext) throws -> Void)?

    public func completeMigration(syncContext: NSManagedObjectContext) throws {
        completeMigrationSyncContext_Invocations.append(syncContext)

        if let error = completeMigrationSyncContext_MockError {
            throw error
        }

        guard let mock = completeMigrationSyncContext_MockMethod else {
            fatalError("no mock for `completeMigrationSyncContext`")
        }

        try mock(syncContext)            
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
    public var fetchPublicKeys_MockMethod: (() throws -> EARPublicKeys)?
    public var fetchPublicKeys_MockValue: EARPublicKeys?

    public func fetchPublicKeys() throws -> EARPublicKeys {
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
    public var fetchPrivateKeysIncludingPrimary_MockMethod: ((Bool) throws -> EARPrivateKeys)?
    public var fetchPrivateKeysIncludingPrimary_MockValue: EARPrivateKeys?

    public func fetchPrivateKeys(includingPrimary: Bool) throws -> EARPrivateKeys {
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
public class MockProteusServiceInterface: ProteusServiceInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - lastPrekeyID

    public var lastPrekeyID: UInt16 {
        get { return underlyingLastPrekeyID }
        set(value) { underlyingLastPrekeyID = value }
    }

    public var underlyingLastPrekeyID: UInt16!


    // MARK: - completeInitialization

    public var completeInitialization_Invocations: [Void] = []
    public var completeInitialization_MockError: Error?
    public var completeInitialization_MockMethod: (() throws -> Void)?

    public func completeInitialization() throws {
        completeInitialization_Invocations.append(())

        if let error = completeInitialization_MockError {
            throw error
        }

        guard let mock = completeInitialization_MockMethod else {
            fatalError("no mock for `completeInitialization`")
        }

        try mock()            
    }

    // MARK: - establishSession

    public var establishSessionIdFromPrekey_Invocations: [(id: ProteusSessionID, fromPrekey: String)] = []
    public var establishSessionIdFromPrekey_MockError: Error?
    public var establishSessionIdFromPrekey_MockMethod: ((ProteusSessionID, String) throws -> Void)?

    public func establishSession(id: ProteusSessionID, fromPrekey: String) throws {
        establishSessionIdFromPrekey_Invocations.append((id: id, fromPrekey: fromPrekey))

        if let error = establishSessionIdFromPrekey_MockError {
            throw error
        }

        guard let mock = establishSessionIdFromPrekey_MockMethod else {
            fatalError("no mock for `establishSessionIdFromPrekey`")
        }

        try mock(id, fromPrekey)            
    }

    // MARK: - deleteSession

    public var deleteSessionId_Invocations: [ProteusSessionID] = []
    public var deleteSessionId_MockError: Error?
    public var deleteSessionId_MockMethod: ((ProteusSessionID) throws -> Void)?

    public func deleteSession(id: ProteusSessionID) throws {
        deleteSessionId_Invocations.append(id)

        if let error = deleteSessionId_MockError {
            throw error
        }

        guard let mock = deleteSessionId_MockMethod else {
            fatalError("no mock for `deleteSessionId`")
        }

        try mock(id)            
    }

    // MARK: - sessionExists

    public var sessionExistsId_Invocations: [ProteusSessionID] = []
    public var sessionExistsId_MockMethod: ((ProteusSessionID) -> Bool)?
    public var sessionExistsId_MockValue: Bool?

    public func sessionExists(id: ProteusSessionID) -> Bool {
        sessionExistsId_Invocations.append(id)

        if let mock = sessionExistsId_MockMethod {
            return mock(id)
        } else if let mock = sessionExistsId_MockValue {
            return mock
        } else {
            fatalError("no mock for `sessionExistsId`")
        }
    }

    // MARK: - encrypt

    public var encryptDataForSession_Invocations: [(data: Data, id: ProteusSessionID)] = []
    public var encryptDataForSession_MockError: Error?
    public var encryptDataForSession_MockMethod: ((Data, ProteusSessionID) throws -> Data)?
    public var encryptDataForSession_MockValue: Data?

    public func encrypt(data: Data, forSession id: ProteusSessionID) throws -> Data {
        encryptDataForSession_Invocations.append((data: data, id: id))

        if let error = encryptDataForSession_MockError {
            throw error
        }

        if let mock = encryptDataForSession_MockMethod {
            return try mock(data, id)
        } else if let mock = encryptDataForSession_MockValue {
            return mock
        } else {
            fatalError("no mock for `encryptDataForSession`")
        }
    }

    // MARK: - encryptBatched

    public var encryptBatchedDataForSessions_Invocations: [(data: Data, sessions: [ProteusSessionID])] = []
    public var encryptBatchedDataForSessions_MockError: Error?
    public var encryptBatchedDataForSessions_MockMethod: ((Data, [ProteusSessionID]) throws -> [String: Data])?
    public var encryptBatchedDataForSessions_MockValue: [String: Data]?

    public func encryptBatched(data: Data, forSessions sessions: [ProteusSessionID]) throws -> [String: Data] {
        encryptBatchedDataForSessions_Invocations.append((data: data, sessions: sessions))

        if let error = encryptBatchedDataForSessions_MockError {
            throw error
        }

        if let mock = encryptBatchedDataForSessions_MockMethod {
            return try mock(data, sessions)
        } else if let mock = encryptBatchedDataForSessions_MockValue {
            return mock
        } else {
            fatalError("no mock for `encryptBatchedDataForSessions`")
        }
    }

    // MARK: - decrypt

    public var decryptDataForSession_Invocations: [(data: Data, id: ProteusSessionID)] = []
    public var decryptDataForSession_MockError: Error?
    public var decryptDataForSession_MockMethod: ((Data, ProteusSessionID) throws -> (didCreateSession: Bool, decryptedData: Data))?
    public var decryptDataForSession_MockValue: (didCreateSession: Bool, decryptedData: Data)?

    public func decrypt(data: Data, forSession id: ProteusSessionID) throws -> (didCreateSession: Bool, decryptedData: Data) {
        decryptDataForSession_Invocations.append((data: data, id: id))

        if let error = decryptDataForSession_MockError {
            throw error
        }

        if let mock = decryptDataForSession_MockMethod {
            return try mock(data, id)
        } else if let mock = decryptDataForSession_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptDataForSession`")
        }
    }

    // MARK: - generatePrekey

    public var generatePrekeyId_Invocations: [UInt16] = []
    public var generatePrekeyId_MockError: Error?
    public var generatePrekeyId_MockMethod: ((UInt16) throws -> String)?
    public var generatePrekeyId_MockValue: String?

    public func generatePrekey(id: UInt16) throws -> String {
        generatePrekeyId_Invocations.append(id)

        if let error = generatePrekeyId_MockError {
            throw error
        }

        if let mock = generatePrekeyId_MockMethod {
            return try mock(id)
        } else if let mock = generatePrekeyId_MockValue {
            return mock
        } else {
            fatalError("no mock for `generatePrekeyId`")
        }
    }

    // MARK: - lastPrekey

    public var lastPrekey_Invocations: [Void] = []
    public var lastPrekey_MockError: Error?
    public var lastPrekey_MockMethod: (() throws -> String)?
    public var lastPrekey_MockValue: String?

    public func lastPrekey() throws -> String {
        lastPrekey_Invocations.append(())

        if let error = lastPrekey_MockError {
            throw error
        }

        if let mock = lastPrekey_MockMethod {
            return try mock()
        } else if let mock = lastPrekey_MockValue {
            return mock
        } else {
            fatalError("no mock for `lastPrekey`")
        }
    }

    // MARK: - generatePrekeys

    public var generatePrekeysStartCount_Invocations: [(start: UInt16, count: UInt16)] = []
    public var generatePrekeysStartCount_MockError: Error?
    public var generatePrekeysStartCount_MockMethod: ((UInt16, UInt16) throws -> [IdPrekeyTuple])?
    public var generatePrekeysStartCount_MockValue: [IdPrekeyTuple]?

    public func generatePrekeys(start: UInt16, count: UInt16) throws -> [IdPrekeyTuple] {
        generatePrekeysStartCount_Invocations.append((start: start, count: count))

        if let error = generatePrekeysStartCount_MockError {
            throw error
        }

        if let mock = generatePrekeysStartCount_MockMethod {
            return try mock(start, count)
        } else if let mock = generatePrekeysStartCount_MockValue {
            return mock
        } else {
            fatalError("no mock for `generatePrekeysStartCount`")
        }
    }

    // MARK: - localFingerprint

    public var localFingerprint_Invocations: [Void] = []
    public var localFingerprint_MockError: Error?
    public var localFingerprint_MockMethod: (() throws -> String)?
    public var localFingerprint_MockValue: String?

    public func localFingerprint() throws -> String {
        localFingerprint_Invocations.append(())

        if let error = localFingerprint_MockError {
            throw error
        }

        if let mock = localFingerprint_MockMethod {
            return try mock()
        } else if let mock = localFingerprint_MockValue {
            return mock
        } else {
            fatalError("no mock for `localFingerprint`")
        }
    }

    // MARK: - remoteFingerprint

    public var remoteFingerprintForSession_Invocations: [ProteusSessionID] = []
    public var remoteFingerprintForSession_MockError: Error?
    public var remoteFingerprintForSession_MockMethod: ((ProteusSessionID) throws -> String)?
    public var remoteFingerprintForSession_MockValue: String?

    public func remoteFingerprint(forSession id: ProteusSessionID) throws -> String {
        remoteFingerprintForSession_Invocations.append(id)

        if let error = remoteFingerprintForSession_MockError {
            throw error
        }

        if let mock = remoteFingerprintForSession_MockMethod {
            return try mock(id)
        } else if let mock = remoteFingerprintForSession_MockValue {
            return mock
        } else {
            fatalError("no mock for `remoteFingerprintForSession`")
        }
    }

    // MARK: - fingerprint

    public var fingerprintFromPrekey_Invocations: [String] = []
    public var fingerprintFromPrekey_MockError: Error?
    public var fingerprintFromPrekey_MockMethod: ((String) throws -> String)?
    public var fingerprintFromPrekey_MockValue: String?

    public func fingerprint(fromPrekey prekey: String) throws -> String {
        fingerprintFromPrekey_Invocations.append(prekey)

        if let error = fingerprintFromPrekey_MockError {
            throw error
        }

        if let mock = fingerprintFromPrekey_MockMethod {
            return try mock(prekey)
        } else if let mock = fingerprintFromPrekey_MockValue {
            return mock
        } else {
            fatalError("no mock for `fingerprintFromPrekey`")
        }
    }

    // MARK: - migrateCryptoboxSessions

    public var migrateCryptoboxSessionsAt_Invocations: [URL] = []
    public var migrateCryptoboxSessionsAt_MockError: Error?
    public var migrateCryptoboxSessionsAt_MockMethod: ((URL) throws -> Void)?

    public func migrateCryptoboxSessions(at url: URL) throws {
        migrateCryptoboxSessionsAt_Invocations.append(url)

        if let error = migrateCryptoboxSessionsAt_MockError {
            throw error
        }

        guard let mock = migrateCryptoboxSessionsAt_MockMethod else {
            fatalError("no mock for `migrateCryptoboxSessionsAt`")
        }

        try mock(url)            
    }

}
