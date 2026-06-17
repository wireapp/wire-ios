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

struct HomeView<
    ViewModel: HomeViewModel,
    ComposeMessageNode: View
>: View {

    @State
    var viewModel: ViewModel

    @ViewBuilder
    var makeComposeMessageNode: (ComposeMessageDestination) -> ComposeMessageNode

    var body: some View {
        content
            .navigationTitle("Send to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") {
                        viewModel.close()
                    }
                }
            }
            .task {
                await viewModel.start()
            }
            .overlay {
                if viewModel.isLoading {
                    loadingIndicator
                }
            }
            .navigationDestination(for: ComposeMessageDestination.self) {
                makeComposeMessageNode($0)
            }
    }

    @ViewBuilder
    private var content: some View {
        Form {
            if viewModel.accounts.count > 1 {
                Section {
                    Picker("Account", selection: $viewModel.selectedAccount) {
                        ForEach(viewModel.accounts, id: \.self) { account in
                            Text(account.name).tag(account)
                        }
                    }
                    .onChange(of: viewModel.selectedAccount) { oldValue, newValue in
                        guard oldValue != newValue else { return }
                        viewModel.reloadConversations()
                    }
                }
            }

            Section("Conversations") {
                ForEach(viewModel.conversations, id: \.self) { conversation in
                    Text(conversation.name).onTapGesture {
                        viewModel.selectConversation(conversation)
                    }
                }
            }
        }
        .searchable(
            text: $viewModel.searchQuery,
            prompt: "Search conversations"
        )
    }

    private var loadingIndicator: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
        }
    }

}

#Preview("Single account") {
    HomeView(
        viewModel: HomeViewModelMock(
            accounts: [
                .sam,
            ],
            conversations: [
                Conversation(name: "🍏 iOS Team"),
                Conversation(name: "[iOS] Discipline rituals"),
                Conversation(name: "🚨 Security Channel"),
                Conversation(name: "[iOS] Beta feedbacks]"),
                Conversation(name: "[iOS] developers developers developers")
            ]
        ),
        makeComposeMessageNode: { _ in Color.red }
    )
}

#Preview("View") {
    HomeView(
        viewModel: HomeViewModelMock(
            accounts: [
                .sam,
                .john
            ],
            conversations: [
                Conversation(name: "🍏 iOS Team"),
                Conversation(name: "[iOS] Discipline rituals"),
                Conversation(name: "🚨 Security Channel"),
                Conversation(name: "[iOS] Beta feedbacks]"),
                Conversation(name: "[iOS] developers developers developers")
            ]
        ),
        makeComposeMessageNode: { _ in Color.red }
    )
}

#Preview("Model") {
    @Previewable
    @State
    var router = RootRouter()

    return NavigationStack(path: $router.path) {
        HomeView(
            viewModel: HomeViewModelImpl(
                fetchAccounts: FetchAccountsUseCaseMock(),
                fetchConversations: FetchConversationsUseCaseMock(),
                shareItem: ShareItem(
                    type: .image,
                    url: URL(string: "")!,
                    name: "foo.jpg",
                    mimeType: "jpg",
                    size: nil
                ),
                router: router,
                onClose: {
                    print("Close")
                }
            ),
            makeComposeMessageNode: { _ in Color.red }
        )
    }
}
