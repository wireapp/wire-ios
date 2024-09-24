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
import WireUIFoundation

final class MockConversationListViewController: UIViewController, MainConversationListProtocol {

    enum ConversationFilter {
        case groups
    }

    var conversationFilter: ConversationFilter? {
        didSet {
            print("didset \(conversationFilter)")
        }
    }
    var splitViewInterface: MainSplitViewState  = .expanded
}

extension MockConversationListViewController.ConversationFilter: MainConversationFilterRepresentable {

    init(_ mainConversationFilter: MainConversationFilter) {
        switch mainConversationFilter {
            case .groups:
            self = .groups
        case .favorites:
            fatalError("not supported")
        case .oneOnOne:
            fatalError("not supported")
        }
    }

    func map() -> MainConversationFilter {
        switch self {
            case .groups:
            .groups
        }
    }
}
