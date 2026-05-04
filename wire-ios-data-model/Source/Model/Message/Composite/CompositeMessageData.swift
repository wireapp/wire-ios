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

import Foundation
import GenericMessageProtocol

// MARK: - CompositeMessageData protocol

public protocol CompositeMessageData {
    var items: [CompositeMessageItem] { get }
}

public enum CompositeMessageItem {
    case text(TextMessageData)
    case button(ButtonMessageData)

    init?(with protoItem: Composite.Item, message: ZMClientMessage) {
        guard let content = protoItem.content else { return nil }
        let itemContent = CompositeMessageItemContent(with: protoItem, message: message)
        switch content {
        case .button:
            self = .button(itemContent)
        case .text:
            self = .text(itemContent)
        }
    }
}

public extension CompositeMessageItem {
    var textData: TextMessageData? {
        guard case let .text(data) = self else { return nil }
        return data
    }
}

// MARK: - ButtonMessageData protocol

public protocol ButtonMessageData {
    var title: String? { get }
    var state: ButtonMessageState { get }
    var isExpired: Bool { get }
    func touchAction()
}
