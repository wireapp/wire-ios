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

import WireSyncEngine

struct SearchUserViewModel {

    enum DisplayState: Equatable {
        case loading
    }

    struct AlertContent: Equatable {
        let title: String
        let message: String
        let buttonTitle: String
    }

    struct ProfileRoute {
        let user: any UserType
        let viewer: any UserType
    }

    enum Action {
        case showProfile(ProfileRoute)
        case showInvalidUser(AlertContent)
        case assertMissingSelfUser(String)
        case ignore
    }

    struct LookupResult {
        let directoryUsers: [any UserType]
        let teamMemberUsers: [any UserType]

        init(
            directoryUsers: [any UserType],
            teamMemberUsers: [any UserType]
        ) {
            self.directoryUsers = directoryUsers
            self.teamMemberUsers = teamMemberUsers
        }

        init(searchResult: SearchResult) {
            self.init(
                directoryUsers: searchResult.directory.map { $0 as any UserType },
                teamMemberUsers: searchResult.teamMembers.first?.user.map { [$0 as any UserType] } ?? []
            )
        }
    }

    private(set) var displayState: DisplayState = .loading
    private(set) var hasHandledResult = false

    var closeButtonAccessibilityLabel: String {
        L10n.Localizable.General.cancel
    }

    mutating func action(
        for searchResult: SearchResult,
        viewer: (any UserType)?
    ) -> Action {
        action(for: LookupResult(searchResult: searchResult), viewer: viewer)
    }

    mutating func action(
        for lookupResult: LookupResult,
        viewer: (any UserType)?
    ) -> Action {
        guard !hasHandledResult else { return .ignore }

        guard let viewer else {
            return .assertMissingSelfUser("ZMUser.selfUser() is nil")
        }

        if let profileUser = profileUser(from: lookupResult) {
            hasHandledResult = true
            return .showProfile(ProfileRoute(user: profileUser, viewer: viewer))
        }

        return .showInvalidUser(invalidUserAlertContent)
    }

    private var invalidUserAlertContent: AlertContent {
        AlertContent(
            title: L10n.Localizable.UrlAction.InvalidUser.title,
            message: L10n.Localizable.UrlAction.InvalidUser.message,
            buttonTitle: L10n.Localizable.General.ok
        )
    }

    private func profileUser(from lookupResult: LookupResult) -> (any UserType)? {
        if let directoryUser = lookupResult.directoryUsers.first, !directoryUser.isAccountDeleted {
            return directoryUser
        }

        if let memberUser = lookupResult.teamMemberUsers.first, !memberUser.isAccountDeleted {
            return memberUser
        }

        return nil
    }
}
