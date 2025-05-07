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
import WireDesign

struct TextMessageView: ConversationCellContentViewProtocol {

    private(set) var model: TextMessageViewModel

    var body: some View {
        HStack(spacing: 0) {
            // TODOD
        }
        .padding(.vertical, 8)
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

#Preview("with unread indicator") {
    let model = TextMessageViewModel()
    TextMessageView(model: model)
}
