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

    // MARK: - setCallbacks

    func wire_setCallbacks(callbacks: CoreCryptoCallbacks) throws {

    }

    // MARK: - clientPublicKey

    var mockClientPublicKey: (() throws -> [UInt8])?

    func wire_clientPublicKey() throws -> [UInt8] {
        guard let mock = mockClientPublicKey else {
            fatalError("no mock for `clientPublicKey`")
        }

        return try mock()
    }

    // MARK: - clientKeypackages

    var mockClientKeypackages: ((UInt32) throws -> [[UInt8]])?

    func wire_clientKeypackages(amountRequested: UInt32) throws -> [[UInt8]] {
        guard let mock = mockClientKeypackages else {
            fatalError("no mock for `clientKeypackages`")
        }

        return try mock(amountRequested)
    }

    // MARK: - clientValidKeypackagesCount

    var mockClientValidKeypackagesCount: (() throws -> UInt64)?

    func wire_clientValidKeypackagesCount() throws -> UInt64 {
        guard let mock = mockClientValidKeypackagesCount else {
            fatalError("no mock for `clientValidKeypackagesCount`")
        }

        return try mock()
    }

    // MARK: - createConversation

    var mockCreateConversation: ((ConversationId, ConversationConfiguration) throws -> Void)?

    func wire_createConversation(conversationId: ConversationId, config: ConversationConfiguration) throws {
        guard let mock = mockCreateConversation else {
            fatalError("no mock for `createConversation`")
        }

        return try mock(conversationId, config)
    }

    // MARK: - conversationEpoch

    var mockConversationEpoch: ((ConversationId) throws -> UInt64)?

    func wire_conversationEpoch(conversationId: ConversationId) throws -> UInt64 {
        guard let mock = mockConversationEpoch else {
            fatalError("no mock for `conversationEpoch`")
        }

        return try mock(conversationId)
    }

    // MARK: - conversationExists

    var mockConversationExists: ((ConversationId) -> Bool)?

    func wire_conversationExists(conversationId: ConversationId) -> Bool {
        guard let mock = mockConversationExists else {
            fatalError("no mock for `conversationExists`")
        }

        return mock(conversationId)
    }

    // MARK: - processWelcomeMessage

    var mockProcessWelcomeMessage: (([UInt8]) throws -> ConversationId)?

    func wire_processWelcomeMessage(welcomeMessage: [UInt8]) throws -> ConversationId {
        guard let mock = mockProcessWelcomeMessage else {
            fatalError("no mock for `processWelcomeMessage`")
        }

        return try mock(welcomeMessage)
    }

    // MARK: - addClientsToConversation

    var mockAddClientsToConversation: ((ConversationId, [Invitee]) throws -> MemberAddedMessages)?

    func wire_addClientsToConversation(conversationId: ConversationId, clients: [Invitee]) throws -> MemberAddedMessages {
        guard let mock = mockAddClientsToConversation else {
            fatalError("no mock for `addClientsToConversation`")
        }

        return try mock(conversationId, clients)
    }

    // MARK: - removeClientsFromConversation

    var mockRemoveClientsFromConversation: ((ConversationId, [ClientId]) throws -> CommitBundle)?

    func wire_removeClientsFromConversation(conversationId: ConversationId, clients: [ClientId]) throws -> CommitBundle {
        guard let mock = mockRemoveClientsFromConversation else {
            fatalError("no mock for `removeClientsFromConversation`")
        }

        return try mock(conversationId, clients)
    }

    // MARK: - updateKeyingMaterial

    var mockUpdateKeyingMaterial: ((ConversationId) throws -> CommitBundle)?

    func wire_updateKeyingMaterial(conversationId: ConversationId) throws -> CommitBundle {
        guard let mock = mockUpdateKeyingMaterial else {
            fatalError("no mock for `updateKeyingMaterial`")
        }

        return try mock(conversationId)
    }

    // MARK: - commitPendingProposals

    var mockCommitPendingProposals: ((ConversationId) throws -> CommitBundle?)?

    func wire_commitPendingProposals(conversationId: ConversationId) throws -> CommitBundle? {
        guard let mock = mockCommitPendingProposals else {
            fatalError("no mock for `commitPendingProposals`")
        }

        return try mock(conversationId)
    }

    // MARK: - wipeConversation

    var mockWipeConversation: ((ConversationId) throws -> Void)?

    func wire_wipeConversation(conversationId: ConversationId) throws {
        guard let mock = mockWipeConversation else {
            fatalError("no mock for `wipeConversation`")
        }

        return try mock(conversationId)
    }

    // MARK: - decryptMessage

    var mockDecryptMessage: ((ConversationId, [UInt8]) throws -> DecryptedMessage)?

    func wire_decryptMessage(conversationId: ConversationId, payload: [UInt8]) throws -> DecryptedMessage {
        guard let mock = mockDecryptMessage else {
            fatalError("no mock for `decryptMessage`")
        }

        return try mock(conversationId, payload)
    }

    // MARK: - encryptMessage

    var mockEncryptMessage: ((ConversationId, [UInt8]) throws -> [UInt8])?

    func wire_encryptMessage(conversationId: ConversationId, message: [UInt8]) throws -> [UInt8] {
        guard let mock = mockEncryptMessage else {
            fatalError("no mock for `encryptMessage`")
        }

        return try mock(conversationId, message)
    }

    // MARK: - newAddProposal

    var mockNewAddProposal: ((ConversationId, [UInt8]) throws -> ProposalBundle)?

    func wire_newAddProposal(conversationId: ConversationId, keyPackage: [UInt8]) throws -> ProposalBundle {
        guard let mock = mockNewAddProposal else {
            fatalError("no mock for `newAddProposal`")
        }

        return try mock(conversationId, keyPackage)
    }

    // MARK: - newUpdateProposal

    var mockNewUpdateProposal: ((ConversationId) throws -> ProposalBundle)?

    func wire_newUpdateProposal(conversationId: ConversationId) throws -> ProposalBundle {
        guard let mock = mockNewUpdateProposal else {
            fatalError("no mock for `newUpdateProposal`")
        }

        return try mock(conversationId)
    }

    // MARK: - newRemoveProposal

    var mockNewRemoveProposal: ((ConversationId, ClientId) throws -> ProposalBundle)?

    func wire_newRemoveProposal(conversationId: ConversationId, clientId: ClientId) throws -> ProposalBundle {
        guard let mock = mockNewRemoveProposal else {
            fatalError("no mock for `newRemoveProposal`")
        }

        return try mock(conversationId, clientId)
    }

    // MARK: - newExternalAddProposal

    var mockNewExternalAddProposal: ((ConversationId, UInt64) throws -> [UInt8])?

    func wire_newExternalAddProposal(conversationId: ConversationId, epoch: UInt64) throws -> [UInt8] {
        guard let mock = mockNewExternalAddProposal else {
            fatalError("no mock for `newExternalAddProposal`")
        }

        return try mock(conversationId, epoch)
    }

    // MARK: - newExternalRemoveProposal

    var mockNewExternalRemoveProposal: ((ConversationId, UInt64, [UInt8]) throws -> [UInt8])?

    func wire_newExternalRemoveProposal(conversationId: ConversationId, epoch: UInt64, keyPackageRef: [UInt8]) throws -> [UInt8] {
        guard let mock = mockNewExternalRemoveProposal else {
            fatalError("no mock for `newExternalRemoveProposal`")
        }

        return try mock(conversationId, epoch, keyPackageRef)
    }

    // MARK: - joinByExternalCommit

    var mockJoinByExternalCommit: ((Bytes) throws -> ConversationInitBundle)?

    func wire_joinByExternalCommit(groupState: [UInt8]) throws -> ConversationInitBundle {
        guard let mock = mockJoinByExternalCommit else {
            fatalError("no mock for `joinByExternalCommit`")
        }

        return try mock(groupState)
    }

    // MARK: - exportGroupState

    var mockExportGroupState: ((ConversationId) throws -> [UInt8])?

    func wire_exportGroupState(conversationId: ConversationId) throws -> [UInt8] {
        guard let mock = mockExportGroupState else {
            fatalError("no mock for `exportGroupState`")
        }

        return try mock(conversationId)
    }

    // MARK: - mergePendingGroupFromExternalCommit

    var mockMergePendingGroupFromExternalCommit: ((ConversationId, ConversationConfiguration) throws -> Void)?

    func wire_mergePendingGroupFromExternalCommit(conversationId: ConversationId, config: ConversationConfiguration) throws {
        guard let mock = mockMergePendingGroupFromExternalCommit else {
            fatalError("no mock for `mergePendingGroupFromExternalCommit`")
        }

        return try mock(conversationId, config)
    }

    // MARK: - clearPendingGroupFromExternalCommit

    var mockClearMergePendingGroupFromExternalCommit: ((ConversationId) throws -> Void)?

    func wire_clearPendingGroupFromExternalCommit(conversationId: WireDataModel.ConversationId) throws {
        guard let mock = mockClearMergePendingGroupFromExternalCommit else {
            fatalError("no mock for `clearPendingGroupFromExternalCommit`")
        }

        return try mock(conversationId)
    }

    // MARK: - exportSecretKey

    var mockExportSecretKey: ((ConversationId, UInt32) throws -> Bytes)?

    func wire_exportSecretKey(conversationId: WireDataModel.ConversationId, keyLength: UInt32) throws -> [UInt8] {
        guard let mock = mockExportSecretKey else {
            fatalError("no mock for `exportSecretKey`")
        }

        return try mock(conversationId, keyLength)
    }

    // MARK: - getClientIds

    var mockGetClientIds: ((ConversationId) throws -> [ClientId])?

    func wire_getClientIds(conversationId: WireDataModel.ConversationId) throws -> [WireDataModel.ClientId] {
        guard let mock = mockGetClientIds else {
            fatalError("no mock for `getClientIds`")
        }

        return try mock(conversationId)
    }

    // MARK: - randomBytes

    var mockRandomBytes: ((UInt32) throws -> [UInt8])?

    func wire_randomBytes(length: UInt32) throws -> [UInt8] {
        guard let mock = mockRandomBytes else {
            fatalError("no mock for `randomBytes`")
        }

        return try mock(length)
    }

    // MARK: - reseedRng

    var mockReseedRng: (([UInt8]) throws -> Void)?

    func wire_reseedRng(seed: [UInt8]) throws {
        guard let mock = mockReseedRng else {
            fatalError("no mock for `reseedRng`")
        }

        return try mock(seed)
    }

    // MARK: - commitAccepted

    var mockCommitAccepted: ((ConversationId) throws -> Void)?

    func wire_commitAccepted(conversationId: ConversationId) throws {
        guard let mock = mockCommitAccepted else {
            fatalError("no mock for `commitAccepted`")
        }

        return try mock(conversationId)
    }

    // MARK: - clearPendingProposal

    var mockClearPendingProposal: ((ConversationId, [UInt8]) throws -> Void)?

    func wire_clearPendingProposal(conversationId: ConversationId, proposalRef: [UInt8]) throws {
        guard let mock = mockClearPendingProposal else {
            fatalError("no mock for `clearPendingProposal`")
        }

        return try mock(conversationId, proposalRef)
    }

    // MARK: - clearPendingCommit

    var mockClearPendingCommit: ((ConversationId) throws -> Void)?

    func wire_clearPendingCommit(conversationId: ConversationId) throws {
        guard let mock = mockClearPendingCommit else {
            fatalError("no mock for `clearPendingCommit`")
        }

        return try mock(conversationId)
    }

    // MARK: - proteusInit

    var mockProteusInit: (() throws -> Void)?

    func wire_proteusInit() throws {
        guard let mock = mockProteusInit else {
            fatalError("no mock for `proteusInit`")
        }

        return try mock()
    }

    // MARK: - proteusSessionFromPrekey

    var mockProteusSessionFromPrekey: ((String, Bytes) throws -> Void)?

    func wire_proteusSessionFromPrekey(sessionId: String, prekey: [UInt8]) throws {
        guard let mock = mockProteusSessionFromPrekey else {
            fatalError("no mock for `proteusSessionFromPrekey`")
        }

        return try mock(sessionId, prekey)
    }

    // MARK: - proteusSessionFromMessage

    var mockProteusSessionFromMessage: ((String, Bytes) throws -> Bytes)?

    func wire_proteusSessionFromMessage(sessionId: String, envelope: [UInt8]) throws -> [UInt8] {
        guard let mock = mockProteusSessionFromMessage else {
            fatalError("no mock for `proteusSessionFromMessage`")
        }

        return try mock(sessionId, envelope)
    }

    // MARK: - proteusSessionSave

    var mockProteusSessionSave: ((String) throws -> Void)?

    func wire_proteusSessionSave(sessionId: String) throws {
        guard let mock = mockProteusSessionSave else {
            fatalError("no mock for `proteusSessionSave`")
        }

        return try mock(sessionId)
    }

    // MARK: - proteusSessionDelete

    var mockProteusSessionDelete: ((String) throws -> Void)?

    func wire_proteusSessionDelete(sessionId: String) throws {
        guard let mock = mockProteusSessionDelete else {
            fatalError("no mock for `proteusSessionDelete`")
        }

        return try mock(sessionId)
    }

    // MARK: - proteusDecrypt

    var mockProteusDecrypt: ((String, Bytes) throws -> Bytes)?

    func wire_proteusDecrypt(sessionId: String, ciphertext: [UInt8]) throws -> [UInt8] {
        guard let mock = mockProteusDecrypt else {
            fatalError("no mock for `proteusDecrypt`")
        }

        return try mock(sessionId, ciphertext)
    }

    // MARK: - proteusEncrypt

    var mockProteusEncrypt: ((String, Bytes) throws -> Bytes)?

    func wire_proteusEncrypt(sessionId: String, plaintext: [UInt8]) throws -> [UInt8] {
        guard let mock = mockProteusEncrypt else {
            fatalError("no mock for `proteusEncrypt`")
        }

        return try mock(sessionId, plaintext)
    }

    // MARK: - proteusEncryptBatched

    var mockProteusEncryptBatched: (([String], Bytes) throws -> [String: Bytes])?

    func wire_proteusEncryptBatched(sessionId: [String], plaintext: [UInt8]) throws -> [String : [UInt8]] {
        guard let mock = mockProteusEncryptBatched else {
            fatalError("no mock for `proteusEncryptBatched`")
        }

        return try mock(sessionId, plaintext)
    }

    // MARK: - proteusNewPrekey

    var mockProteusNewPrekey: ((UInt16) throws -> Bytes)?

    func wire_proteusNewPrekey(prekeyId: UInt16) throws -> [UInt8] {
        guard let mock = mockProteusNewPrekey else {
            fatalError("no mock for `proteusNewPrekey`")
        }

        return try mock(prekeyId)
    }

    // MARK: - proteusFingerprint

    var mockProteusFingerprint: (() throws -> String)?

    func wire_proteusFingerprint() throws -> String {
        guard let mock = mockProteusFingerprint else {
            fatalError("no mock for `proteusFingerprint`")
        }

        return try mock()
    }

    // MARK: - proteusCryptoboxMigrate

    var mockProteusCryptoboxMigrate: ((String) throws -> Void)?

    func wire_proteusCryptoboxMigrate(path: String) throws {
        guard let mock = mockProteusCryptoboxMigrate else {
            fatalError("no mock for `proteusCryptoboxMigrate`")
        }

        return try mock(path)
    }

}

