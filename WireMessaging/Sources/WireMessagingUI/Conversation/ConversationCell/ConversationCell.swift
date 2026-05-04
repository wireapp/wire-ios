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

final class ConversationCell<Model: ConversationCellModelProtocol>: UITableViewCell {

    var model = Model() {
        didSet { updateConfiguration() }
    }

    private func updateConfiguration() {
        contentConfiguration = UIHostingConfiguration {
            model.buildView()
        }
        .margins(.all, 0)
        .minSize(width: 0, height: 0)
        .background(.clear)
    }

}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    ConversationCellsPreview(
        itemIdentifiers: [
            .timeDivider(text: "Friday", isUnread: false),
            .timeDivider(text: "Saturday", isUnread: false),
            .timeDivider(text: "Today", isUnread: true)
        ]
    )
}
