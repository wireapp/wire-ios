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

import UIKit
import WireFoundation

public enum MainSplitViewSupplementaryContent<
    ConversationList,
    Archive,
    NewConversation,
    Settings
> where
    ConversationList: UIViewController,
    Archive: UIViewController,
    NewConversation: UIViewController,
    Settings: UIViewController {
    case conversationList(_ conversationList: WeakReference<ConversationList>)
    case archive(_ archive: WeakReference<Archive>)
    case newConversation(_ newConversation: WeakReference<NewConversation>)
    case settings(_ settings: WeakReference<Settings>)
}

extension MainSplitViewSupplementaryContent {

    var viewController: UIViewController? {
        switch self {
        case .conversationList(let conversationList):
            conversationList.reference
        case .archive(let archive):
            archive.reference
        case .newConversation(let newConversation):
            newConversation.reference
        case .settings(let settings):
            settings.reference
        }
    }

    static func conversationList(_ conversationList: ConversationList) -> Self {
        .conversationList(.init(conversationList))
    }

    static func archive(_ archive: Archive) -> Self {
        .archive(.init(archive))
    }

    static func newConversation(_ newConversation: NewConversation) -> Self {
        .newConversation(.init(newConversation))
    }

    static func settings(_ settings: Settings) -> Self {
        .settings(.init(settings))
    }
}
