// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

class _CBox : PointerWrapper {}



/**
 A cryptobox context that manages access to sessions, allowing the
 same sessions to be accessed by multuple processes in a safe way.
 Inside a process, only a single session context should be used.
 
 - note:
 In order to be used by multiple processes (see iOS extensions), cryptobox needs to lock the 
 directory with the key material as it works on it, so that no other process will touch it.
 
 This class introduces the concept of *encryption context*, similar to the concept of context in Core Data.
 A context must be used only from a single thread. Multiple contexts can refer to the same 
 directory on disk, locking the directory when needed so that they don't interfere with 
 each other.
 
 Conflicts and race conditions are avoided by loading from disk and saving to disk 
 every time a context it used, and locking around these operations. 
 This is slow, but extensions are not supposed to need to access 
 cryptobox very frequently.
 
 The intended use of this class is:
 
 1. Create context once, reuse the same context to avoid having to create/load identity 
    (which never changes once created, so no race condition other than during creation)
 2. use `perform:` with a block to create sessions, prekeys, encrypt and decrypt. 
    During the execution of the block, the directory is locked. 
    When decrypting, the decrypted data should be saved synchronously inside this block
    (e.g. in case of Core Data, should be inserted and immediately saved) to enforce it
    being saved before the session state is persisted later.
    If the decrypted data is not persisted, and there is a crash before the data is
    persisted, the data is lost forever as it can not be decrypted again once the session 
    is saved.
 3. When the block passed to `perform:` is completed, the sessions are persisted to disk.
    The lock is relased.
 */
public class EncryptionContext : NSObject {
    
    /// What to do with modified sessions
    public enum ModifiedSessionsBehaviour {
        case Save
        case Discard
    }
    
    /// Underlying C-style implementation
    let implementation = _CBox()
    
    /// File directory with the implementation files
    private let path : NSURL
    
    /// The latest created and still open session directory
    /// will be set to `nil` after calling `doneUsingSessions`
    private(set) var currentSessionsDirectory: EncryptionSessionsDirectory?
    
    /// Folder file descriptor
    private var fileDescriptor : CInt!
    
    
    private var performCount : UInt = 0
    
    /// Opens cryptobox from a given folder
    /// - throws: CryptoBox error in case of lower-level error
    public init(path: NSURL) {
        let result = cbox_file_open((path.path! as NSString).UTF8String, &self.implementation.ptr)
        self.path = path
        super.init()
        if result != CBOX_SUCCESS {
            fatalError("Failed to open cryptobox: ERROR \(result.rawValue)")
        }
        self.fileDescriptor = open(self.path.path!, 0)
        if self.fileDescriptor <= 0 {
            fatalError("Can't obtain FD for folder \(self.path)")
        }
    }
    
    deinit {
        // unlock
        self.releaseDirectoryLock()
        // close
        close(self.fileDescriptor)
        // close cbox
        cbox_close(implementation.ptr)
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
    public func perform(block: (sessionsDirectory: EncryptionSessionsDirectory) -> () ) {
        self.acquireDirectoryLock()
        if self.currentSessionsDirectory == nil {
            self.currentSessionsDirectory = EncryptionSessionsDirectory(generatingContext: self)
        }
        performCount += 1
        block(sessionsDirectory: self.currentSessionsDirectory!)
        performCount -= 1
        if 0 == performCount {
            self.currentSessionsDirectory = nil
        }
        self.releaseDirectoryLock()
    }
    
    private func acquireDirectoryLock() {
        if flock(self.fileDescriptor, LOCK_EX) != 0 {
            fatalError("Failed to lock \(self.path)")
        }
    }
    
    private func releaseDirectoryLock() {
        if flock(self.fileDescriptor, LOCK_UN) != 0 {
            fatalError("Failed to unlock \(self.path)")
        }
    }
}

