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
import UIKit
import WireDesign
import WireFoundation
import WireReusableUIComponents

public struct SelfProfileViewCallToActionBanner: View {

    public enum Action: Sendable {
        case createWireTeam
    }

    let actionCallback: @Sendable (Action) -> Void

    public init(actionCallback: @escaping @Sendable (Action) -> Void) {
        self.actionCallback = actionCallback
    }

    public var body: some View {
        contentView(actionCallback: actionCallback)
            .padding(8)
            .bannerBackground()
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())
    }
}

@MainActor
@ViewBuilder
private func contentView(
    actionCallback: @escaping @Sendable (SelfProfileViewCallToActionBanner.Action) -> Void
) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Label(title: {
            Text(String.localized(key: "individualToTeam.banner.title", bundle: .module))
                .wireTextStyle(.h5)
        }, icon: {
            Image.infoCircle
        })
        Text(String.localized(key: "individualToTeam.banner.body", bundle: .module))
            .wireTextStyle(.body1)
            .lineLimit(nil)

        Button(
            action: { actionCallback(.createWireTeam) },
            label: {
                Text(String.localized(key: "individualToTeam.banner.button", bundle: .module))
            }
        )
        .wireButtonStyle(.tertiary)
    }
}

private extension View {
    func bannerBackground() -> some View {
        background {
            if #available(iOS 17.0, *) {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ColorTheme.Banners.border.color, lineWidth: 1)
                    .fill(ColorTheme.Banners.background.color)
            } else {
                ColorTheme.Banners.background.color
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .border(ColorTheme.Banners.border.color, width: 1)
            }
        }
    }
}

public class SelfProfileViewCallToActionBannerHostingController: UIHostingController<SelfProfileViewCallToActionBanner> {
    public init(actionCallback: @escaping @Sendable (SelfProfileViewCallToActionBanner.Action) -> Void) {
        super.init(rootView: SelfProfileViewCallToActionBanner(actionCallback: actionCallback))
        view.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 17.0, *)
#Preview {
    SelfProfileViewCallToActionBanner(actionCallback: { _ in })
}
