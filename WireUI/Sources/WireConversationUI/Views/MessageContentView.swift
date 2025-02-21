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

struct MessageContentView<
    AccountImageView: View
>: View {

    let accountImageViewDiameter: CGFloat = 32

    var message: Message
    var layout: MessageLayout
    var accountImageViewContent: () -> AccountImageView

    var body: some View {
        switch layout {
        case .oneOnOneConversationStyle:
            oneOnOneConversationContent()
        case .groupConversationStyle:
            groupConversationContent()
        }
    }

    @ViewBuilder
    private func oneOnOneConversationContent() -> some View {
        HStack(alignment: .top) {

            accountImageViewContent()
                .frame(width: accountImageViewDiameter, height: accountImageViewDiameter)

            VStack {
                Text(message.attributedText)
            }

        }
    }

    @ViewBuilder
    private func groupConversationContent() -> some View {
        Grid(alignment: .topLeading) {
            GridRow(alignment: .center) {
                accountImageViewContent()
                    .frame(width: accountImageViewDiameter, height: accountImageViewDiameter)
                Text(verbatim: "sender-name")
                    .frame(minHeight: accountImageViewDiameter)
            }
            GridRow {
                Color.clear
                    .gridCellUnsizedAxes([.horizontal, .vertical])
                Text(message.attributedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

}
