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

import WireDataModel

/// Updates `conversationFilter` based on system events rather than user selection.
///
/// For example, if the current filter is a folder filter, and the folder is deleted, this selector will remove
/// the filter.

@MainActor
final class ConversationFilterSelector: @preconcurrency ConversationDirectoryObserver {

    private let conversationFilter: () -> ConversationFilter?
    private let updateConversationFilter: (ConversationFilter?) -> Void
    private var observation: Any?

    /// Creates a new ConversationFilterSelector.
    ///
    /// - Parameters:
    ///  - mainCoordinator: The main coordinator.
    ///  - conversationFilter: A closure that returns the current conversation filter.

    init(
        conversationFilter: @escaping () -> ConversationFilter?,
        updateConversationFilter: @escaping (ConversationFilter?) -> Void
    ) {
        self.conversationFilter = conversationFilter
        self.updateConversationFilter = updateConversationFilter
    }

    /// Start observing `conversationDirectory`.

    func observe(conversationDirectory: any ConversationDirectoryType) {
        observation = conversationDirectory.addObserver(self)
    }

    func conversationDirectoryDidChange(
        conversationDirectory: ConversationDirectoryType,
        changeInfo: ConversationDirectoryChangeInfo
    ) {
        if case let .folder(id, _) = conversationFilter(),
           conversationDirectory.nonDeletedFolders.first(where: { $0.remoteIdentifier == id }) == nil {
            updateConversationFilter(nil)
        }
    }
}
