//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireDataModel

final class StackViewCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationStackMessageContentView

    var cellDescriptions: [AnyConversationMessageCellDescription] { configuration }

    var topMargin: CGFloat {
        get { cellDescriptions.first?.topMargin ?? 0 }
        set { fatalError() }
    }

    static let isFullWidth = true

    var supportsActions: Bool {
        cellDescriptions.contains(where: \.supportsActions)
    }

    var showEphemeralTimer: Bool {
        get { cellDescriptions.contains(where: \.showEphemeralTimer) }
        set { fatalError("TODO?") }
    }

    var containsHighlightableContent: Bool {
        cellDescriptions.contains(where: \.containsHighlightableContent)
    }

    var message: (any ZMConversationMessage)? {
        get {
            for cellDescription in cellDescriptions {
                if let message = cellDescription.message {
                    return message
                }
            }
            return nil
        }
        set {
            for cellDescription in cellDescriptions {
                cellDescription.message = newValue
            }
        }
    }

    var delegate: (any ConversationMessageCellDelegate)? {
        get {
            for cellDescription in cellDescriptions {
                if let delegate = cellDescription.delegate {
                    return delegate
                }
            }
            return nil
        }
        set {
            for cellDescription in cellDescriptions {
                cellDescription.delegate = newValue
            }
        }
    }

    var actionController: ConversationMessageActionController? {
        get {
            for cellDescription in cellDescriptions {
                if let actionController = cellDescription.actionController {
                    return actionController
                }
            }
            return nil
        }
        set {
            for cellDescription in cellDescriptions {
                cellDescription.actionController = newValue
            }
        }
    }

    let configuration: View.Configuration

    var accessibilityIdentifier: String? {
        nil // not used for the stack view, but only for the arranged subviews
    }

    var accessibilityLabel: String? {
        nil // not used for the stack view, but only for the arranged subviews
    }

    init(cellDescriptions: [AnyConversationMessageCellDescription]) {
        self.configuration = cellDescriptions
    }

}
