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

final class ConversationCell<Model: ConversationCellModelProtocol>: UITableViewCell {

    var model = Model() {
        didSet { updateConfiguration() }
    }

    private func updateConfiguration() {
        contentConfiguration = UIHostingConfiguration {
            model.buildView()
        }.margins(.all, 0)
    }

}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    ConversationCellPreviews(
        models: [
            .guestsAllowed,
            .timeDivider(text: "Friday"),
            .timeDivider(text: "Saturday"),
            .timeDivider(text: "Sunday")
        ]
    )
}

@MainActor
func ConversationCellPreviews(
    models: [MessageCellModel]
) -> UIViewController {

    enum Section { case single }

    let tableViewController = UITableViewController(style: .plain)

    let dataSource = UITableViewDiffableDataSource<Section, AnyConversationCellModel>(
        tableView: tableViewController.tableView!
    ) { tableView, indexPath, itemIdentifier in
        fatalError()
    }
    tableViewController.dataSource = dataSource

    return tableViewController
}

private extension NSObject {
    var dataSource: AnyObject? {
        get { objc_getAssociatedObject(self, &handle) as? AnyObject }
        set { objc_setAssociatedObject(self, &handle, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

nonisolated(unsafe) private var handle = 0
