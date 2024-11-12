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
import WireMoveToFolderUI
import WireSyncEngine

/// A mapper that bridges the UI layer's move-to-folder operation with the core domain layer.
/// It translates between the UI's representation of folders/conversations and the core domain model's representation.
///
/// This type implements the adapter pattern to:
/// - Convert UI-layer folder/conversation models to domain models
/// - Handle the actual movement of conversations between folders using the core domain useCase
/// - Provide error handling for failed conversions
///
/// Example usage:
/// ```
/// let mapper = WireMoveConversationToFolderUseCaseMapper(...)
/// try await mapper.invoke(folder: uiFolder, conversation: uiConversation)
/// ```
public struct WireMoveConversationToFolderUseCaseMapper: MoveConversationToFolderUseCaseType {

    private let useCase: ConversationFolderSelectionUseCase
    private let directory: ConversationDirectoryType
    private let targetConversation: ZMConversation
    private let context: NSManagedObjectContext

    /// Initializes the mapper with required dependencies
    /// - Parameters:
    ///   - useCase: The core domain use case that handles the actual folder selection logic
    ///   - directory: Provides access to all available folders in the system
    ///   - conversation: The conversation to be moved (in domain model form)
    ///   - context: The managed object context for performing Core Data operations
    public init(
        useCase: ConversationFolderSelectionUseCase,
        directory: ConversationDirectoryType,
        conversation: ZMConversation,
        context: NSManagedObjectContext
    ) {
        self.useCase = useCase
        self.directory = directory
        self.targetConversation = conversation
        self.context = context
    }

    /// Moves a conversation to a specified folder
    /// - Parameters:
    ///   - folder: The destination folder (in UI model form)
    ///   - conversation: The conversation to be moved (in UI model form)
    /// - Throws: FolderError.conversionFailed if the UI folder cannot be mapped to a domain folder
    public func invoke(folder: Folder, conversation: WireMoveToFolderUI.Conversation) async throws {
        try await context.perform {
            guard let wireFolder = directory.allFolders.first(where: { $0.remoteIdentifier == folder.identifier }) else {
                throw FolderError.conversionFailed
            }
            useCase.invoke(folder: wireFolder, conversation: targetConversation)
        }
    }

    private enum FolderError: Error {
        /// Thrown when a UI folder model cannot be converted to a domain folder model
        case conversionFailed
    }
}
