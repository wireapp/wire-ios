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

    // MARK: - finalAddClientsToConversation

    var mockFinalAddClientsToConversation: ((ConversationId, [Invitee]) throws -> TlsCommitBundle)?

    func wire_finalAddClientsToConversation(conversationId: ConversationId, clients: [Invitee]) throws -> TlsCommitBundle {
        guard let mock = mockFinalAddClientsToConversation else {
            fatalError("no mock for `finalAddClientsToConversation`")
        }

        return try mock(conversationId, clients)
    }

    // MARK: - finalRemoveClientsFromConversation

    var mockFinalRemoveClientsFromConversation: ((ConversationId, [ClientId]) throws -> TlsCommitBundle)?

    func wire_finalRemoveClientsFromConversation(conversationId: ConversationId, clients: [ClientId]) throws -> TlsCommitBundle {
        guard let mock = mockFinalRemoveClientsFromConversation else {
            fatalError("no mock for `finalRemoveClientsFromConversation`")
        }

        return try mock(conversationId, clients)
    }

    // MARK: - finalUpdateKeyingMaterial

    var mockFinalUpdateKeyingMaterial: ((ConversationId) throws -> TlsCommitBundle)?

    func wire_finalUpdateKeyingMaterial(conversationId: ConversationId) throws -> TlsCommitBundle {
        guard let mock = mockFinalUpdateKeyingMaterial else {
            fatalError("no mock for `finalUpdateKeyingMaterial`")
        }

        return try mock(conversationId)
    }

    // MARK: - finalCommitPendingProposals

    var mockFinalCommitPendingProposals: ((ConversationId) throws -> TlsCommitBundle)?

    func wire_finalCommitPendingProposals(conversationId: ConversationId) throws -> TlsCommitBundle? {
        guard let mock = mockFinalCommitPendingProposals else {
            fatalError("no mock for `finalCommitPendingProposals`")
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

    var mockJoinByExternalCommit: (([UInt8]) throws -> MlsConversationInitMessage)?

    func wire_joinByExternalCommit(groupState: [UInt8]) throws -> MlsConversationInitMessage {
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

}
