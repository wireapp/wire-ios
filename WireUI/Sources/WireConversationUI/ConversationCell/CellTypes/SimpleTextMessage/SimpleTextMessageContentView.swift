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

struct SimpleTextMessageContentView: ConversationCellContentViewProtocol {
    typealias Model = SimpleTextMessageModel

    let model: Model

    var body: some View {
        VStack(alignment: .leading) {
            Text(model.text)
            if !model.dateTime.isEmpty, !model.status.isEmpty {
                (Text(model.dateTime) + Text(verbatim: " • ") + Text(model.status))
                    .font(.caption)
            } else if !model.dateTime.isEmpty {
                Text(model.dateTime)
                    .font(.caption)
            } else if !model.status.isEmpty {
                Text(model.status)
                    .font(.caption)
            }
            reactions
        }
        .padding()
    }

    @ViewBuilder
    private var reactions: some View {
        ReactionsViewRepresentable?()
    }

}

#Preview {
    let model = SimpleTextMessageModel(
        senderInfo: .none,
        text: "text",
        dateTime: "10:11 AM",
        status: "Sent",
        reactions: []
    )
    return SimpleTextMessageContentView(model: model)
}

// MARK: - Temp

private struct ReactionsViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> UIView {
        SimpleTextMessageContentViewReactionsFactory?() ?? UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        //
    }
}

nonisolated(unsafe) public var SimpleTextMessageContentViewReactionsFactory: (() -> UIView)!
