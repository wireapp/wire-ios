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
@testable import WireMoveToFolderUI

public class MockFolderDirectoryTypeProtocol: FolderDirectoryTypeProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - allFolders

    public var allFolders: [Folder] = []
}

public class MockUpdateConversationFolderUseCase: @unchecked Sendable, UpdateConversationFolderUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - invoke

    public var invoke_Invocations: [(conversationID: UUID, folderID: UUID)] = []
    public var invoke_MockError: (any Error)?
    public var invoke_MockMethod: ((UUID, UUID) async throws -> Void)?

    public func invoke(conversationID: UUID, folderID: UUID) async throws {
        invoke_Invocations.append((conversationID: conversationID, folderID: folderID))

        if let error = invoke_MockError {
            throw error
        }

        guard let mock = invoke_MockMethod else {
            fatalError("no mock for `invoke`")
        }

        try await mock(conversationID, folderID)
    }
}

public class MockCreateConversationFolderUseCase: @unchecked Sendable, CreateConversationFolderUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - invoke

    public var invokeName_Invocations: [String] = []
    public var invokeName_MockError: (any Error)?
    public var invokeName_MockMethod: ((String) async throws -> Folder)?

    public func invoke(name: String) async throws -> Folder {
        invokeName_Invocations.append(name)

        if let error = invokeName_MockError {
            throw error
        }

        guard let mock = invokeName_MockMethod else {
            fatalError("no mock for `invokeName`")
        }

        return try await mock(name)
    }
}
