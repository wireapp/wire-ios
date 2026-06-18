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

@MainActor
protocol HomeViewModel {

    var accounts: [Account] { get }
    var selectedAccount: Account? { get set }

    var searchQuery: String { get set }
    var conversations: [Conversation] { get }

    var isLoading: Bool { get }

    func start() async
    func reloadConversations()
    func selectConversation(_ conversation: Conversation)
    func close()

}

@MainActor
@Observable
final class HomeViewModelImpl: HomeViewModel {

    var accounts: [Account] = []
    var selectedAccount: Account?

    var searchQuery: String = ""
    var isLoading: Bool = false

    private var allConversations: [Conversation] = []
    var conversations: [Conversation] {
        if searchQuery.isEmpty {
            return allConversations
        } else {
            return allConversations.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    private let fetchAccounts: any FetchAccountsUseCase
    private let fetchConversations: any FetchConversationsUseCase
    private let router: RootRouter
    private let onClose: () -> Void

    init(
        fetchAccounts: any FetchAccountsUseCase,
        fetchConversations: any FetchConversationsUseCase,
        router: RootRouter,
        onClose: @escaping () -> Void
    ) {
        self.fetchAccounts = fetchAccounts
        self.fetchConversations = fetchConversations
        self.router = router
        self.onClose = onClose
    }

    func start() async {
        isLoading = true
        defer { isLoading = false }

        let fetchAccountsTask = Task.detached { [self] in
            try await fetchAccounts()
        }

        do {
            accounts = try await fetchAccountsTask.value
            selectedAccount = accounts.first
        } catch {
            router.errorAlert = .debug(message: "failed to fetch accounts: \(error)")
        }

        await internalReloadConversations()
    }

    func reloadConversations() {
        Task {
            await internalReloadConversations()
        }
    }

    private func internalReloadConversations() async {
        isLoading = true
        defer { isLoading = false }

        let fetchConversationsTask = Task.detached { [self] in
            try await fetchConversations(for: selectedAccount!)
        }

        do {
            allConversations = try await fetchConversationsTask.value
        } catch {
            router.errorAlert = .debug(message: "failed to fetch conversations: \(error)")
        }
    }

    func close() {
        onClose()
    }

    func selectConversation(_ conversation: Conversation) {
        router.navigateTo(
            ComposeMessageDestination(
                account: selectedAccount!, // TODO: Make safe
                conversation: conversation
            )
        )
    }

}

struct HomeViewModelMock: HomeViewModel {

    var accounts: [Account]
    var selectedAccount: Account?
    var searchQuery: String
    var conversations: [Conversation]

    var isLoading: Bool

    init(
        accounts: [Account],
        selectedAccount: Account? = nil,
        searchQuery: String = "",
        conversations: [Conversation],
        isLoading: Bool = false,
    ) {
        self.accounts = accounts
        self.selectedAccount = selectedAccount ?? accounts.first
        self.searchQuery = searchQuery
        self.conversations = conversations
        self.isLoading = isLoading
    }

    func start() async {}
    func reloadConversations() {}
    func selectConversation(_ conversation: Conversation) {}
    func close() {}
}
