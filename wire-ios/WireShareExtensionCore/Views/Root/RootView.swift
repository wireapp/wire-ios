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

public struct RootView: View {

    @Bindable var viewModel: RootViewModelImpl

    public init(viewModel: RootViewModelImpl) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            form.navigationDestination(for: Conversation.self) { conversation in
                ComposeMessageView(
                    viewModel: ComposeMessageViewModelImpl(
                        conversation: conversation,
                        shareItem: viewModel.shareItem
                    )
                )
            }
            .navigationTitle("Send to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        print("Cancel")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var form: some View {
        Form {
            Section {
                Picker("Account", selection: $viewModel.selectedAccount) {
                    ForEach(viewModel.accounts, id: \.self) { account in
                        Text(account.name)
                    }
                }
            }

            Section("Conversations") {
                ForEach(viewModel.conversations, id: \.self) { conversation in
                    NavigationLink(value: conversation) {
                        Text(conversation.name)
                    }
                }
            }
        }
        .searchable(
            text: $viewModel.searchQuery,
            prompt: "Search conversations"
        )
    }
}

#Preview {
    RootView(
        viewModel: RootViewModelImpl(
            accounts: [
                Account(name: "Sam"),
                Account(name: "John")
            ],
            conversations: [
                Conversation(name: "🍏 iOS Team"),
                Conversation(name: "[iOS] Discipline rituals"),
                Conversation(name: "🚨 Security Channel"),
                Conversation(name: "[iOS] Beta feedbacks]"),
                Conversation(name: "[iOS] developers developers developers")
            ],
            shareItem: ShareItem(
                type: .image,
                fileName: "Screenshot.png"
            )
        )
    )
}
