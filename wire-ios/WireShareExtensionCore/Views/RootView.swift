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

    // Selected account

    @State
    private var conversations: [ConversationModel]

    @State
    private var accounts: [Account]

    @State
    private var selectedAccount: Account

    public init(accounts: [Account], conversations: [ConversationModel]) {
        self.accounts = accounts
        self.conversations = conversations
        self.selectedAccount = accounts[0]
    }

    public var body: some View {
        NavigationStack {
            form.navigationDestination(for: ConversationModel.self) { conversation in
                ComposeMessageView()
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
                Picker("Account", selection: $selectedAccount) {
                    ForEach(accounts, id: \.self) { account in
                        Text(account.name)
                    }
                }
            }

            Section("Conversations") {
                ForEach(conversations, id: \.self) { conversation in
                    NavigationLink(value: conversation) {
                        Text(conversation.name)
                    }
                }
            }
        }
    }
}

public struct Account: Hashable {

    let id: UUID
    let name: String
}

#Preview {
    RootView(
        accounts: [
            Account(id: UUID(), name: "Sam"),
            Account(id: UUID(), name: "John")
        ],
        conversations: [
        ConversationModel(id: UUID(), name: "One"),
        ConversationModel(id: UUID(), name: "Two"),
        ConversationModel(id: UUID(), name: "Three"),
        ConversationModel(id: UUID(), name: "Four"),
        ConversationModel(id: UUID(), name: "Five"),
    ])
}
