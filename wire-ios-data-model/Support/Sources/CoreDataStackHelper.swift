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
<<<<<<<< HEAD:wire-ios-data-model/Support/Sources/CoreData/CoreDataStackHelper.swift

public struct CoreDataStackHelper {
========

public struct CoreDataStackHelper {

>>>>>>>> origin/develop:wire-ios-data-model/Support/Sources/CoreDataStackHelper.swift
    private let fileManager = FileManager.default

    public var storageDirectory: URL {
        var path = fileManager.temporaryDirectory
        if #available(iOS 16, *) {
            path.append(path: "CoreDataStackHelper", directoryHint: .isDirectory)
        } else {
            path.appendPathComponent("CoreDataStackHelper", isDirectory: true)
        }
        return path
    }

<<<<<<<< HEAD:wire-ios-data-model/Support/Sources/CoreData/CoreDataStackHelper.swift
    public init() { }
========
    public init() {

    }
>>>>>>>> origin/develop:wire-ios-data-model/Support/Sources/CoreDataStackHelper.swift

    public func createStack() async throws -> CoreDataStack {
        try await createStack(at: storageDirectory)
    }

    @MainActor
    public func createStack(at directory: URL) async throws -> CoreDataStack {
        let account = Account(userName: "", userIdentifier: UUID())

        let stack = CoreDataStack(
            account: account,
            applicationContainer: directory,
            inMemoryStore: true
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

        let files = try fileManager.contentsOfDirectory(
            at: storageDirectory,
            includingPropertiesForKeys: nil,
            options: []
        )

        try files.forEach { try fileManager.removeItem(at: $0) }
    }
}
