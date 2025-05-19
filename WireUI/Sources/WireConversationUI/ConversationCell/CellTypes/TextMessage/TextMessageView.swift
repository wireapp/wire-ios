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

import Combine
import SwiftUI
import UIKit
import WireDesign
import WireReusableUIComponents

public struct TextMessageView: ConversationCellContentViewProtocol {

    @ObservedObject var model: TextMessageViewModel

    public init(model: TextMessageViewModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            SenderMessageView(model: model.senderViewModelWrapper)
            HStack(spacing: 0) {
                LinkInteractionTextViewWrapper(
                    text: model.text,
                    accentColor: model.accentColor,
                    shouldDetectTypes: true
                )
            }
            MessageStatusView(model: model.statusViewModel)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#Preview("Simple") {
    let model = TextMessageViewModel(
        text: "Test message",
        accentColor: .red,
        isObfuscated: false,
        senderViewModelWrapper: .init(state: .some(MessageSenderViewModel(
            avatarViewModel: AvatarViewModel(color: .red),
            senderModel: UserModel(
                name: "Test",
                isSelfUser: true,
                isServiceUser: false,
                accentColor: .purple
            ),
            isDeleted: false,
            teamRoleIndicator: nil,
            authorChanged: MockSenderObserver()
        ))),
        statusViewModel: MessageStatusViewModel(
            state: .details(StatusDetails(
                deliveryState: .seen,
                editedString: "Edited: 2 mins ago",
                timestamp: "2 mins ago"
            ))
        )
    )
    TextMessageView(model: model)
}

extension MessageToolboxState {
    var text: String { // TODO: migrate strings

        switch self {
        case .sending:
            "Sending"
        case .sent:
            "Sent"
        case .delivered:
            "Delivered"
        case .seen:
            "Seen"
        case let .seenByMultiple(int):
            "Seen \(int)"
        }
    }
}

struct MockSenderObserver: SenderObserverProtocol {
    var authorChangedPublisher: AnyPublisher<String, Never> {
        Empty().eraseToAnyPublisher()
    }
}

struct MockStatusObserver: StatusObserverProtocol {
    var statusChangedPublisher: AnyPublisher<MessageModel, Never> {
        Empty<MessageModel, Never>().eraseToAnyPublisher()
    }
}
