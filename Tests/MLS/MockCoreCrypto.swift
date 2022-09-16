//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

class MockCoreCrypto: CoreCryptoProtocol {

    // MARK: - Types

    struct Calls {

        var setCallbacksCount = 0
        var clientPublicKey: [Void] = []
        var clientKeypackages = [UInt32]()
        var clientValidKeypackagesCount: [Void] = []
        var createConversation = [(conversationId: ConversationId, config: ConversationConfiguration)]()
        var conversationExists = [ConversationId]()
        var processWelcomeMessage = [[UInt8]]()
        var addClientsToConversation = [(conversationId: ConversationId, clients: [Invitee])]()
        var removeClientsFromConversation = [(conversationId: ConversationId, clients: [ClientId])]()
        var wipeConversation = [ConversationId]()
        var decryptMessage = [(conversationId: ConversationId, payload: [UInt8])]()
        var encryptMessage = [(conversationId: ConversationId, message: [UInt8])]()
        var newAddProposal = [(conversationId: ConversationId, keyPackage: [UInt8])]()
        var newUpdateProposal = [ConversationId]()
        var newRemoveProposal = [(conversationId: ConversationId, clientId: ClientId)]()
        var newExternalAddProposal = [(conversationId: ConversationId, epoch: UInt64)]()
        var newExternalRemoveProposal = [(conversationId: ConversationId, epoch: UInt64, keyPackageRef: [UInt8])]()
        var updateKeyingMaterial = [ConversationId]()
        var joinByExternalCommit = [[UInt8]]()
        var exportGroupState = [ConversationId]()
        var mergePendingGroupFromExternalCommit = [(conversationId: ConversationId, config: ConversationConfiguration)]()
        var randomBytes = [UInt32]()
        var reseedRng = [[UInt8]]()
        var commitAccepted = [ConversationId]()
        var commitPendingProposals = [(ConversationId, Date)]()
    }

    // MARK: - Properties

    var calls = Calls()

    // MARK: - setCallbacks

    var mockErrorForSetCallbacks: CryptoError?

    func wire_setCallbacks(callbacks: CoreCryptoCallbacks) throws {
        calls.setCallbacksCount += 1

        if let error = mockErrorForSetCallbacks {
            throw error
        }
    }

    // MARK: - clientPublicKey

    var mockResultForClientPublicKey: [UInt8]?
    var mockErrorForClientPublicKey: CryptoError?

    func wire_clientPublicKey() throws -> [UInt8] {
        calls.clientPublicKey.append(())

        if let error = mockErrorForClientPublicKey {
            throw error
        }

        return try XCTUnwrap(mockResultForClientPublicKey, "no mocked result for `clientPublicKey`")
    }

    // MARK: - clientKeypackages

    var mockResultForClientKeypackages: [[UInt8]]?
    var mockErrorForClientKeypackages: CryptoError?

    func wire_clientKeypackages(amountRequested: UInt32) throws -> [[UInt8]] {
        calls.clientKeypackages.append(amountRequested)

        if let error = mockErrorForClientKeypackages {
            throw error
        }

        return try XCTUnwrap(mockResultForClientKeypackages, "no mocked result for `clientKeypackages`")
    }

    // MARK: - clientValidKeypackagesCount

    var mockResultForClientValidKeypackagesCount: UInt64?
    var mockErrorForClientValidKeypackagesCount: CryptoError?

    func wire_clientValidKeypackagesCount() throws -> UInt64 {
        calls.clientValidKeypackagesCount.append(())

        if let error = mockErrorForClientValidKeypackagesCount {
            throw error
        }

        return try XCTUnwrap(mockResultForClientValidKeypackagesCount, "no mocked result for `clientValidKeypackagesCount`")
    }

    // MARK: - createConversation

    var mockErrorForCreateConversation: CryptoError?

    func wire_createConversation(conversationId: ConversationId, config: ConversationConfiguration) throws {
        calls.createConversation.append((conversationId, config))

        if let error = mockErrorForCreateConversation {
            throw error
        }
    }

    // MARK: - conversationExists

    var mockResultForConversationExists: Bool?

    func wire_conversationExists(conversationId: ConversationId) -> Bool {
        calls.conversationExists.append(conversationId)

        let result = try? XCTUnwrap(mockResultForConversationExists, "no mocked result for `conversationExists`")
        return result ?? false
    }

    // MARK: - processWelcomeMessage

    var mockResultForProcessWelcomeMessage: ConversationId?
    var mockErrorForProcessWelcomeMessage: CryptoError?

