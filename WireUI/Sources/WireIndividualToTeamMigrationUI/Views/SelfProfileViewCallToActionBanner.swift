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

import WireLocators
import WireReusableUIComponents

public struct SelfProfileViewCallToActionBanner: View {

    let buttonAction: () -> Void

    public init(buttonAction: @escaping () -> Void) {
        self.buttonAction = buttonAction
    }

    public var body: some View {
        InfoBannerView(
            title: .init(localized: "individualToTeam.banner.title", bundle: .module),
            message: .init(localized: "individualToTeam.banner.body", bundle: .module),
            button: .init(
                title: .init(localized: "individualToTeam.banner.button", bundle: .module),
                accessibilityIdentifier: Locators.UserProfilePage.createWireTeamButton.rawValue,
                action: buttonAction
            )
        )
    }

}

#Preview {
    SelfProfileViewCallToActionBanner {}
}
