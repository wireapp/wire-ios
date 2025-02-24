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
import WireDataModel

final class StackViewCell: UITableViewCell {

    let stackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupStackView()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupStackView() {

        focusStyle = .custom
        selectionStyle = .none
        backgroundColor = .clear
        isOpaque = false

        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
    }

}

/// A new cell which contains one whole message.
final class UnifiedMessageCell: UITableViewCell {
    typealias Message = WireConversationUI.Message

    var message = Message() {
        didSet {
            if oldValue != message {
                updateContent()
            }
        }
    }

    var messageLayout = MessageLayout.oneOnOneConversationStyle {
        didSet {
            if oldValue != messageLayout {
                updateContent()
            }
        }
    }

    var wireAccentColor: WireAccentColor = .default {
        didSet {
            if oldValue != wireAccentColor {
                updateContent()
            }
        }
    }

    var wireAccentColorMapping: WireAccentColorMapping? {
        didSet { updateContent() }
    }

    private func updateContent() {
        contentConfiguration = UIHostingConfiguration {
            MessageViewBuilder().build(
                message: message,
                layout: messageLayout
                // accountImageViewContent: { Circle().fill(.red) }
            )
//            .swipeActions(edge: .leading) {
//                Button {
//                    print("swipe")
//                } label: {
//                    Label("Reply", systemImage: "arrowshape.turn.up.backward.fill")
//                }
//            }
            .environment(\.wireAccentColor, wireAccentColor)
            .environment(\.wireAccentColorMapping, wireAccentColorMapping)
        }
    }

}

extension WireConversationUI.Message {

    init(_ message: ZMMessage) {
        self.init()
    }

}





var dataSourceX: AnyObject?

@MainActor
func MessageCellPreview(_ messageLayout: MessageLayout) -> UIViewController {

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

struct MessageCellPreviewRepresentable: UIViewControllerRepresentable {

    private let messageLayout: MessageLayout

    init(messageLayout: MessageLayout) {
        self.messageLayout = messageLayout
    }

    func makeUIViewController(context: Context) -> UIViewController {
        MessageCellPreview(messageLayout)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

}
