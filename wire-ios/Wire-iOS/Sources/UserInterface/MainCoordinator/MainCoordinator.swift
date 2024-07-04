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
import WireSystem

struct MainCoordinator: MainCoordinating {

    weak var zClientViewController: ZClientViewController?

    func openConversation(_ conversation: ZMConversation, focusOnView focus: Bool, animated: Bool) {
        guard let zClientViewController else {
            return WireLogger.mainCoordinator.warn("zClientViewController is nil")
        }
        zClientViewController.load(conversation, scrollTo: nil, focusOnView: focus, animated: animated)
    }

    func openConversation<Message>(
        _ conversation: ZMConversation,
        scrollTo message: Message,
        focusOnView focus: Bool,
        animated: Bool
    ) where Message: ZMConversationMessage {
        guard let zClientViewController else {
            return WireLogger.mainCoordinator.warn("zClientViewController is nil")
        }
        zClientViewController.load(conversation, scrollTo: message, focusOnView: focus, animated: animated)
    }

    func showConversationList() {
        guard let zClientViewController else {
            return WireLogger.mainCoordinator.warn("zClientViewController is nil")
        }
        zClientViewController.showConversationList()
    }

    func showSettings() {
        zClientViewController?.presentSettings()
    }
}
