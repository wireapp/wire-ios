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
import UIKit
import Combine
import WireDesign



public struct TextMessageView: ConversationCellContentViewProtocol {

    @ObservedObject var model: TextMessageViewModel

    public init(model: TextMessageViewModel) {
        self.model = model
    }
    
    public var body: some View {
        VStack {
//            if let model = model.senderViewModel {
//                SenderMessageView(model: model)
                SenderMessageView(model: model.senderViewModel)
//            }
            HStack(spacing: 0) {
                Text(model.text)
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .layoutPriority(1)
            }
            MessageStatusView(model: model.statusViewModel)
        }
    }
}

// MARK: - Previews

#Preview("Simple") {
    let model = TextMessageViewModel(
        text: "Test message",
        senderViewModel: MessageSenderViewModel(
            avatar: AvatarViewModel(color: .red),
            senderModel: UserModel(
                name: "Test",
                isSelfUser: true,
                isServiceUser: false,
                accentColor: .purple
            ),
            isDeleted: false,
            teamRoleIndicator: nil,
            authorChanged: MockSenderObserver()
        ),
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
        case .seenByMultiple(let int):
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
