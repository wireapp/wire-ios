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
import SwiftUI

@MainActor
public protocol RootViewModel {

    var accounts: [Account] { get }
    var selectedAccount: Account { get set }

    var searchQuery: String { get set }
    var conversations: [Conversation] { get }

}

@Observable
@MainActor
final class RootViewModelImpl: RootViewModel {

    var accounts: [Account]
    var selectedAccount: Account
    var searchQuery: String = ""

    private let allConversations: [Conversation]

    var conversations: [Conversation] {
        if searchQuery.isEmpty {
            return allConversations
        } else {
            return allConversations.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    init(
        accounts: [Account],
        conversations: [Conversation]
    ) {
        self.accounts = accounts
        self.selectedAccount = accounts[0]
        self.allConversations = conversations
    }

}

struct RootViewModelMock: RootViewModel {

    var accounts: [Account]
    var selectedAccount: Account
    var searchQuery: String
    var conversations: [Conversation]

    init(
        accounts: [Account],
        selectedAccount: Account? = nil,
        searchQuery: String = "",
        conversations: [Conversation]
    ) {
        self.accounts = accounts
        self.selectedAccount = selectedAccount ?? accounts[0]
        self.searchQuery = searchQuery
        self.conversations = conversations
    }

}
