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

public struct TimeDividerModel: ConversationCellModelProtocol {
    typealias ContentView = TimeDividerContentView

    public var id: AnyHashable { self }

    var text: String
    var isUnreadIndicatorVisible: Bool

    public init(
        text: String,
        isUnreadIndicatorVisible: Bool
    ) {
        self.text = text
        self.isUnreadIndicatorVisible = isUnreadIndicatorVisible
    }

    init() {
        self.init(
            text: "",
            isUnreadIndicatorVisible: false
        )
    }

}

extension ConversationCellModel {

    static func timeDivider(
        text: String,
        isUnread: Bool
    ) -> Self {
        let model = TimeDividerModel(
            text: text,
            isUnreadIndicatorVisible: isUnread
        )
        return .timeDivider(model)
    }
}
