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

public protocol FetchConversationsUseCase {

    /// Fetch all conversations for a given account in which a
    /// message can be sent.
    func callAsFunction(
        for account: Account
    ) async throws -> [Conversation]

}

struct FetchConversationsUseCaseMock: FetchConversationsUseCase {

    func callAsFunction(
        for account: Account
    ) async throws -> [Conversation] {
        try await Task.sleep(
            for: .milliseconds((500...1000).randomElement()!)
        )

        switch account {
        case .sam:
            return [
                Conversation(name: "Engineering Team"),
                Conversation(name: "Product Design"),
                Conversation(name: "Alice Cooper"),
                Conversation(name: "Weekend Plans"),
                Conversation(name: "Marketing"),
                Conversation(name: "Bob Martinez"),
            ]
        case .john:
            return [
                Conversation(name: "Family Group"),
                Conversation(name: "Project Alpha"),
                Conversation(name: "Sarah Johnson"),
                Conversation(name: "Book Club"),
            ]
        default:
            return []
        }
    }

}