    func wire_processWelcomeMessage(welcomeMessage: [UInt8]) throws -> ConversationId {
        calls.processWelcomeMessage.append(welcomeMessage)

        if let error = mockErrorForProcessWelcomeMessage {
            throw error
        }

        return try XCTUnwrap(mockResultForProcessWelcomeMessage, "no mocked result for `processWelcomeMessage`")
    }

    // MARK: - addClientsToConversation

    var mockResultForAddClientsToConversation: MemberAddedMessages?
    var mockErrorForAddClientsToConversation: CryptoError?

    func wire_addClientsToConversation(conversationId: ConversationId, clients: [Invitee]) throws -> MemberAddedMessages {
        calls.addClientsToConversation.append((conversationId, clients))

        if let error = mockErrorForAddClientsToConversation {
            throw error
        }

        return try XCTUnwrap(mockResultForAddClientsToConversation, "no mocked result for `addClientsToConversation`")
    }

    // MARK: - removeClientsFromConversation

    var mockResultForRemoveClientsFromConversation: CommitBundle?
    var mockErrorForRemoveClientsFromConversation: CryptoError?

    func wire_removeClientsFromConversation(conversationId: ConversationId, clients: [ClientId]) throws -> CommitBundle {
        calls.removeClientsFromConversation.append((conversationId, clients))

        if let error = mockErrorForRemoveClientsFromConversation {
            throw error
        }

        return try XCTUnwrap(mockResultForRemoveClientsFromConversation, "no mocked result for `removeClientsFromConversation`")
    }

    // MARK: - wipeConversation

    var mockErrorForWipeConversation: CryptoError?

    func wire_wipeConversation(conversationId: ConversationId) throws {
        calls.wipeConversation.append(conversationId)

        if let error = mockErrorForWipeConversation {
            throw error
        }
    }

    // MARK: - decryptMessage

    var mockResultForDecryptMessage: DecryptedMessage?
    var mockErrorForDecryptMessage: CryptoError?

    func wire_decryptMessage(conversationId: ConversationId, payload: [UInt8]) throws -> DecryptedMessage {
        calls.decryptMessage.append((conversationId, payload))

        if let error = mockErrorForDecryptMessage {
            throw error
        }

        return try XCTUnwrap(mockResultForDecryptMessage, "no mocked result for `decryptMessage`")
    }

    // MARK: - encryptMessage

    var mockResultForEncryptMessage: [UInt8]?
    var mockErrorForEncryptMessage: CryptoError?

    func wire_encryptMessage(conversationId: ConversationId, message: [UInt8]) throws -> [UInt8] {
        calls.encryptMessage.append((conversationId, message))

        if let error = mockErrorForEncryptMessage {
            throw error
        }

        return try XCTUnwrap(mockResultForEncryptMessage, "no mocked result for `encryptMessage`")
    }

    // MARK: - newAddProposal

    var mockResultForNewAddProposal: [UInt8]?
    var mockErrorForNewAddProposal: CryptoError?

    func wire_newAddProposal(conversationId: ConversationId, keyPackage: [UInt8]) throws -> [UInt8] {
        calls.newAddProposal.append((conversationId, keyPackage))

        if let error = mockErrorForNewAddProposal {
            throw error
        }

        return try XCTUnwrap(mockResultForNewAddProposal, "no mocked result for `newAddProposal`")
    }

    // MARK: - newUpdateProposal

    var mockResultForNewUpdateProposal: [UInt8]?
    var mockErrorForNewUpdateProposal: CryptoError?

    func wire_newUpdateProposal(conversationId: ConversationId) throws -> [UInt8] {
        calls.newUpdateProposal.append(conversationId)

        if let error = mockErrorForNewUpdateProposal {
            throw error
        }

        return try XCTUnwrap(mockResultForNewUpdateProposal, "no mocked result for `newUpdateProposal`")
    }

    // MARK: - newRemoveProposal

    var mockResultForNewRemoveProposal: [UInt8]?
    var mockErrorForNewRemoveProposal: CryptoError?

    func wire_newRemoveProposal(conversationId: ConversationId, clientId: ClientId) throws -> [UInt8] {
        calls.newRemoveProposal.append((conversationId, clientId))

        if let error = mockErrorForNewRemoveProposal {
            throw error
        }

        return try XCTUnwrap(mockResultForNewRemoveProposal, "no mocked result for `newRemoveProposal`")
    }

    // MARK: - newExternalAddProposal

    var mockResultForNewExternalAddProposal: [UInt8]?
    var mockErrorForNewExternalAddProposal: CryptoError?

