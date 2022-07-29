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

// Note: This is a temporary workaround the problem that we can't
// link to CoreCrypto from this project. The idea is to copy the public
// interface of CoreCrypto here, link it in the UI project, and inject
// it into this project.

public protocol CoreCryptoProtocol {

    func wire_setCallbacks(callbacks: CoreCryptoCallbacks) throws
    func wire_clientPublicKey() throws -> [UInt8]
    func wire_clientKeypackages(amountRequested: UInt32) throws -> [[UInt8]]
    func wire_createConversation(conversationId: ConversationId, config: ConversationConfiguration) throws
    func wire_conversationExists(conversationId: ConversationId) -> Bool
    func wire_processWelcomeMessage(welcomeMessage: [UInt8]) throws -> ConversationId
    func wire_addClientsToConversation(conversationId: ConversationId, clients: [Invitee]) throws -> MemberAddedMessages?
    func wire_removeClientsFromConversation(conversationId: ConversationId, clients: [ClientId]) throws -> [UInt8]?
    func wire_leaveConversation(conversationId: ConversationId, otherClients: [ClientId]) throws -> ConversationLeaveMessages
    func wire_decryptMessage(conversationId: ConversationId, payload: [UInt8]) throws -> [UInt8]?
    func wire_encryptMessage(conversationId: ConversationId, message: [UInt8]) throws -> [UInt8]
    func wire_newAddProposal(conversationId: ConversationId, keyPackage: [UInt8]) throws -> [UInt8]
    func wire_newUpdateProposal(conversationId: ConversationId) throws -> [UInt8]
    func wire_newRemoveProposal(conversationId: ConversationId, clientId: ClientId) throws -> [UInt8]
    func wire_newExternalAddProposal(conversationId: ConversationId, epoch: UInt64, keyPackage: [UInt8]) throws -> [UInt8]
    func wire_newExternalRemoveProposal(conversationId: ConversationId, epoch: UInt64, keyPackageRef: [UInt8]) throws -> [UInt8]
    func wire_updateKeyingMaterial(conversationId: ConversationId) throws -> CommitBundle
    func wire_joinByExternalCommit(groupState: [UInt8]) throws -> MlsConversationInitMessage
    func wire_exportGroupState(conversationId: ConversationId) throws -> [UInt8]
    func wire_mergePendingGroupFromExternalCommit(conversationId: ConversationId, config: ConversationConfiguration) throws

}

public protocol CoreCryptoCallbacks: AnyObject {

    func authorize(conversationId: [UInt8], clientId: String) -> Bool

}

public struct ConversationConfiguration: Equatable {
    public var admins: [MemberId]
    public var ciphersuite: CiphersuiteName?
    public var keyRotationSpan: TimeInterval?
    public var externalSenders: [[UInt8]]

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(
        admins: [MemberId] = [],
        ciphersuite: CiphersuiteName? = nil,
        keyRotationSpan: TimeInterval? = nil,
        externalSenders: [[UInt8]] = []
    ) {
        self.admins = admins
        self.ciphersuite = ciphersuite
        self.keyRotationSpan = keyRotationSpan
        self.externalSenders = externalSenders
    }
}

public enum CiphersuiteName: Equatable {

    case mls128Dhkemx25519Aes128gcmSha256Ed25519
    case mls128Dhkemp256Aes128gcmSha256P256
    case mls128Dhkemx25519Chacha20poly1305Sha256Ed25519
    case mls256Dhkemx448Aes256gcmSha512Ed448
    case mls256Dhkemp521Aes256gcmSha512P521
    case mls256Dhkemx448Chacha20poly1305Sha512Ed448
    case mls256Dhkemp384Aes256gcmSha384P384

}

public struct MemberAddedMessages {

    public var message: [UInt8]
    public var welcome: [UInt8]

    public init(message: [UInt8], welcome: [UInt8] ) {
        self.message = message
        self.welcome = welcome
    }

}

public struct ConversationLeaveMessages {

    public var selfRemovalProposal: [UInt8]
    public var otherClientsRemovalCommit: [UInt8]?

    public init(selfRemovalProposal: [UInt8], otherClientsRemovalCommit: [UInt8]?) {
        self.selfRemovalProposal = selfRemovalProposal
        self.otherClientsRemovalCommit = otherClientsRemovalCommit
    }

}

public struct Invitee: Equatable {
    public var id: ClientId
    public var kp: [UInt8]

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(id: ClientId, kp: [UInt8]) {
        self.id = id
        self.kp = kp
    }
}

public enum CryptoError: Error {

    // Simple error enums only carry a message
    case ConversationNotFound(message: String)

    // Simple error enums only carry a message
    case ClientNotFound(message: String)

    // Simple error enums only carry a message
    case MalformedIdentifier(message: String)

    // Simple error enums only carry a message
    case ClientSignatureNotFound(message: String)

    // Simple error enums only carry a message
    case ClientSignatureMismatch(message: String)

    // Simple error enums only carry a message
    case LockPoisonError(message: String)

    // Simple error enums only carry a message
    case OutOfKeyPackage(message: String)

    // Simple error enums only carry a message
    case KeyStoreError(message: String)

    // Simple error enums only carry a message
    case MlsError(message: String)

    // Simple error enums only carry a message
    case Utf8Error(message: String)

    // Simple error enums only carry a message
    case StringUtf8Error(message: String)

    // Simple error enums only carry a message
    case ParseIntError(message: String)

    // Simple error enums only carry a message
    case InvalidByteArrayError(message: String)

    // Simple error enums only carry a message
    case IoError(message: String)

    // Simple error enums only carry a message
    case Unauthorized(message: String)

}

public enum CoreCryptoLifecycle {
    /**
     * Initialize the FFI and Rust library. This should be only called once per application.
     */
    func initialize() {

        // No initialization code needed

    }
}

public typealias ConversationId = [UInt8]
public typealias ClientId = [UInt8]
public typealias MemberId = [UInt8]

public struct CommitBundle {
    public var welcome: [UInt8]?
    public var message: [UInt8]

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(welcome: [UInt8]?, message: [UInt8]) {
        self.welcome = welcome
        self.message = message
    }
}

public struct MlsConversationInitMessage {
    public var group: [UInt8]
    public var message: [UInt8]

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(group: [UInt8], message: [UInt8]) {
        self.group = group
        self.message = message
    }
}
