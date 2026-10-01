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

import WireDataModel

public extension LegacyFeatureRepository.FeatureChange {

    /// The feature state this change corresponds to. `WireDataModel` can't express this
    /// itself (it doesn't depend on `WireDomain`), so the mapping lives here instead.

    var featureState: FeatureState {
        switch self {
        case .conferenceCallingIsAvailable:
            FeatureState(name: .conferenceCalling, isEnabled: true)

        case .selfDeletingMessagesIsDisabled:
            FeatureState(name: .selfDeletingMessages, isEnabled: false)

        case .selfDeletingMessagesIsEnabled:
            FeatureState(name: .selfDeletingMessages, isEnabled: true)

        case .fileSharingEnabled:
            FeatureState(name: .fileSharing, isEnabled: true)

        case .fileSharingDisabled:
            FeatureState(name: .fileSharing, isEnabled: false)

        case .conversationGuestLinksEnabled:
            FeatureState(name: .conversationGuestLinks, isEnabled: true)

        case .conversationGuestLinksDisabled:
            FeatureState(name: .conversationGuestLinks, isEnabled: false)

        case .e2eIEnabled:
            FeatureState(name: .e2ei, isEnabled: true)
        }
    }
}
