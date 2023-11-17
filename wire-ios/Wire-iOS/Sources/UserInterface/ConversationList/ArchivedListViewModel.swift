//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
    func archivedListViewModel(_ model: ArchivedListViewModel, didUpdateConversationWithChange change: ConversationChangeInfo)
}

final class ArchivedListViewModel: NSObject {

    weak var delegate: ArchivedListViewModelDelegate?
    var archivedConversationListObserverToken: NSObjectProtocol?
    var archivedConversations = [ZMConversation]()
    let userSession: UserSession

    init(userSession: UserSession) {
        self.userSession = userSession
        super.init()

        let list = userSession.archivedConversationsInUserSession()
        archivedConversationListObserverToken = userSession.addConversationListObserver(self, for: list)
        archivedConversations = list.asArray() as! [ZMConversation]
    }

    var count: Int {
        return archivedConversations.count
    }

    subscript(key: Int) -> ZMConversation? {
        return archivedConversations[key]
    }

}

extension ArchivedListViewModel: ZMConversationListObserver {
    func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
        guard changeInfo.conversationList == userSession.archivedConversationsInUserSession() else { return }
        delegate?.archivedListViewModel(self, didUpdateArchivedConversationsWithChange: changeInfo) { [weak self] in
            self?.archivedConversations = self?.userSession.archivedConversationsInUserSession().asArray() as! [ZMConversation]
        }
    }

    func conversationInsideList(_ list: ZMConversationList, didChange changeInfo: ConversationChangeInfo) {
        delegate?.archivedListViewModel(self, didUpdateConversationWithChange: changeInfo)
    }
}
