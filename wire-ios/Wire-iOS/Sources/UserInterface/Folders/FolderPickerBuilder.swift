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

import SwiftUI
import UIKit
import WireCommonComponents
import WireDataModel
import WireMoveToFolderUI
import WireSyncEngine

struct FolderPickerBuilder {
    @MainActor
    func build(
        conversation: ZMConversation,
        directory: ConversationDirectoryType,
        useCase: UpdateConversationFolderUseCase,
        context: NSManagedObjectContext
    ) -> UIViewController {
        let directoryMapper = WireFolderDirectoryMapper(directory: directory)
        let useCase = UpdateConversationFolderUseCase(context: context)

        let createConversationFolderUseCase = CreateConversationFolderUseCase(context: context)
        let conversationName = conversation.displayName ?? conversation.displayNameWithFallback

        let viewModel = FolderPickerViewModel(
            conversation: Conversation(conversation),
            directory: directoryMapper,
            updateConversationFolderUseCase: useCase,
            createFolderUseCase: createConversationFolderUseCase
        )

        return FolderPickerHostingController(
            viewModel: viewModel,
            createFolderUseCase: createConversationFolderUseCase,
            isContextMenuAllowed: SecurityFlags.clipboard.isEnabled,
            conversationName: conversationName
        )
    }
}
