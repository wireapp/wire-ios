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

import UIKit
import WireDataModel

/// Header view controller for group and channel conversations.
/// Stacks the guest-warning banner above the conversation-started summary.
final class DefaultConversationHeaderViewController: UIViewController {

    private let conversation: ZMConversation
    private let selfUser: any UserType
    private var newConversationHeader: ConversationNewConversationHeaderView?

    weak var delegate: ConversationMessageCellDelegate? {
        didSet { newConversationHeader?.delegate = delegate }
    }

    init(conversation: ZMConversation, selfUser: any UserType) {
        self.conversation = conversation
        self.selfUser = selfUser
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        let header = ConversationNewConversationHeaderView(
            conversation: conversation,
            selfUser: selfUser
        )
        newConversationHeader = header

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.addArrangedSubview(DefaultConversationHeaderView())
        if !header.isEmpty {
            stackView.addArrangedSubview(header)
        }
        view = stackView
    }
}
