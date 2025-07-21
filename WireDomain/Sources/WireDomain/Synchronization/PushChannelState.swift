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

/// sourcery: AutoMockable
public protocol PushChannelStateProtocol {
    func isOpen() -> Bool
    func markAsOpen()
    func markAsClosed()
}

struct PushChannelState: PushChannelStateProtocol {
    let fileContext: SafeFileContext
    init(sharedContainerURL: URL, clientID: String) {
        let url = sharedContainerURL.appendingPathComponent(clientID)
        if !FileManager.default.fileExists(atPath: url.path) {
            let created = FileManager.default.createFile(atPath: url.path, contents: Data())
            if !created {
                fatal("could not create file")
            }
        }
        fileContext = SafeFileContext(fileURL: url)
    }
    
    func isOpen() -> Bool {
        return fileContext.isLocked()
    }
    
    func markAsOpen() {
        fileContext.acquireDirectoryLock()
    }
    
    func markAsClosed() {
        fileContext.releaseDirectoryLock()
    }
}
