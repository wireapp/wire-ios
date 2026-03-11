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

package import SwiftUI
package import WireMessagingDomain

package struct ConversationGroupIcon: View {
    let groupIcon: ConversationGroupIconAsset

    @ScaledMetric private var iconSize: CGFloat

    package init(asset: ConversationGroupIconAsset, size: CGFloat = 34) {
        self.groupIcon = asset
        self._iconSize = .init(wrappedValue: size)
    }

    package var body: some View {
        groupIcon.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize, height: iconSize)
    }
}

#Preview {
    ConversationGroupIcon(asset: ConversationGroupIconAsset._1)
    ConversationGroupIcon(asset: ConversationGroupIconAsset._2)
}
