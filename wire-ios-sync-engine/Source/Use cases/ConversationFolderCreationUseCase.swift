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

import WireDataModel

// MARK: - ConversationFolderCreationUseCaseProtocol

public protocol ConversationFolderCreationUseCaseProtocol {
    /// Creates a new conversation folder with the specified name
    /// - Parameter name: The name of the folder to be created
    /// - Returns: The created `LabelType`, or `nil` if creation fails
    func invoke(with name: String) async -> LabelType?
}

// MARK: - ConversationFolderCreationUseCase

public struct ConversationFolderCreationUseCase: ConversationFolderCreationUseCaseProtocol {

    // MARK: - Properties

    private let managedObjectContext: NSManagedObjectContext

    // MARK: - Initialization

    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    // MARK: - Public Interface

    public func invoke(with name: String) async -> LabelType? {
        await managedObjectContext.perform {
            var created = false
            let label = Label.fetchOrCreate(
                remoteIdentifier: UUID(),
                create: true,
                in: managedObjectContext,
                created: &created
            )
            label?.name = name
            label?.kind = .folder
            return label

        }
    }
}
