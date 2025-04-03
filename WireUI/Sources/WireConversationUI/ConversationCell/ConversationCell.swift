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

// TODO: remove after performance review
import os

@MainActor private var instanceCount = 0
private let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ConversationCell")

final class ConversationCell<Model: ConversationCellModelProtocol>: UITableViewCell {

    var model = Model() {
        didSet { updateConfiguration() }
    }

    private func updateConfiguration() {
        contentConfiguration = UIHostingConfiguration {
            model.buildView()
            // .id(model.id) // TODO: check if .id should or must not be used
        }
        .margins(.all, 0)
        .minSize(width: 0, height: 0)
        .background(.clear)
    }

    // TODO: remove global var and init/deinit
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        instanceCount += 1
        logger
            .info(
                "ConversationCell<\(String(describing: Model.self), privacy: .public)>.init, total instance count: \(instanceCount, privacy: .public)"
            )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        Task { @MainActor in
            instanceCount -= 1
            logger
                .info(
                    "ConversationCell<\(String(describing: Model.self), privacy: .public)>.deinit, total instance count: \(instanceCount, privacy: .public)"
                )
        }
    }

}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    ConversationCellsPreview(
        itemIdentifiers: [
            .timeDivider(text: "Tuesday, Mar 18", isUnread: false),
            .simpleTextMessage(
                text: "message",
                dateTime: "10:11 AM",
                status: ""
            ),
            .simpleTextMessage(
                text: "message",
                dateTime: "11:10 AM",
                status: ""
            ),
            .timeDivider(text: "25 hours ago", isUnread: true),
            .simpleTextMessage(
                text: "message",
                dateTime: "11:30 AM",
                status: ""
            ),
            .timeDivider(text: "Today", isUnread: false),
            .simpleTextMessage(
                text: "message",
                dateTime: "12:30 AM",
                status: "👁️"
            )
        ]
    )
}

// seen+sent timestamps only time
// read indicator on last message and without timestamp
