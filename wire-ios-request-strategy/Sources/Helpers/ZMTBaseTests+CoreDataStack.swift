//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireTesting

extension ZMTBaseTest {

    var sharedContainerURL: URL {
        FileManager.default.randomCacheURL!

    }

    @objc
    func createCoreDataStack(
        userIdentifier: UUID = UUID(),
        inMemoryStore: Bool = true
    ) async throws -> CoreDataStack {
        let account = Account(userName: "", userIdentifier: userIdentifier)
        let stack = CoreDataStack(
            account: account,
            applicationContainer: sharedContainerURL,
            inMemoryStore: inMemoryStore,
            dispatchGroup: dispatchGroup,
            localDomain: "wire.com",
            isFederationEnabled: false
        )

        try await stack.load()

        return stack
    }

    @objc
    func setupCaches(in coreDataStack: CoreDataStack) async {
        let userImageCache = UserImageLocalCache(location: nil)
        let fileAssetCache = FileAssetCache(location: sharedContainerURL)

        await coreDataStack.viewContext.perform {
            coreDataStack.viewContext.zm_userImageCache = userImageCache
            coreDataStack.viewContext.zm_fileAssetCache = fileAssetCache

        }

        await coreDataStack.syncContext.perform {
            coreDataStack.syncContext.zm_userImageCache = userImageCache
            coreDataStack.syncContext.zm_fileAssetCache = fileAssetCache
        }
    }

    func removeFilesInSharedContainer() {
        try? FileManager.default.contentsOfDirectory(
            at: sharedContainerURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ).forEach {
            try? FileManager.default.removeItem(at: $0)
        }
    }

}
