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

public import UIKit

public extension ConversationCellModel {

    @MainActor
    func registerIfNeeded(in tableView: UITableView) {
        guard !tableView.registeredIdentifiers.contains(cellReuseIdentifier) else { return }

        let cellType = switch self {

        case .timeDivider:
            ConversationCell<TimeDividerModel>.self
        case .multipartAttachments:
            MultipartAttachmentsConversationCell.self
        }

        tableView.register(cellType, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.registeredIdentifiers.insert(cellReuseIdentifier)
    }

}

private extension UITableView {

    var registeredIdentifiers: Set<String> {
        get { objc_getAssociatedObject(self, &registeredIdentifiersKey) as? Set<String> ?? [] }
        set { objc_setAssociatedObject(self, &registeredIdentifiersKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

}

@MainActor private var registeredIdentifiersKey = 0
