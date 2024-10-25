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
import WireSyncEngine

protocol ArchivedListViewModelDelegate: AnyObject {
    func archivedListViewModel(_ model: ArchivedListViewModel, didUpdateArchivedConversationsWithChange change: ConversationListChangeInfo, applyChangesClosure: @escaping () -> Void)
}

final class ArchivedListViewModel: NSObject {

    weak var delegate: ArchivedListViewModelDelegate?
    private(set) var archivedConversationListObserverToken: NSObjectProtocol?
    private(set) var archivedConversations = [ZMConversation]()
    private let userSession: UserSession

    var isEmptyArchivePlaceholderVisible: Bool {
        archivedConversations.isEmpty
    }

    init(userSession: UserSession) {
        self.userSession = userSession
        super.init()

        let list = userSession.archivedConversationsInUserSession()
        archivedConversationListObserverToken = userSession.addConversationListObserver(self, for: list)
        archivedConversations = list.items
    }

    var count: Int {
        return archivedConversations.count
    }

    subscript(key: Int) -> ZMConversation {
        return archivedConversations[key]
    }

    func unarchiveConversation(at row: Int) {
        let conversation = self[row]
        userSession.enqueue {
            conversation.isArchived = false
        }
    }
}

extension ArchivedListViewModel: ZMConversationListObserver {

    func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
        guard changeInfo.conversationList == userSession.archivedConversationsInUserSession() else { return }
        delegate?.archivedListViewModel(self, didUpdateArchivedConversationsWithChange: changeInfo) { [weak self] in
            guard let self else { return }
            archivedConversations = userSession.archivedConversationsInUserSession().items
        }
    }

    func conversationInsideList(_ list: ConversationList, didChange changeInfo: ConversationChangeInfo) {
        // no-op
    }
}
