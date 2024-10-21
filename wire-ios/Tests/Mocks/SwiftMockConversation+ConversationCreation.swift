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

extension SwiftMockConversation {

    static func oneOnOneConversation(
        otherUser: UserType = MockUser.mockUsers().first!
    ) -> SwiftMockConversation {
        _ = MockUser.mockSelf()
        let mockConversation = SwiftMockConversation()
        mockConversation.conversationType = .oneOnOne
        mockConversation.displayName = otherUser.name
        mockConversation.connectedUserType = otherUser
        return mockConversation
    }

    static func groupConversation(
        selfUser: UserType = MockUserType.createSelfUser(name: "Alice"),
        otherUser: UserType = SwiftMockLoader.mockUsers().first!
    ) -> SwiftMockConversation {
        let mockConversation = SwiftMockConversation()
        mockConversation.conversationType = .group
        mockConversation.displayName = otherUser.name
        return mockConversation
    }
}
