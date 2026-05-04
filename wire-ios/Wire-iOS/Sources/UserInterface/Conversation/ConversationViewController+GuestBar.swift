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

import UIKit
import WireDataModel

extension ConversationViewController {

    typealias ConversationBanner = L10n.Localizable.Conversation.Banner

    /// The state that the guest bar should adopt in the current configuration.
    var currentGuestBarState: GuestsBarController.State {

        let state = conversation.externalParticipantsState

        guard
            !state.isEmpty,
            let labelKey = label(for: state)
        else {
            return .hidden
        }
        return .visible(labelKey: labelKey)

    }

    func label(for state: ZMConversation.ExternalParticipantsState) -> String? {
        typealias BannerStrings = L10n.Localizable.Conversation.Banner

        switch state {
        case [.visibleRemotes, .visibleExternals, .visibleGuests, .visibleApps]:
            return BannerStrings.remotesExternalsGuestsAppsPresent

        case [.visibleRemotes, .visibleExternals, .visibleGuests]:
            return BannerStrings.remotesExternalsGuestsPresent

        case [.visibleRemotes, .visibleExternals, .visibleApps]:
            return BannerStrings.remotesExternalsAppsPresent

        case [.visibleRemotes, .visibleGuests, .visibleApps]:
            return BannerStrings.remotesGuestsAppsPresent

        case [.visibleExternals, .visibleGuests, .visibleApps]:
            return BannerStrings.externalsGuestsAppsPresent

        case [.visibleRemotes, .visibleExternals]:
            return BannerStrings.remotesExternalsPresent

        case [.visibleRemotes, .visibleGuests]:
            return BannerStrings.remotesGuestsPresent

        case [.visibleRemotes, .visibleApps]:
            return BannerStrings.remotesAppsPresent

        case [.visibleExternals, .visibleGuests]:
            return BannerStrings.externalsGuestsPresent

        case [.visibleExternals, .visibleApps]:
            return BannerStrings.externalsAppsPresent

        case [.visibleGuests, .visibleApps]:
            return BannerStrings.guestsAppsPresent

        case [.visibleRemotes]:
            return BannerStrings.remotesPresent

        case [.visibleExternals]:
            return BannerStrings.externalsPresent

        case [.visibleGuests]:
            return BannerStrings.guestsPresent

        case [.visibleApps]:
            return BannerStrings.appsActive

        default:
            return nil
        }
    }

    /// Updates the visibility of the guest bar.
    func updateGuestsBarVisibility() {
        let currentState = currentGuestBarState
        guestsBarController.state = currentState

        if case .hidden = currentState {
            conversationBarController.dismiss(bar: guestsBarController)
        } else {
            conversationBarController.present(bar: guestsBarController)
        }
    }

}
