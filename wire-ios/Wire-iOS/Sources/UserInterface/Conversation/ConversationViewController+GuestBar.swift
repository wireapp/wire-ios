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
        return .visible(labelKey: labelKey, identifier: identifier(for: state))

    }

    func label(for state: ZMConversation.ExternalParticipantsState) -> String? {
        typealias BannerStrings = L10n.Localizable.Conversation.Banner

        switch state {
        case [.visibleRemotes, .visibleExternals, .visibleGuests, .visibleServices]:
            return BannerStrings.remotesExternalsGuestsServicesPresent

        case [.visibleRemotes, .visibleExternals, .visibleGuests]:
            return BannerStrings.remotesExternalsGuestsPresent

        case [.visibleRemotes, .visibleExternals, .visibleServices]:
            return BannerStrings.remotesExternalsServicesPresent

        case [.visibleRemotes, .visibleGuests, .visibleServices]:
            return BannerStrings.remotesGuestsServicesPresent

        case [.visibleExternals, .visibleGuests, .visibleServices]:
            return BannerStrings.externalsGuestsServicesPresent

        case [.visibleRemotes, .visibleExternals]:
            return BannerStrings.remotesExternalsPresent

        case [.visibleRemotes, .visibleGuests]:
            return BannerStrings.remotesGuestsPresent

        case [.visibleRemotes, .visibleServices]:
            return BannerStrings.remotesServicesPresent

        case [.visibleExternals, .visibleGuests]:
            return BannerStrings.externalsGuestsPresent

        case [.visibleExternals, .visibleServices]:
            return BannerStrings.externalsServicesPresent

        case [.visibleGuests, .visibleServices]:
            return BannerStrings.guestsServicesPresent

        case [.visibleRemotes]:
            return BannerStrings.remotesPresent

        case [.visibleExternals]:
            return BannerStrings.externalsPresent

        case [.visibleGuests]:
            return BannerStrings.guestsPresent

        case [.visibleServices]:
            return BannerStrings.servicesActive

        default:
            return nil
        }
    }

    func identifier(for state: ZMConversation.ExternalParticipantsState) -> String {
        var identifiers: [String] = []

        if conversation.externalParticipantsState.contains(.visibleRemotes) {
            identifiers.append("remotes")
        }

        if conversation.externalParticipantsState.contains(.visibleExternals) {
            identifiers.append("externals")
        }

        if conversation.externalParticipantsState.contains(.visibleGuests) {
            identifiers.append("guests")
        }

        if conversation.externalParticipantsState.contains(.visibleServices) {
            identifiers.append("services")
        }

        return "has\(identifiers.joined(separator: "and"))"
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

    func setGuestBarForceHidden(_ isGuestBarForceHidden: Bool) {
        if isGuestBarForceHidden {
            guestsBarController.setState(.hidden, animated: true)
            guestsBarController.shouldIgnoreUpdates = true
        } else {
            guestsBarController.shouldIgnoreUpdates = false
            updateGuestsBarVisibility()
        }
    }

}
