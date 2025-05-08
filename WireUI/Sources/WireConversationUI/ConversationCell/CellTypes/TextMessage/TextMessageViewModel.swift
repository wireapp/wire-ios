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

import Foundation
import SwiftUI

public struct AvatarViewModel: Hashable, Sendable {
    let color: Color
    public init(color: Color) {
        self.color = color
    }
}

public struct MessageSenderViewModel: Hashable, Sendable {
    
    let avatar: AvatarViewModel

    let author: AttributedString
    
    public init(avatar: AvatarViewModel, author: AttributedString) {
        self.avatar = avatar
        self.author = author
    }
}

public enum DeliveryState: Int, Sendable {
    case invalid
    case pending
    case sent
    case delivered
    case read
    case failedToSend
}

public struct MessageStatusViewModel: Hashable, Sendable {
    let deliveryState: DeliveryState?
    let edited: Bool
    let timestamp: String
    
    public init(
        deliveryState: DeliveryState?,
        edited: Bool,
        timestamp: String
    ) {
        self.deliveryState = deliveryState
        self.edited = edited
        self.timestamp = timestamp
    }
}

public struct TextMessageViewModel: ConversationCellModelProtocol {
    
    typealias ContentView = TextMessageView
    
    let senderViewModel: MessageSenderViewModel?
    let statusViewModel: MessageStatusViewModel?

    public var id: AnyHashable { self }

    var text: String
    
    public init(
        text: String,
        senderViewModel: MessageSenderViewModel?,
        statusViewModel: MessageStatusViewModel?
    ) {
        self.text = text
        self.senderViewModel = senderViewModel
        self.statusViewModel = statusViewModel
    }

    init() {
        self.init(
            text: "",
            senderViewModel: nil,
            statusViewModel: nil
        )
    }

}

extension ConversationCellModel {

//    static func timeDivider(
//        text: String,
//        isUnread: Bool
//    ) -> Self {
//        let model = TimeDividerModel(
//            text: text,
//            isUnreadIndicatorVisible: isUnread
//        )
//        return .timeDivider(model)
//    }
}

