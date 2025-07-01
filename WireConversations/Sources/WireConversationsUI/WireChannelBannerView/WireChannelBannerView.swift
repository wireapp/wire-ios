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

public struct WireChannelBannerView: View {

    private let configuration: Configuration

    @ScaledMetric private var maxWidth: CGFloat = 350

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(configuration.title)
                    .wireTextStyle(.buttonSmall)
                    .foregroundStyle(Color.white)
                    .bold()
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

            Text(configuration.message)
                .foregroundStyle(.white)
                .accessibilityLabel(
                    configuration.message
                )

            Link(
                configuration.buttonTitle,
                destination: configuration.buttonURL
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
            Image("wire_banner_background", bundle: .resources)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        .cornerRadius(10)
        .clipped()
        .frame(maxWidth: maxWidth)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(SemanticColors.View.channelBannerBorderColor.color, lineWidth: 1)
        )
        .padding([.leading, .trailing], configuration.padding)
    }
}

#Preview {
    WireChannelBannerView(
        configuration: .init(
            title: "Show older messages?",
            message: "Upgrade to a paid plan to offer channel members the whole history.",
            buttonTitle: "Upgrade now",
            buttonURL: URL(string: "https://example.com")!,
            padding: 30,
            closeButton: .init(
                accessibilityLabel: "close banner",
                action: {}
            )
        )
    )
}
