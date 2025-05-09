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
import Combine
import WireDesign

struct SenderMessageView: View {

    private(set) var model: MessageSenderViewModel

    var body: some View {
        HStack(spacing: 0) {
            Text(model.author)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeInOut, value: model.author)
        }
        .padding(.vertical, 8)
        .background(.green)
    }
}

struct MessageStatusView: View {
    
    @StateObject var model: MessageStatusViewModel
    
    var body: some View {
        HStack {
            Text(model.timestamp)
            if model.edited {
                Text("Edited")
            }
            Text(model.deliveryState?.text ?? "-")
        }
    }
}

struct TextMessageView: ConversationCellContentViewProtocol {

    @StateObject var model: TextMessageViewModel

    var body: some View {
        VStack {
            if let model = model.senderViewModel {
                SenderMessageView(model: model)
            }
            HStack(spacing: 0) {
                text
            }
            .padding(.vertical, 8)
            .background(.red)
            
            if let model = model.statusViewModel {
                MessageStatusView(model: model)
            }
        }
    }

    @ViewBuilder private var text: some View {
        Text(model.text)
            .multilineTextAlignment(.center)
            .font(.footnote)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .layoutPriority(1)
    }

}

// MARK: - Previews

#Preview("Simple") {
    let model = TextMessageViewModel(
        text: "Test message",
        senderViewModel: MessageSenderViewModel(
            avatar: AvatarViewModel(color: .red),
            author: "Author name",
            authorChanged: MockSenderObserver()
        ),
        statusViewModel: MessageStatusViewModel(
            deliveryState: .pending,
            edited: true,
            timestamp: "2 mins ago"
        )
    )
    TextMessageView(model: model)
}

extension DeliveryState {
    var text: String {
        switch self {
        case .invalid:
            "Invalid"
        case .pending:
            "Pending"
        case .sent:
            "Sent"
        case .delivered:
            "Delivered"
        case .read:
            "Read"
        case .failedToSend:
            "Failed"
        }
    }
}

struct MockSenderObserver: SenderObserverProtocol {
    var authorChangedPublisher: AnyPublisher<String, Never> {
        Empty().eraseToAnyPublisher()
    }
}
