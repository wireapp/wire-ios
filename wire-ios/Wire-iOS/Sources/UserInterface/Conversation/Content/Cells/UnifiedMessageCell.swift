//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireFoundation
import WireConversationUI
import WireDesign

/// A new cell which contains one whole message.
public final class UnifiedMessageCell: UITableViewCell {
    public typealias Message = WireConversationUI.Message

    public var message = Message() {
        didSet {
            if oldValue != message {
                updateContent()
            }
        }
    }

    public var messageLayout = MessageLayout.oneOnOneConversationStyle {
        didSet {
            if oldValue != messageLayout {
                updateContent()
            }
        }
    }

    public var wireAccentColor: WireAccentColor = .default {
        didSet {
            if oldValue != wireAccentColor {
                updateContent()
            }
        }
    }

    public var wireAccentColorMapping: WireAccentColorMapping? {
        didSet { updateContent() }
    }

    private func updateContent() {
        contentConfiguration = UIHostingConfiguration {
            MessageViewBuilder().build(
                message: message,
                layout: messageLayout
                // accountImageViewContent: { Circle().fill(.red) }
            )
            .swipeActions(edge: .leading) {
                Button {
                    print("swipe")
                } label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.backward.fill")
                        .rotationEffect(.degrees(180)) // TODO: doesn't have effect
                }
            }
            .environment(\.wireAccentColor, wireAccentColor)
            .environment(\.wireAccentColorMapping, wireAccentColorMapping)
        }
    }

}





var dataSourceX: AnyObject?

@MainActor
public func MessageCellPreview(_ messageLayout: MessageLayout) -> UIViewController {

    let tableViewController = UITableViewController()
    tableViewController.tableView.register(UnifiedMessageCell.self, forCellReuseIdentifier: "MessageCell")
    let dataSource = UITableViewDiffableDataSource<SectionIdentifier, ItemIdentifier>(
        tableView: tableViewController.tableView
    ) { tableView, indexPath, itemID in
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        if let cell = cell as? UnifiedMessageCell {
            cell.messageLayout = messageLayout
            cell.message = Message(
                id: .init(itemID),
                attributedText: AttributedString("Hello,\nWorld!")
            )
        }
        return cell
    }
    tableViewController.tableView.dataSource = dataSource
    tableViewController.tableView.separatorStyle = .none

    var snapshot = dataSource.snapshot()
    snapshot.appendSections([.single])
    snapshot.appendItems([.init()])
    dataSource.apply(snapshot, animatingDifferences: false)

    dataSourceX = dataSource

    return tableViewController

    enum SectionIdentifier: Hashable { case single }
    typealias ItemIdentifier = UUID

}

@available(iOS 17, *)
#Preview("oneOnOne") {
    MessageCellPreview(.oneOnOneConversationStyle)
}

@available(iOS 17, *)
#Preview("group") {
    MessageCellPreview(.groupConversationStyle)
}

public struct MessageCellPreviewRepresentable: UIViewControllerRepresentable {

    private let messageLayout: MessageLayout

    public init(messageLayout: MessageLayout) {
        self.messageLayout = messageLayout
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        MessageCellPreview(messageLayout)
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

}
