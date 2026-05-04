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

public struct MessageModel: Sendable {

    public enum Kind: Sendable {
        case system(SystemMessageModel)
        case image(ImageMessageModel)
        case text(TextMessageModel)
    }

    public let sender: UserModel?
    public let kind: Kind

    public init(sender: UserModel?, kind: Kind) {
        self.sender = sender
        self.kind = kind
    }
}

// To be refined later
public struct SystemMessageModel: Sendable {}

public struct ImageMessageModel: Sendable {}

public struct TextMessageModel: Sendable {
    public let text: String?

    public init(text: String?) {
        self.text = text
    }
}
