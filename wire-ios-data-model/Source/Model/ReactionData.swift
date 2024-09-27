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

@objc
public class ReactionData: NSObject {
    // MARK: Lifecycle

    public init(reactionString: String, users: [UserType], creationDate: Date) {
        self.reactionString = reactionString
        self.users = users
        self.creationDate = creationDate
    }

    // MARK: Public

    public let reactionString: String
    public let users: [UserType]
    public let creationDate: Date

    override public var hash: Int {
        reactionString.hash
    }
}
