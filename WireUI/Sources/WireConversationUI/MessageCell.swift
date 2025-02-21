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

public final class MessageCell: UITableViewCell {

    public override func prepareForReuse() {
        super.prepareForReuse()

//        var contentConfiguration = defaultContentConfiguration()
//        contentConfiguration.text = "todo"
//        self.contentConfiguration = contentConfiguration
    }
}

@MainActor
public func MessageCellPreview() -> UIViewController {

    let tableViewController = UITableViewController()
    tableViewController.tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
    let dataSource = UITableViewDiffableDataSource<SectionIdentifier, ItemIdentifier>(
        tableView: tableViewController.tableView
    ) { tableView, indexPath, itemID in
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        cell.contentConfiguration = UIHostingConfiguration { // TODO: check docs for swipe action
            Text(verbatim: itemID.uuidString)
                .background(Color.green)
        }
        return cell
    }
    tableViewController.tableView.dataSource = dataSource

    var snapshot = dataSource.snapshot()
    snapshot.appendSections([.single])
    snapshot.appendItems([.init()])
    dataSource.apply(snapshot, animatingDifferences: false)

    return tableViewController

    enum SectionIdentifier: Hashable { case single }
    typealias ItemIdentifier = UUID

}

@available(iOS 17, *)
#Preview {
    MessageCellPreview()
}

public struct MessageCellPreviewRepresentable: UIViewControllerRepresentable {

    public init() {}

    public func makeUIViewController(context: Context) -> UIViewController {
        MessageCellPreview()
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

}