    func wire_newExternalAddProposal(conversationId: ConversationId, epoch: UInt64) throws -> [UInt8] {
        calls.newExternalAddProposal.append((conversationId, epoch))

        if let error = mockErrorForNewExternalAddProposal {
            throw error
        }

        return try XCTUnwrap(mockResultForNewExternalAddProposal, "no mocked result for `newExternalAddProposal`")
    }

    // MARK: - newExternalRemoveProposal

    var mockResultForNewExternalRemoveProposal: [UInt8]?
    var mockErrorForNewExternalRemoveProposal: CryptoError?

    func wire_newExternalRemoveProposal(conversationId: ConversationId, epoch: UInt64, keyPackageRef: [UInt8]) throws -> [UInt8] {
        calls.newExternalRemoveProposal.append((conversationId, epoch, keyPackageRef))

        if let error = mockErrorForNewExternalRemoveProposal {
            throw error
        }

        return try XCTUnwrap(mockResultForNewExternalRemoveProposal, "no mocked result for `newExternalRemoveProposal`")
    }

    // MARK: - updateKeyingMaterial

    var mockResultForUpdateKeyingMaterial: CommitBundle?
    var mockErrorForUpdateKeyingMaterial: CryptoError?

    func wire_updateKeyingMaterial(conversationId: ConversationId) throws -> CommitBundle {
        calls.updateKeyingMaterial.append(conversationId)

        if let error = mockErrorForUpdateKeyingMaterial {
            throw error
        }

        return try XCTUnwrap(mockResultForUpdateKeyingMaterial, "no mocked result for `updateKeyingMaterial`")
    }

    // MARK: - joinByExternalCommit

    var mockResultForJoinByExternalCommit: MlsConversationInitMessage?
    var mockErrorForJoinByExternalCommit: CryptoError?

    func wire_joinByExternalCommit(groupState: [UInt8]) throws -> MlsConversationInitMessage {
        calls.joinByExternalCommit.append(groupState)

        if let error = mockErrorForJoinByExternalCommit {
            throw error
        }

        return try XCTUnwrap(mockResultForJoinByExternalCommit, "no mocked result for `joinByExternalCommit`")
    }

    // MARK: - exportGroupState

    var mockResultForExportGroupState: [UInt8]?
    var mockErrorForExportGroupState: CryptoError?

    func wire_exportGroupState(conversationId: ConversationId) throws -> [UInt8] {
        calls.exportGroupState.append(conversationId)

        if let error = mockErrorForExportGroupState {
            throw error
        }

        return try XCTUnwrap(mockResultForExportGroupState, "no mocked result for `exportGroupState`")
    }

    // MARK: - mergePendingGroupFromExternalCommit

    var mockErrorForMergePendingGroupFromExternalCommit: CryptoError?

    func wire_mergePendingGroupFromExternalCommit(conversationId: ConversationId, config: ConversationConfiguration) throws {
        calls.mergePendingGroupFromExternalCommit.append((conversationId, config))

        if let error = mockErrorForMergePendingGroupFromExternalCommit {
            throw error
        }
    }

    // MARK: - randomBytes

    var mockResultForRandomBytes: [UInt8]?
    var mockErrorForRandomBytes: CryptoError?

    func wire_randomBytes(length: UInt32) throws -> [UInt8] {
        calls.randomBytes.append(length)

        if let error = mockErrorForRandomBytes {
            throw error
        }

        return try XCTUnwrap(mockResultForRandomBytes, "no mocked result for `randomBytes`")
    }

    // MARK: - reseedRng

    var mockErrorForReseedRng: CryptoError?

    func wire_reseedRng(seed: [UInt8]) throws {
        calls.reseedRng.append(seed)

        if let error = mockErrorForReseedRng {
            throw error
        }
    }

    // MARK: - commitAccepted

    var mockErrorForCommitAccepted: CryptoError?

    func wire_commitAccepted(conversationId: ConversationId) throws {
        calls.commitAccepted.append(conversationId)

        if let error = mockErrorForCommitAccepted {
            throw error
        }
    }

    // MARK: - commitPendingProposals

    var mockResultForCommitPendingProposals: CommitBundle?
    var mockErrorForCommitPendingProposals: CryptoError?

    func wire_commitPendingProposals(conversationId: ConversationId) throws -> CommitBundle {
        calls.commitPendingProposals.append((conversationId, Date()))

        if let error = mockErrorForCommitPendingProposals {
            throw error
        }

        return try XCTUnwrap(mockResultForCommitPendingProposals, "no mocked result for `commitPendingProposals`")
    }

}
