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

import SwiftUI

public struct RootNode: View {

    public let shareItem: ShareItem
    public let fetchAccounts: any FetchAccountsUseCase
    public let fetchConversations: any FetchConversationsUseCase

    // TODO: Maybe Combine close / done into a single callback
    // with an enum param to indicate the action
    public let onClose: () -> Void
    public let onDone: () -> Void

    @State
    private var router = RootRouter()

    public init(
        shareItem: ShareItem,
        fetchAccounts: any FetchAccountsUseCase,
        fetchConversations: any FetchConversationsUseCase,
        onClose: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) {
        self.shareItem = shareItem
        self.fetchAccounts = fetchAccounts
        self.fetchConversations = fetchConversations
        self.onClose = onClose
        self.onDone = onDone
    }

    public var body: some View {
        RootView(
            viewModel: makeViewModel(),
            router: router
        ) { destination in
            HomeNode(
                destination: destination,
                shareItem: shareItem,
                fetchAccounts: fetchAccounts,
                fetchConversations: fetchConversations,
                router: router,
                onClose: onClose,
                onDone: onDone
            )
        }
    }

    private func makeViewModel() -> RootViewModelImpl {
        RootViewModelImpl()
    }

}
