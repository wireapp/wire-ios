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

import Foundation

// MARK: - ProteusError

public enum ProteusError: Int, Error, Equatable {
    /// An internal storage error occurred.
    ///
    /// An error occurred while loading or peristing key material. The
    /// operation may be retried a limited number of times.

    case storageError = 1

    /// A requested session was not found.

    case sessionNotFound = 2

    /// A message or key could not be decoded.
    ///
    /// The message or key being decoded is either malformed or otherwise
    /// encoded in a way such that it cannot be understood.

    case decodeError = 3

    /// The remote identity of a session changed.
    ///
    /// Usually the user should be informed and the session reinitialised.
    /// If the remote fingerprint was previously verified, it will need to be
    /// verified anew in order to exclude any potential MITM.

    case remoteIdentityChanged = 4

    /// The signature of a decrypted message is invalid.
    ///
    /// The message being decrypted is incomplete or has otherwise been tampered with.

    case invalidSignature = 5

    /// A message is invalid.
    ///
    /// The message is well-formed but cannot be decrypted, e.g.
    /// because the message is used to initialise a session but does not
    /// contain a [PreKey] or the used session does not contain the
    /// appropriate key material for decrypting the message. The problem
    /// should be reported to the user, as it might be necessary for both
    /// peers to re-initialise their sessions.

    case invalidMessage = 6

    /// A message is a duplicate.
    ///
    /// The message being decrypted is a duplicate of a message that has
    /// previously been decrypted with the same session. The message can
    /// be safely discarded.

    case duplicateMessage = 7

    /// A message is too recent.
    ///
    /// There is an unreasonably large gap between the last decrypted message
    /// and the message being decrypted, i.e. there are too many intermediate
    /// messages missing. The message should be dropped.

    case tooDistantFuture = 8

    /// A message is too old.
    ///
    /// The message being decrypted is unreasonably old and cannot be decrypted
    /// any longer due to the key material no longer being available. The message
    /// should be dropped.

    case outdatedMessage = 9

    /// A CBox has been opened with an incomplete or mismatching identity using
    /// 'CryptoBox.openWith'.

    case identityError = 13

    /// An attempt was made to initialise a new session using
    /// `CryptoBox.initSessionFromMessage'` whereby the prekey corresponding to
    /// the prekey ID in the message could not be found.

    case prekeyNotFound = 14

    /// A panic occurred. This is the last resort error raised from native code
    /// to signal a severe problem, like a violation of a critical invariant,
    /// that would otherwise have caused a crash. Client code can choose to handle
    /// these errors more gracefully, preventing the application from crashing.
    ///
    /// Note that any `CryptoSession`s which might have been involved in a
    /// computation leading to a panic must no longer be used as their in-memory
    /// state may be corrupt. Such sessions should be closed and may be subsequently
    /// reloaded to retry the operation(s).

    case panic = 15

    /// An unspecified error occurred.

    case unknown = 999

    // MARK: Lifecycle

    /// Initialise from a proteus code.
    /// See: https://github.com/wireapp/proteus/blob/2.x/crates/proteus-traits/src/lib.rs

    init(proteusCode: UInt32) {
        switch proteusCode {
        case 501:
            self = .storageError

        case 102:
            self = .sessionNotFound

        case 3,
             301,
             302,
             303:
            self = .decodeError

        case 204:
            self = .remoteIdentityChanged

        case 206,
             207,
             210:
            self = .invalidSignature

        case 200,
             201,
             202,
             205,
             213:
            self = .invalidMessage

        case 209:
            self = .duplicateMessage

        case 211,
             212:
            self = .tooDistantFuture

        case 208:
            self = .outdatedMessage

        case 300:
            self = .identityError

        case 101:
            self = .prekeyNotFound

        case 5:
            self = .panic

        default:
            self = .unknown
        }
    }
}

// MARK: SafeForLoggingStringConvertible

extension ProteusError: SafeForLoggingStringConvertible {
    public var safeForLoggingDescription: String {
        String(describing: self)
    }
}
