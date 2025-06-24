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

public import SwiftUI
import WireDesign
import WireReusableUIComponents

public struct WireChannelUpgradeBannerView: View {
    @ObservedObject private var viewModel: WireConversationChannelCreationFormViewModel

    public init(
        viewModel: WireConversationChannelCreationFormViewModel
    ) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.black.opacity(0.6))
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text(L10n.Localizable.Conversation.CreationForm.ChannelHistory.UpgradeBanner.title)
                        .wireTextStyle(.buttonSmall)
                        .foregroundStyle(Color.white)
                        .bold()
                        .accessibilityLabel(Text(
                            L10n.Localizable.Conversation.CreationForm.ChannelHistory.UpgradeBanner
                                .title
                        ))

                    Spacer()

                    CloseButton(
                        action: { viewModel.hideUpgradeBanner() },
                        foregroundColor: SemanticColors.Label.textWhite,
                        accessibilityLabel: L10n.Accessibility.Conversation.CreationForm.ChannelHistory.UpgradeBanner
                            .close
                    )
                }

                HStack {
                    Text(L10n.Localizable.Conversation.CreationForm.ChannelHistory.UpgradeBanner.message)
                        .foregroundStyle(.white)
                        .accessibilityLabel(
                            L10n.Localizable.Conversation.CreationForm.ChannelHistory.UpgradeBanner
                                .message
                        )

                    Spacer()
                        .frame(width: 80)
                }

                Link(
                    L10n.Localizable.Conversation.CreationForm.ChannelHistory.UpgradeBanner.button,
                    destination: viewModel.upgradeBannerURL()
                )
                .lineLimit(1)
                .padding(8)
                .background(Color.white.opacity(0.2))
                .foregroundStyle(Color.white)
                .wireTextStyle(.buttonSmall)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.black)
                }
                .clipShape(.rect(cornerRadius: 12))

            }
            .padding(.all, 15)
            .background(alignment: .top) {
                Image("wire_upgrade_banner", bundle: .resources)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .cornerRadius(10)
            .clipped()
            .frame(maxWidth: .infinity)
            .padding([.leading, .trailing], 30)
        }
    }
}

#Preview {
    WireChannelUpgradeBannerView(
        viewModel: WireConversationChannelCreationFormViewModel(
            channelName: "",
            isUserPremium: true
        ) { _ in }
    )
}
