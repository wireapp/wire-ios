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

/// Defines the contract for any conversation list view controller.

@MainActor
public protocol MainConversationListProtocol: UIViewController {

    /// ``MainConversationListProtocol`` conforming view controllers may use their own type for the
    /// ``conversationFilter-swift.property`` property, however, this type must be creatable from
    /// a ``ConversationFilter`` and has to be convertable to ``ConversationFilter``.
    associatedtype ConversationFilter: MainConversationFilterRepresentable

    // TODO: doc comment
    associatedtype ConversationID: Sendable

    // TODO: doc comment
    associatedtype MessageID: Sendable

    /// Assigning a non-nil value to this property filters the presented conversations by the provided criteria.
    var conversationFilter: ConversationFilter? { get set }

    /// Allows the ``MainCoordinator`` to inform this instance about the current split view state.
    var splitViewInterface: MainSplitViewState { get set }
}
