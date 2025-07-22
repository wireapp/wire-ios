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
import WireFoundation
import WireReusableUIComponents

public struct ChannelBannerView: View {

    private let configuration: Configuration

    @ScaledMetric private var mainButtonFontSize: CGFloat = 14
    @ScaledMetric private var maxWidth: CGFloat = 350

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            titleView
            messageView
            buttonView
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(alignment: .top) {
            Image("wire_banner_background", bundle: .resources)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        .cornerRadius(10)
        .frame(maxWidth: maxWidth)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(BaseColorPalette.Grays.gray90.color, lineWidth: 1)
        )
    }

    private var titleView: some View {
        HStack(alignment: .top) {
            Text(configuration.title)
                .wireTextStyle(.body3)
                .foregroundStyle(Color.white)
                .accessibilityLabel(Text(configuration.title))

            Spacer()

            if let closeButtonConfiguration = configuration.closeButton {
                CloseButton(
                    action: { closeButtonConfiguration.action() },
                    foregroundColor: SemanticColors.Label.textWhite,
                    accessibilityLabel: closeButtonConfiguration.accessibilityLabel
                )
            }
        }
    }

    private var messageView: some View {
        Text(configuration.message)
            .wireTextStyle(.body1)
            .foregroundStyle(.white)
            .accessibilityLabel(
                configuration.message
            )
    }

    private var buttonView: some View {
        Button(configuration.mainButtonTitle, action: configuration.mainButtonAction)
            .lineLimit(1)
            .padding(8)
            .background(ColorTheme.Buttons.Secondary.enabledOutline.color)
            .foregroundStyle(ColorTheme.Buttons.Secondary.onEnabled.color)
            .font(.system(size: mainButtonFontSize, weight: .semibold, design: .default))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(BaseColorPalette.Grays.gray100.color, lineWidth: 1)
            }
            .clipShape(.rect(cornerRadius: 12))
            .padding(.top, 8)
    }
}

#Preview {
    ChannelBannerView(
        configuration: .init(
            title: "Show older messages?",
            message: "Upgrade to a paid plan to offer channel members the whole history.",
            mainButtonTitle: "Upgrade now",
            mainButtonAction: {},
            closeButton: .init(
                accessibilityLabel: "close banner",
                action: {}
            )
        )
    )
    .environment(\.wireTextStyleMapping, WireTextStyleMapping())
    .preferredColorScheme(.dark)
}
