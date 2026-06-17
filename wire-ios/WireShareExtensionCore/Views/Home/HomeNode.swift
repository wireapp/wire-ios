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

struct HomeNode: View {

    let destination: HomeDestination
    let shareItem: ShareItem
    let router: RootRouter
    let onClose: () -> Void
    let onDone: () -> Void

    var body: some View {
        HomeView(viewModel: makeViewModel()) { destination in
            ComposeMessageNode(
                destination: destination,
                onDone: onDone
            )
        }
    }

    private func makeViewModel() -> HomeViewModelImpl {
        HomeViewModelImpl(
            fetchAccounts: FetchAccountsUseCaseMock(),
            fetchConversations: FetchConversationsUseCaseMock(),
            shareItem: shareItem,
            router: router,
            onClose: onClose
        )
    }

}
