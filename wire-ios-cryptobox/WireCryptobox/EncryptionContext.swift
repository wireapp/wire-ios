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
import WireSystem

// MARK: - _CBox

class _CBox: PointerWrapper {}

// MARK: - EncryptionContext

/// A cryptobox context that manages access to sessions, allowing the
/// same sessions to be accessed by multuple processes in a safe way.
/// Inside a process, only a single session context should be used.
///
/// - note:
/// In order to be used by multiple processes (see iOS extensions), cryptobox needs to lock the
/// directory with the key material as it works on it, so that no other process will touch it.
///
/// This class introduces the concept of *encryption context*, similar to the concept of context in Core Data.
/// A context must be used only from a single thread. Multiple contexts can refer to the same
/// directory on disk, locking the directory when needed so that they don't interfere with
/// each other.
///
/// Conflicts and race conditions are avoided by loading from disk and saving to disk
/// every time a context it used, and locking around these operations.
/// This is slow, but extensions are not supposed to need to access
/// cryptobox very frequently.
///
/// The intended use of this class is:
///
/// 1. Create context once, reuse the same context to avoid having to create/load identity
///   (which never changes once created, so no race condition other than during creation)
/// 2. use `perform:` with a block to create sessions, prekeys, encrypt and decrypt.
///   During the execution of the block, the directory is locked.
///   When decrypting, the decrypted data should be saved synchronously inside this block
///   (e.g. in case of Core Data, should be inserted and immediately saved) to enforce it
///   being saved before the session state is persisted later.
///   If the decrypted data is not persisted, and there is a crash before the data is
///   persisted, the data is lost forever as it can not be decrypted again once the session
///   is saved.
/// 3. When the block passed to `perform:` is completed, the sessions are persisted to disk.
///   The lock is relased.
public final class EncryptionContext: NSObject {
    /// What to do with modified sessions
    public enum ModifiedSessionsBehaviour {
        case save
        case discard
    }

    /// Set of session identifier that require full debugging logs
    private var extensiveLoggingSessions = Set<EncryptionSessionIdentifier>()

    /// Underlying C-style implementation
    let implementation = _CBox()

    /// File directory with the implementation files
    let path: URL

    /// The latest created and still open session directory
    /// will be set to `nil` after calling `doneUsingSessions`
    fileprivate(set) var currentSessionsDirectory: EncryptionSessionsDirectory?

    /// Folder file descriptor
    fileprivate var fileDescriptor: CInt!

    /// Keeps track of how many times we enter a `perform` block,
    /// to allow re-entry
    fileprivate var performCount: UInt = 0

    // The maximum size of the end-to-end encrypted payload is defined by ZMClientMessageByteSizeExternalThreshold
    // It's currently 128KB of data. NOTE that this cache is shared between all sessions in an encryption context.
    fileprivate let cache = Cache<GenericHash, Data>(maxCost: 10_000_000, maxElementsCount: 100_000)

    /// Opens cryptobox from a given folder
    /// - throws: CryptoBox error in case of lower-level error
    public init(path: URL) {
        let result = cbox_file_open((path.path as NSString).utf8String, &implementation.ptr)
        self.path = path
        super.init()
        if result != CBOX_SUCCESS {
            fatal("Failed to open cryptobox: ERROR \(result.rawValue)")
        }
        self.fileDescriptor = open(self.path.path, 0)
        if fileDescriptor <= 0 {
            fatal("Can't obtain FD for folder \(self.path)")
        }
        zmLog.debug("Opened cryptobox at path: \(path)")
    }

    deinit {
        // unlock
        self.releaseDirectoryLock()
        // close
        close(self.fileDescriptor)
        // close cbox
        cbox_close(implementation.ptr)
        zmLog.debug("Closed cryptobox at path: \(path)")
    }
}

// MARK: - Start and stop using sessions

extension EncryptionContext {
    /// Access sessions and other data in this context. While the block is executed,
    /// no other process can use sessions from this context. If another process or thread is already
    /// using sessions from a context with the same path, this call will block until the other process
    /// stops using sessions. Nested calls to this method on the same objects on the same
    /// thread are allowed.
    /// - warning: this method is not thread safe
    public func perform(_ block: (_ sessionsDirectory: EncryptionSessionsDirectory) -> Void) {
        acquireDirectoryLock()
        if currentSessionsDirectory == nil {
            currentSessionsDirectory =
                EncryptionSessionsDirectory(
                    generatingContext: self,
                    encryptionPayloadCache: cache,
                    extensiveLoggingSessions: extensiveLoggingSessions
                )
        }
        performCount += 1
        block(currentSessionsDirectory!)
        performCount -= 1
        if performCount == 0 {
            currentSessionsDirectory = nil
        }
        releaseDirectoryLock()
    }

    // swiftlint:disable:next todo_requires_jira_link
    // TODO: can this be removed?
    public func performAsync(_ block: (_ sessionsDirectory: EncryptionSessionsDirectory) async -> Void) async {
        acquireDirectoryLock()
        if currentSessionsDirectory == nil {
            currentSessionsDirectory =
                EncryptionSessionsDirectory(
                    generatingContext: self,
                    encryptionPayloadCache: cache,
                    extensiveLoggingSessions: extensiveLoggingSessions
                )
        }
        performCount += 1
        await block(currentSessionsDirectory!)
        performCount -= 1
        if performCount == 0 {
            currentSessionsDirectory = nil
        }
        releaseDirectoryLock()
    }

    private func acquireDirectoryLock() {
        if flock(fileDescriptor, LOCK_EX) != 0 {
            fatal("Failed to lock \(path)")
        }
    }

    private func releaseDirectoryLock() {
        if flock(fileDescriptor, LOCK_UN) != 0 {
            fatal("Failed to unlock \(path)")
        }
    }
}

extension EncryptionContext {
    /// Enables or disables extended logging for any message encrypted from or to
    /// a specific session.
    /// note: if the session is already cached in memory, this will apply from the
    /// next time the session is reloaded
    public func setExtendedLogging(identifier: EncryptionSessionIdentifier, enabled: Bool) {
        if enabled {
            extensiveLoggingSessions.insert(identifier)
        } else {
            extensiveLoggingSessions.remove(identifier)
        }
    }

    /// Disable extensive logging on all sessions
    public func disableExtendedLoggingOnAllSessions() {
        extensiveLoggingSessions.removeAll()
    }
}
