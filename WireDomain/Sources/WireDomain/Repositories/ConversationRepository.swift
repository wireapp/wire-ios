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

import WireAPI

public protocol ConversationRepositoryProtocol {
    func updateGroupIcon() async throws

    // TODO: [WPB-8701] add all other repository funcs
}

public final class ConversationRepository: ConversationRepositoryProtocol {

    private let conversationAPI: any ConversationsAPI

    public init(conversationAPI: any ConversationsAPI) {
        self.conversationAPI = conversationAPI
    }

    public func updateGroupIcon() async throws {
//        try await conversationAPI.updateGroupIcon(for: <#QualifiedID#>, hexColor: <#String?#>, emoji: <#String?#>)
    }
}
