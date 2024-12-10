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
import WireDataModel

public struct CoreDataStackHelper {

    private let fileManager = FileManager.default

    public var storageDirectory: URL {
        var path = fileManager.temporaryDirectory
        path.append(path: uniquePath, directoryHint: .isDirectory)
        return path
    }

    var uniquePath: String

    public init() {
        self.uniquePath = UUID().uuidString
    }

    public func createStack(inMemoryStore: Bool = true) async throws -> CoreDataStack {
        try await createStack(at: storageDirectory, inMemoryStore: inMemoryStore)
    }

    @MainActor
    public func createStack(at directory: URL, inMemoryStore: Bool = true) async throws -> CoreDataStack {
        let account = Account(userName: "", userIdentifier: UUID())

        let stack = CoreDataStack(
            account: account,
            applicationContainer: directory,
            inMemoryStore: inMemoryStore
        )

        return try await withCheckedThrowingContinuation { continuation in
            stack.loadStores { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: stack)
                }
            }
        }
    }

    public func cleanupDirectory() throws {
        try cleanupDirectory(storageDirectory)
    }

    public func cleanupDirectory(_ url: URL) throws {
        guard storageDirectory.hasDirectoryPath else {
            assertionFailure("url is not a directory path!")
            return
        }

        guard fileManager.fileExists(atPath: storageDirectory.path) else {
            return
        }

        try fileManager.removeItem(atPath: storageDirectory.path)
    }
}
