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
import WireDesign

package struct ConversationChannelIcon: View {
    let groupIcon: ConversationChannelIconAsset
    let isPrivateChannel: Bool
    
    @ScaledMetric private var iconSize: CGFloat

    // TODO: [WPB-16527] Pass in correct `isPrivateChannel` when we implement public channels
    package init(asset: ConversationChannelIconAsset, size: CGFloat = 34, isPrivateChannel: Bool = true) {
        self.groupIcon = asset
        self.isPrivateChannel = isPrivateChannel
        self._iconSize = .init(wrappedValue: size)
    }

    package var body: some View {
        groupIcon.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay(alignment: .bottomTrailing) {
                if isPrivateChannel {
                    PrivateIcon()
                }
            }
            .frame(width: iconSize, height: iconSize)
    }
}

extension ConversationChannelIcon {
    package struct PrivateIcon: View {
        @ScaledMetric private var width: CGFloat = 9
        @ScaledMetric private var height: CGFloat = 10
        @ScaledMetric private var innerPadding: CGFloat = 3.5
        @ScaledMetric private var cornerRadius: CGFloat = 3
        @ScaledMetric private var offsetX: CGFloat = 3
        @ScaledMetric private var offsetY: CGFloat = 3
        
        package var body: some View {
            Image(systemName: "lock.fill")
                .resizable()
                .frame(width: width, height: height)
                .fontWeight(.bold)
                .foregroundStyle(ColorTheme.Backgrounds.background.color)
                .padding(innerPadding)
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .aspectRatio(1, contentMode: .fit)
                        .foregroundStyle(ColorTheme.Backgrounds.inverted.color)
                }
                .offset(x: offsetX, y: offsetY)
        }
    }
}

#Preview {
    ConversationChannelIcon(asset: .amber)
    ConversationChannelIcon(asset: .green)
    ConversationChannelIcon(asset: .green, isPrivateChannel: false)
}
