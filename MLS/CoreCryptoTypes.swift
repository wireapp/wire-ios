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
    func wire_createConversation(conversationId: [UInt8], config: ConversationConfiguration) throws -> MemberAddedMessages?
    func wire_conversationExists(conversationId: [UInt8]) -> Bool
    func wire_processWelcomeMessage(welcomeMessage: [UInt8]) throws -> [UInt8]
    func wire_addClientsToConversation(conversationId: [UInt8], clients: [Invitee]) throws -> MemberAddedMessages?
    func wire_removeClientsFromConversation(conversationId: [UInt8], clients: [[UInt8]]) throws -> [UInt8]?
    func wire_leaveConversation(conversationId: [UInt8], otherClients: [[UInt8]]) throws -> ConversationLeaveMessages
    func wire_decryptMessage(conversationId: [UInt8], payload: [UInt8]) throws -> [UInt8]?
    func wire_encryptMessage(conversationId: [UInt8], message: [UInt8]) throws -> [UInt8]
    func wire_newAddProposal(conversationId: [UInt8], keyPackage: [UInt8]) throws -> [UInt8]
    func wire_newUpdateProposal(conversationId: [UInt8]) throws -> [UInt8]
    func wire_newRemoveProposal(conversationId: [UInt8], clientId: [UInt8]) throws -> [UInt8]

}

public protocol CoreCryptoCallbacks: AnyObject {

    func authorize(conversationId: [UInt8], clientId: String) -> Bool

}

public struct ConversationConfiguration {

    public var extraMembers: [Invitee]
    public var admins: [[UInt8]]
    public var ciphersuite: CiphersuiteName?
    public var keyRotationSpan: TimeInterval?

    public init(extraMembers: [Invitee], admins: [[UInt8]], ciphersuite: CiphersuiteName?, keyRotationSpan: TimeInterval? ) {
        self.extraMembers = extraMembers
        self.admins = admins
        self.ciphersuite = ciphersuite
        self.keyRotationSpan = keyRotationSpan
    }

}

public enum CiphersuiteName {

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

public struct Invitee {

    public var id: [UInt8]
    public var kp: [UInt8]

    public init(id: [UInt8], kp: [UInt8]) {
        self.id = id
        self.kp = kp
    }

}

public enum CryptoError {

    case ConversationNotFound(message: String)
    case ClientNotFound(message: String)
    case MalformedIdentifier(message: String)
    case KeyStoreError(message: String)
    case ClientSignatureNotFound(message: String)
    case OutOfKeyPackage(message: String)
    case LockPoisonError(message: String)
    case ConversationConfigurationError(message: String)
    case MlsError(message: String)
    case UuidError(message: String)
    case Utf8Error(message: String)
    case StringUtf8Error(message: String)
    case ParseIntError(message: String)
    case IoError(message: String)
    case Unauthorized(message: String)
    case Other(message: String)

}


public enum CoreCryptoLifecycle {
    /**
     * Initialize the FFI and Rust library. This should be only called once per application.
     */
    func initialize() {

        // No initialization code needed

    }
}
