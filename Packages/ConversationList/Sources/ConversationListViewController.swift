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

import SwiftUI

///
final class ConversationListViewController: UIHostingController<ConversationListView> {

    convenience init() {
        self.init(rootView: .init())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem
        navigationItem.title = "All Conversations"
        navigationItem.backButtonTitle = "Filter"
        navigationItem.hidesBackButton = true
        navigationItem.leftItemsSupplementBackButton = false
        // navigationItem.leftBarButtonItem = .init(image: .init(systemName: "line.3.horizontal.decrease.circle"))

        navigationController!.navigationBar.backIndicatorImage = .init(systemName: "line.3.horizontal.decrease.circle")
        navigationController!.navigationBar.backIndicatorTransitionMaskImage = navigationController!.navigationBar.backIndicatorImage
    }
}

struct ConversationListView: View {

    var body: some View {
        VStack {

            TextField("Search", text: .constant(""))
                .textFieldStyle(.roundedBorder)
                .padding()

            List(conversations) { conversation in
                HStack(spacing: 12) {

                    switch conversation.avatar {
                    case .color(let color):
                        color
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .aspectRatio(1, contentMode: .fit)
                    case .image(let uiImage):
                        Image(uiImage: uiImage)
                            .clipShape(Circle())
                            .aspectRatio(1, contentMode: .fit)
                    }

                    VStack(alignment: .leading) {
                        Text(conversation.name)
                        Text(conversation.info)
                            .foregroundStyle(.gray)
                    }
                }
                .frame(height: 40)
                .listRowBackground(Color(white: 0.95))
            }
            .listStyle(.plain)
        }
        // .navigationTitle("All Conversations")
        .background(Color(white: 0.95))
    }
}

#Preview() {
    SplitViewControllerRepresentable()
        .ignoresSafeArea(edges: .all)
}

private struct SplitViewControllerRepresentable: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UISplitViewController {
        let splitViewController = UISplitViewController(style: .tripleColumn)
        let conversationList = ConversationListViewController()
        splitViewController.viewControllers = [
            SidebarViewController(),
            UINavigationController(rootViewController: conversationList),
            .init()
        ]
        splitViewController.preferredDisplayMode = .twoDisplaceSecondary
        return splitViewController
    }

    func updateUIViewController(_ uiViewController: UISplitViewController, context: Context) {}
}

struct Conversation: Identifiable {

    var avatar: Avatar
    var name: String
    var info: String
    var id: String { name }

    init(_ name: String, _ avatar: Avatar) {
        self.name = name
        self.avatar = avatar
        info = Bool.random() ? "" : "Lorem ipsum dolor sit amet."
    }

    enum Avatar {
        case image(UIImage)
        case color(Color)
    }
}

private let conversations: [Conversation] = [
    .init("Marcel Pierrot", .color(.green)),
    .init("Deniz Agha", .color(.blue)),
    .init("Sales Pitch", .color(.yellow)),
    .init("Across federated backends", .color(.red)),
    .init("Waltraud Liebermann", .color(.black)),
    .init("Conversation name", .color(.brown)),
    .init("John Smith", .color(.cyan)),
    .init("Design", .color(.gray)),
    .init("Marketing Team", .color(.indigo)),
    .init("Martin Koch-Johansen", .color(.mint)),
    .init("Jaqueline Olaho", .color(.orange))
]
