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

import WireDesign
import WireFoundation
import WireNetwork
import WireSyncEngine
import WireUtilities

final class SelfProfileViewModel {

    struct TeamMigrationBannerPresentation {
        let apiVersion: WireNetwork.APIVersion
        let accentColor: WireAccentColor
    }

    enum AccountSwitcherAction {
        case addAccount
        case manageTeam
    }

    struct AccountSwitcherPresentation {
        let otherAccounts: [Account]
        let visibleActions: [AccountSwitcherAction]
    }

    let profileHeaderOptions: ProfileHeaderViewController.Options
    let teamMigrationBannerPresentation: TeamMigrationBannerPresentation?
    let accountSwitcherPresentation: AccountSwitcherPresentation
    let isProfilePictureEditingEnabled: Bool

    init(
        selfUser: SettingsSelfUser,
        userRightInterfaceType: UserRightInterface.Type,
        backendAPIVersionRawValue: UInt?,
        canManageTeam: Bool,
        accounts: [Account],
        selectedAccount: Account?
    ) {
        isProfilePictureEditingEnabled = userRightInterfaceType.selfUserIsPermitted(to: .editProfilePicture)
        profileHeaderOptions = SelfProfileViewModel.profileHeaderOptions(
            isTeamMember: selfUser.isTeamMember,
            isProfilePictureEditingEnabled: isProfilePictureEditingEnabled
        )
        teamMigrationBannerPresentation = SelfProfileViewModel.teamMigrationBannerPresentation(
            isTeamMember: selfUser.isTeamMember,
            backendAPIVersionRawValue: backendAPIVersionRawValue,
            accentColorValue: selfUser.accentColorValue
        )
        accountSwitcherPresentation = SelfProfileViewModel.accountSwitcherPresentation(
            canManageTeam: canManageTeam,
            accounts: accounts,
            selectedAccount: selectedAccount
        )
    }

    private static func profileHeaderOptions(
        isTeamMember: Bool,
        isProfilePictureEditingEnabled: Bool
    ) -> ProfileHeaderViewController.Options {
        var options: ProfileHeaderViewController.Options = isTeamMember ? [.allowEditingAvailability] : [.hideAvailability]
        if isProfilePictureEditingEnabled {
            options.insert(.allowEditingProfilePicture)
        }
        return options
    }

    private static func teamMigrationBannerPresentation(
        isTeamMember: Bool,
        backendAPIVersionRawValue: UInt?,
        accentColorValue: ZMAccentColorRawValue
    ) -> TeamMigrationBannerPresentation? {
        guard
            !isTeamMember,
            let backendAPIVersionRawValue,
            let apiVersion = WireNetwork.APIVersion(rawValue: backendAPIVersionRawValue),
            apiVersion >= .v7
        else {
            return nil
        }

        return TeamMigrationBannerPresentation(
            apiVersion: apiVersion,
            accentColor: WireAccentColor(rawValue: accentColorValue) ?? .default
        )
    }

    private static func accountSwitcherPresentation(
        canManageTeam: Bool,
        accounts: [Account],
        selectedAccount: Account?
    ) -> AccountSwitcherPresentation {
        var visibleActions: [AccountSwitcherAction] = [.addAccount]
        if canManageTeam {
            visibleActions.append(.manageTeam)
        }

        return AccountSwitcherPresentation(
            otherAccounts: accounts.filter { !$0.isEqual(selectedAccount) },
            visibleActions: visibleActions
        )
    }
}
