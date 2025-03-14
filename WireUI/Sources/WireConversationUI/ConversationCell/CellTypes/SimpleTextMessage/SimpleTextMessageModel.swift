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

public struct SimpleTextMessageModel: ConversationCellModelProtocol {
    typealias ContentView = SimpleTextMessageContentView

    public var id: AnyHashable { self }

    /// If `nil` no sender info is displayed (e.g. for subsequent messages of the same sender).
    var senderInfo: MessageSenderInfo?

    var text: AttributedString

    var dateTime: String

    var status: String

    var reactions: Reactions

    init() {
        self.text = AttributedString()
        self.dateTime = ""
        self.status = ""
        self.reactions = Reactions()
    }

}

public extension ConversationCellModel {

    static var simpleTextMessage: Self {
        .simpleTextMessage(SimpleTextMessageModel())
    }
}
