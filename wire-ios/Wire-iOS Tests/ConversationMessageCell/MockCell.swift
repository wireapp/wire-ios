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
import WireFoundation

@testable import Wire

final class MockCell: UIView, ConversationMessageContentView {
    struct Configuration {
        let backgroundColor: UIColor
    }

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageContentViewDelegate?

    var isConfigured: Bool = false
    var isSelected: Bool = false

    func configure(with object: Configuration, animated: Bool) {
        isConfigured = true
        backgroundColor = object.backgroundColor
    }
}

final class MockCellDescription<T>: ConversationMessageContentViewDescription {
    typealias View = MockCell
    let configuration: View.Configuration

    var canBeCombinedWithOtherCells: Bool { fatalError("TODO") }

    var showEphemeralTimer: Bool = false
    var topMargin: CGFloat = 0
    var supportsActions: Bool = true
    var containsHighlightableContent: Bool = true

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageContentViewDelegate?
    weak var actionController: ConversationMessageActionController?

    var accessibilityIdentifier: String?
    var accessibilityLabel: String?

    init() {
        let backgroundColor = AccentColor.red.uiColor
        self.configuration = View.Configuration(backgroundColor: backgroundColor)
    }
}
