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

package import SwiftUI
import WireDesign
import WireFoundation
import WireLocators
package import WireMessagingDomain

package struct ConversationTypePicker: View {

    @Environment(\.wireAccentColor) private var wireAccentColor

    private enum Constants {
        static let verticalSpacing: CGFloat = 12
        static let maxIconWidth: CGFloat = 27
        static let minRowHeight: CGFloat = 60
    }

    private enum DisplayedItem: Hashable {
        case channel
        case group
        case divider

        init(_ conversationType: MultiParticipantConversationType) {
            switch conversationType {
            case .channel:
                self = .channel
            case .group:
                self = .group
            }
        }
    }

    private let displayedItems: [DisplayedItem]
    private let onConversationTypeSelected: @Sendable (MultiParticipantConversationType) -> Void

    package init(
        availableConversationTypes: Set<MultiParticipantConversationType>,
        onConversationTypeSelected: @escaping @Sendable (MultiParticipantConversationType) -> Void
    ) {
        let orderedConversationTypes: [MultiParticipantConversationType] = [.channel, .group]

        self.displayedItems = Array(
            orderedConversationTypes
                .filter(availableConversationTypes.contains)
                .map { [DisplayedItem($0)] }
                .joined(separator: [.divider])
        )

        self.onConversationTypeSelected = onConversationTypeSelected
    }

    package var body: some View {
        VStack(spacing: 0) {
            ForEach(displayedItems, id: \.hashValue) { conversationType in
                view(for: conversationType)
            }
        }
        .background(ColorTheme.Backgrounds.surface.color)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func view(for item: DisplayedItem) -> some View {
        switch item {
        case .channel:
            channelItem()
                .padding(.horizontal, 16)
                .frame(minHeight: Constants.minRowHeight)
        case .divider:
            Rectangle()
                .fill(ColorTheme.Backgrounds.background.color)
                .frame(height: 1)
                .padding(.leading, 56)
        case .group:
            groupItem()
                .padding(.horizontal, 16)
                .frame(minHeight: Constants.minRowHeight)
        }
    }

    func channelItem() -> some View {
        Button(action: {
            onConversationTypeSelected(.channel)
        }, label: {
            HStack(alignment: .center, spacing: Constants.verticalSpacing) {
                iconView(for: "wire_conversation_channel_icon")
                VStack(alignment: .leading) {
                    Text(L10n.Localizable.Conversation.Create.Channel.title)
                        .font(for: .body2)
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                        .multilineTextAlignment(.leading)
                    Text(L10n.Localizable.Conversation.Create.Channel.subtitle)
                        .font(for: .h4)
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                chevronView()
            }
        })
    }

    func groupItem() -> some View {
        Button(action: {
            onConversationTypeSelected(.group)
        }, label: {
            HStack(alignment: .center, spacing: Constants.verticalSpacing) {
                iconView(for: "wire_conversation_group_icon")
                Text(L10n.Localizable.Conversation.Create.Group.title)
                    .font(for: .body2)
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                Spacer()
                chevronView()
            }
        })
        .accessibilityIdentifier(Locators.NewConversationPage.createNewGroupButton.rawValue)
    }

    func iconView(for imageName: String) -> some View {
        Image(imageName, bundle: .resources)
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(ColorTheme.Base.primary(wireAccentColor).color)
            .frame(width: Constants.maxIconWidth)
    }

    func chevronView() -> some View {
        Image("wire_conversations_chevron_right", bundle: .resources)
            .renderingMode(.template)
            .foregroundStyle(ColorTheme.Base.secondaryText.color)
    }
}

#Preview {
    VStack {
        ConversationTypePicker(
            availableConversationTypes: [.channel, .group],
            onConversationTypeSelected: { _ in }
        )
        .padding()
    }
    .background(.gray)
}
