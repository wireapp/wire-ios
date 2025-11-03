//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireDataModel
import WireLegacyLogging

/// sourcery: AutoMockable
public protocol PushChannelStateProtocol {

    func markAsOpen() async throws
    func markAsClosed() async
}

struct PushChannelState: PushChannelStateProtocol {
    enum Failure: Error, Equatable {
        case alreadyLocked(sameProcess: Bool)
    }

    /// The file context only prevents other processes to get the lock
    /// same process will succeed, so we need an extra state
    private static let processLock = ProcessLock()

    let fileContext: SafeFileContext
    init(sharedContainerURL: URL, clientID: String) {
        let url = sharedContainerURL.appendingPathComponent(clientID)
        if !FileManager.default.fileExists(atPath: url.path) {
            let created = FileManager.default.createFile(atPath: url.path, contents: Data())
            if !created {
                fatal("could not create file")
            }
        }
        self.fileContext = SafeFileContext(fileURL: url)
    }

    func markAsOpen() async throws {

        if await Self.processLock.isLocked {
            throw Failure.alreadyLocked(sameProcess: true)
        }

        if !fileContext.tryAcquireLock() {
            throw Failure.alreadyLocked(sameProcess: false)
        }
        await Self.processLock.lock()
        WireLogger.pushChannel.debug("pushChannel marked as opened")
    }

    func markAsClosed() async {
        fileContext.releaseDirectoryLock()
        await Self.processLock.unlock()
        WireLogger.pushChannel.debug("pushChannel marked as closed")
    }
}

private actor ProcessLock {
    private(set) var isLocked: Bool = false

    func lock() async {
        isLocked = true
    }

    func unlock() async {
        isLocked = false
    }
}
