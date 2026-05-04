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
import WireDataModel
import WireFolderPickerUI

struct FolderPickerViewControllerBuilder {
    private let conversationDirectory: ConversationDirectoryType
    private let conversationFilter: () -> ConversationFilter?

    init(conversationDirectory: ConversationDirectoryType, conversationFilter: @escaping () -> ConversationFilter?) {
        self.conversationDirectory = conversationDirectory
        self.conversationFilter = conversationFilter
    }

    @MainActor
    func build(mainCoordinator: AnyMainCoordinator, showCloseButton: Bool) -> UIViewController {
        let folders: [FolderPickerOption] = conversationDirectory.nonDeletedFolders.compactMap {
            guard let id = $0.remoteIdentifier, let title = $0.name else { return nil }

            return FolderPickerOption(id: id, title: title)
        }

        let selected = Binding<FolderPickerOption?>(
            get: { [conversationFilter] in
                conversationFilter()?.folderData.map { FolderPickerOption(id: $0.id, title: $0.name) }
            },
            set: { option, _ in
                Task {
                    if let option {
                        await mainCoordinator.showConversationList(
                            conversationFilter: .folder(id: option.id, name: option.title)
                        )
                    }
                }
            }
        )

        let navigationStack = NavigationStack {
            FolderPicker(
                showCloseButton: showCloseButton,
                options: folders,
                helpLink: WireURLs.shared.howToAddConversationToCustomFolder,
                selected: selected
            )
        }

        return UIHostingController(rootView: navigationStack)
    }
}
