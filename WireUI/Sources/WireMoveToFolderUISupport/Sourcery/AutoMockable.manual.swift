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
@testable import WireMoveToFolderUI

public class MockFolderDirectoryTypeProtocol: FolderDirectoryTypeProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - allFolders

    public var allFolders: [Folder] = []
}

public class MockMoveConversationToFolderUseCaseType: @unchecked Sendable, MoveConversationToFolderUseCaseType {

    // MARK: - Life cycle

    public init() {}

    // MARK: - invoke

    public var invokeFolderConversation_Invocations: [(folder: Folder, conversation: Conversation)] = []
    public var invokeFolderConversation_MockError: (any Error)?
    public var invokeFolderConversation_MockMethod: ((Folder, Conversation) async throws -> Void)?

    public func invoke(folder: Folder, conversation: Conversation) async throws {
        invokeFolderConversation_Invocations.append((folder: folder, conversation: conversation))

        if let error = invokeFolderConversation_MockError {
            throw error
        }

        guard let mock = invokeFolderConversation_MockMethod else {
            fatalError("no mock for `invokeFolderConversation`")
        }

        try await mock(folder, conversation)
    }
}

