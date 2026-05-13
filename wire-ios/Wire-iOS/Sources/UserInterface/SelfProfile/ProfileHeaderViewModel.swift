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

import Foundation
import WireSyncEngine

final class ProfileHeaderViewModel {

    struct DisplayState {
        let handleText: String?
        let teamNameText: String?
        let remainingTimeText: String?
        let isGuestIndicatorHidden: Bool
        let isExternalIndicatorHidden: Bool
        let isFederatedIndicatorHidden: Bool
        let isGroupRoleIndicatorHidden: Bool
        let isAvailabilityHidden: Bool
        let isProfilePictureEditingEnabled: Bool
        let isQRCodeButtonHidden: Bool
    }

    enum AvailabilitySelectionAction {
        case updateAvailability(Availability)
    }

    enum Route {
        case none
        case showQRCode(UserQRCodeViewModel)
    }

    private let user: UserType
    private let viewer: UserType
    private let conversation: ZMConversation?
    private let options: ProfileHeaderViewController.Options

    var displayState: DisplayState {
        DisplayState(
            handleText: handleText,
            teamNameText: teamNameText,
            remainingTimeText: user.expirationDisplayString,
            isGuestIndicatorHidden: isGuestIndicatorHidden,
            isExternalIndicatorHidden: !user.isExternalPartner,
            isFederatedIndicatorHidden: !user.isFederated,
            isGroupRoleIndicatorHidden: isGroupRoleIndicatorHidden,
            isAvailabilityHidden: isAvailabilityHidden,
            isProfilePictureEditingEnabled: options.contains(.allowEditingProfilePicture),
            isQRCodeButtonHidden: !user.isSelfUser
        )
    }

    var userStatusViewOptions: UserStatusView.Options {
        options.contains(.allowEditingAvailability) ? [.allowSettingStatus] : [.hideActionHint]
    }

    init(
        user: UserType,
        viewer: UserType,
        conversation: ZMConversation?,
        options: ProfileHeaderViewController.Options
    ) {
        self.user = user
        self.viewer = viewer
        self.conversation = conversation
        self.options = options
    }

    func availabilitySelected(_ availability: Availability) -> AvailabilitySelectionAction {
        .updateAvailability(availability)
    }

    func qrCodeButtonTapped() -> Route {
        guard
            let profileLink = URL.selfUserProfileLink?.absoluteString.removingPercentEncoding,
            let profileDeepLink = user.profileDeepLink,
            let handle = user.handle
        else {
            return .none
        }

        return .showQRCode(UserQRCodeViewModel(
            profileLink: profileLink,
            profileDeepLink: profileDeepLink,
            handle: handle
        ))
    }

    func isQRCodeButtonHidden(isFeatureEnabled: Bool) -> Bool {
        !user.isSelfUser || !isFeatureEnabled
    }

    private var handleText: String? {
        guard let handle = user.handle, !handle.isEmpty else { return nil }
        return "@\(handle)"
    }

    private var teamNameText: String? {
        guard !options.contains(.hideTeamName) else { return nil }
        return user.teamName
    }

    private var isGuestIndicatorHidden: Bool {
        if let conversation {
            return !user.isGuest(in: conversation)
        } else {
            return !viewer.isTeamMember || viewer.canAccessCompanyInformation(of: user)
        }
    }

    private var isGroupRoleIndicatorHidden: Bool {
        switch conversation?.conversationType {
        case .group?:
            !(conversation.map(user.isGroupAdmin) ?? false)
        default:
            true
        }
    }

    private var isAvailabilityHidden: Bool {
        options.contains(.hideAvailability)
            || !options.contains(.allowEditingAvailability) && user.availability == .none
    }
}
