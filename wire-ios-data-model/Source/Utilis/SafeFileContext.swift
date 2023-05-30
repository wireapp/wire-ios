//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

private let zmLog = ZMSLog(tag: "safeFileContext")

/// Provides safe access to a file with lock mechanism
public final class SafeFileContext: NSObject {

    let fileURL: URL
    fileprivate var fileDescriptor: CInt!

    public init(fileURL: URL) {
        self.fileURL = fileURL
        super.init()

        self.fileDescriptor = open(self.fileURL.path, 0)
        if self.fileDescriptor <= 0 {
            fatal("Can't obtain FileDescriptor for \(self.fileURL)")
        }
    }

    deinit {
        // unlock
        self.releaseDirectoryLock()
        // close
        close(self.fileDescriptor)
        zmLog.debug("Closed fileDescriptor at path: \(fileURL)")
    }

}

public extension SafeFileContext {

    func acquireDirectoryLock() {
        if flock(self.fileDescriptor, LOCK_EX) != 0 {
            fatal("Failed to lock \(self.fileURL)")
        }
        zmLog.debug("Acquired lock at path: \(self.fileURL)")
    }

    func releaseDirectoryLock() {
        if flock(self.fileDescriptor, LOCK_UN) != 0 {
            fatal("Failed to unlock \(self.fileURL)")
        }
        zmLog.debug("Released lock at path: \(self.fileURL)")
    }
}
