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

        var setCallBacksCallCount = 0
        var clientKeypackages = [UInt32]()
        var createConversation = [(ConversationId, ConversationConfiguration)]()
        var conversationExists = [ConversationId]()
        var processWelcomeMessage = [[UInt8]]()
        var addClientsToConversation = [(ConversationId, [Invitee])]()
        var removeClientsFromConversation = [(ConversationId, [ClientId])]()
        var leaveConversation = [(ConversationId, [ClientId])]()
        var decryptMessage = [(ConversationId, [UInt8])]()
        var encryptMessage = [(ConversationId, [UInt8])]()
        var newAddProposal = [(ConversationId, [UInt8])]()
        var newUpdateProposal = [ConversationId]()
        var newRemoveProposal = [(ConversationId, ClientId)]()
        var newExternalAddProposal = [(ConversationId, UInt64, [UInt8])]()
        var newExternalRemoveProposal = [(ConversationId, UInt64, [UInt8])]()
        var updateKeyingMaterial = [ConversationId]()
        var joinByExternalCommit = [[UInt8]]()
        var exportGroupState = [ConversationId]()
        var mergePendingGroupFromExternalCommit = [(ConversationId, ConversationConfiguration)]()

    }

    // MARK: - Properties

    var calls = Calls()

    // MARK: - Methods

    func wire_setCallbacks(callbacks: CoreCryptoCallbacks) throws {
        calls.setCallBacksCallCount += 1
    }

    var mockClientPublicKey: [UInt8]?

    func wire_clientPublicKey() throws -> [UInt8] {
        return try XCTUnwrap(mockClientPublicKey, "return value not mocked")
    }

    var mockClientKeyPackages: [[UInt8]]?

    func wire_clientKeypackages(amountRequested: UInt32) throws -> [[UInt8]] {
        calls.clientKeypackages.append(amountRequested)
        return try XCTUnwrap(mockClientKeyPackages, "return value not mocked")
    }

    func wire_createConversation(conversationId: ConversationId, config: ConversationConfiguration) throws {
        calls.createConversation.append((conversationId, config))
    }

    var mockConversationExists: Bool?

    func wire_conversationExists(conversationId: ConversationId) -> Bool {
        calls.conversationExists.append(conversationId)
        return mockConversationExists ?? false
    }

    var mockProcessWelcomeMessage: ConversationId?

    func wire_processWelcomeMessage(welcomeMessage: [UInt8]) throws -> ConversationId {
        calls.processWelcomeMessage.append(welcomeMessage)
        return try XCTUnwrap(mockProcessWelcomeMessage, "return value not mocked")
    }

    var mockAddClientsToConversation: MemberAddedMessages??

    func wire_addClientsToConversation(conversationId: ConversationId, clients: [Invitee]) throws -> MemberAddedMessages? {
        calls.addClientsToConversation.append((conversationId, clients))
        return try XCTUnwrap(mockAddClientsToConversation, "return value not mocked")
    }

    var mockRemoveClientsFromConversation: [UInt8]??

    func wire_removeClientsFromConversation(conversationId: ConversationId, clients: [ClientId]) throws -> [UInt8]? {
        calls.removeClientsFromConversation.append((conversationId, clients))
        return try XCTUnwrap(mockRemoveClientsFromConversation, "return value not mocked")
    }

    var mockLeaveConversation: ConversationLeaveMessages?

    func wire_leaveConversation(conversationId: ConversationId, otherClients: [ClientId]) throws -> ConversationLeaveMessages {
        calls.leaveConversation.append((conversationId, otherClients))
        return try XCTUnwrap(mockLeaveConversation, "return value not mocked")
    }

    var mockDecryptMessage: [UInt8]??

    func wire_decryptMessage(conversationId: ConversationId, payload: [UInt8]) throws -> [UInt8]? {
        calls.decryptMessage.append((conversationId, payload))
        return try XCTUnwrap(mockDecryptMessage, "return value not mocked")
    }

    var mockEncryptMessage: [UInt8]?

    func wire_encryptMessage(conversationId: ConversationId, message: [UInt8]) throws -> [UInt8] {
        calls.encryptMessage.append((conversationId, message))
        return try XCTUnwrap(mockEncryptMessage, "return value not mocked")
    }

    var mockNewAddProposal: [UInt8]?

    func wire_newAddProposal(conversationId: ConversationId, keyPackage: [UInt8]) throws -> [UInt8] {
        calls.newAddProposal.append((conversationId, keyPackage))
        return try XCTUnwrap(mockNewAddProposal, "return value not mocked")
    }

    var mockNewUpdateProposal: [UInt8]?

    func wire_newUpdateProposal(conversationId: ConversationId) throws -> [UInt8] {
        calls.newUpdateProposal.append(conversationId)
        return try XCTUnwrap(mockNewUpdateProposal, "return value not mocked")
    }

    var mockNewRemoveProposal: [UInt8]?

    func wire_newRemoveProposal(conversationId: ConversationId, clientId: ClientId) throws -> [UInt8] {
        calls.newRemoveProposal.append((conversationId, clientId))
        return try XCTUnwrap(mockNewRemoveProposal, "return value not mocked")
    }

    var mockNewExternalAddProposal: [UInt8]?

    func wire_newExternalAddProposal(conversationId: ConversationId, epoch: UInt64, keyPackage: [UInt8]) throws -> [UInt8] {
        calls.newExternalAddProposal.append((conversationId, epoch, keyPackage))
        return try XCTUnwrap(mockNewExternalAddProposal, "return value not mocked")
    }

    var mockNewExternalRemoveProposal: [UInt8]?

    func wire_newExternalRemoveProposal(conversationId: ConversationId, epoch: UInt64, keyPackageRef: [UInt8]) throws -> [UInt8] {
        calls.newExternalRemoveProposal.append((conversationId, epoch, keyPackageRef))
        return try XCTUnwrap(mockNewExternalRemoveProposal, "return value not mocked")
    }

    var mockUpdateKeyingMaterial: CommitBundle?

    func wire_updateKeyingMaterial(conversationId: ConversationId) throws -> CommitBundle {
        calls.updateKeyingMaterial.append(conversationId)
        return try XCTUnwrap(mockUpdateKeyingMaterial, "return value not mocked")
    }

    var mockJoinByExternalCommit: MlsConversationInitMessage?

    func wire_joinByExternalCommit(groupState: [UInt8]) throws -> MlsConversationInitMessage {
        calls.joinByExternalCommit.append(groupState)
        return try XCTUnwrap(mockJoinByExternalCommit, "return value not mocked")
    }

    var mockExportGroupState: [UInt8]?

    func wire_exportGroupState(conversationId: ConversationId) throws -> [UInt8] {
        calls.exportGroupState.append(conversationId)
        return try XCTUnwrap(mockExportGroupState, "return value not mocked")
    }

    func wire_mergePendingGroupFromExternalCommit(conversationId: ConversationId, config: ConversationConfiguration) throws {
        calls.mergePendingGroupFromExternalCommit.append((conversationId, config))
    }

}
