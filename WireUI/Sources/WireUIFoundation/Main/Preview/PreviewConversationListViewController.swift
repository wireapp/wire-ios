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

import SwiftUI

final class PreviewConversationListViewController: UIHostingController<LabelView>, MainConversationListProtocol {

    // MARK: - MainConversationListProtocol

    var conversationFilter: ConversationFilter?
    var splitViewInterface: MainSplitViewState = .expanded

    enum ConversationFilter: MainConversationFilterConvertible {
        case favorites, groups, oneOnOne

        init(_ mainConversationFilter: MainConversationFilter) {
            switch mainConversationFilter {
            case .favorites: self = .favorites
            case .groups: self  = .groups
            case .oneOnOne: self = .oneOnOne
            }
        }

        func map() -> MainConversationFilter {
            switch self {
            case .favorites: .favorites
            case .groups: .groups
            case .oneOnOne: .oneOnOne
            }
        }
    }

    // MARK: - Life Cycle

    convenience init(_ content: String) {
        self.init(content, .init(uiColor: .systemBackground))
    }

    convenience init(_ content: String, _ backgroundColor: Color) {
        self.init(rootView: .init(content: content, backgroundColor: backgroundColor))
    }
}
