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
    var selectedAccount: Account? { get set }

    var searchQuery: String { get set }
    var conversations: [Conversation] { get }
    var shareItem: ShareItem { get }

    var isLoading: Bool { get }
    var errorAlert: ErrorAlert? { get set }

    func start() async
    func reloadConversations()

}

@Observable
@MainActor
public final class RootViewModelImpl: RootViewModel {

    public var accounts: [Account] = []
    public var selectedAccount: Account?

    public var searchQuery: String = ""
    public let shareItem: ShareItem

    public var errorAlert: ErrorAlert?
    public var isLoading: Bool = false

    private var allConversations: [Conversation] = []
    public var conversations: [Conversation] {
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

    public init(
        fetchAccounts: any FetchAccountsUseCase,
        fetchConversations: any FetchConversationsUseCase,
        shareItem: ShareItem
    ) {
        self.fetchAccounts = fetchAccounts
        self.fetchConversations = fetchConversations
        self.shareItem = shareItem
    }

    public func start() async {
        isLoading = true
        defer { isLoading = false }

        let fetchAccountsTask = Task.detached { [self] in
            try await fetchAccounts()
        }

        do {
            accounts = try await fetchAccountsTask.value
            selectedAccount = accounts.first
        } catch {
            errorAlert = .debug(message: "failed to fetch accounts: \(error)")
        }
    }

    public func reloadConversations() {
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
            errorAlert = .debug(message: "failed to fetch conversations: \(error)")
        }
    }

}

struct RootViewModelMock: RootViewModel {

    var accounts: [Account]
    var selectedAccount: Account?
    var searchQuery: String
    var conversations: [Conversation]
    var shareItem: ShareItem

    var isLoading: Bool
    var errorAlert: ErrorAlert?

    init(
        accounts: [Account],
        selectedAccount: Account? = nil,
        searchQuery: String = "",
        conversations: [Conversation],
        shareItem: ShareItem,
        isLoading: Bool = false,
        errorAlert: ErrorAlert? = nil
    ) {
        self.accounts = accounts
        self.selectedAccount = selectedAccount ?? accounts.first
        self.searchQuery = searchQuery
        self.conversations = conversations
        self.shareItem = shareItem
        self.isLoading = isLoading
        self.errorAlert = errorAlert
    }

    func start() async {}
    func reloadConversations() {}
}
