//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import WireFoundation
import WireUserProfile
import WireDataModel

extension GetAccountImageUseCase<InitialsProviderAdapter, AccountImageGenerator> {

    @MainActor
    init() {
        self.init(
            initalsProvider: .init(),
            accountImageGenerator: .init()
        )
    }
}

// MARK: -

private struct InitialsProviderAdapter: GetAccountImageUseCaseInitialsProvider {
    func initials(from fullName: String) -> String {
        PersonName.person(withName: fullName, schemeTagger: nil).initials
    }
}

// MARK: -

extension GetAccountImageUseCaseProtocol {

    func invoke(
        user: some UserType,
        account: Account
    ) async -> UIImage {
        await invoke(
            user: UserTypeAdapter(user: user),
            account: AccountAdapter(account: account)
        )
    }
}

private struct UserTypeAdapter<User>: GetAccountImageUseCaseUserProtocol where User: UserType {
    private(set) var user: User
    var membership: TeamMembershipAdapter? { user.membership.map(TeamMembershipAdapter.init(teamMembership:)) }
}

private struct TeamMembershipAdapter: GetAccountImageUseCaseTeamMembershipProtocol {
    private(set) var teamMembership: TeamMembership
    var team: TeamAdapter? { teamMembership.team.map(TeamAdapter.init(team:)) }
}

private struct TeamAdapter: GetAccountImageUseCaseTeamProtocol {
    private(set) var team: Team
    var name: String? { team.name }
    var teamImageSource: AccountImageSource? { .init(team.teamImageViewContent) }
}

private struct AccountAdapter: GetAccountImageUseCaseAccountProtocol {
    private(set) var account: Account
    var imageData: Data? { account.imageData }
    var userName: String { account.userName }
    var teamName: String? { account.teamName }
    var teamImageSource: AccountImageSource? { .init(account.teamImageViewContent) }
}

private extension AccountImageSource {
    init?(_ teamImageViewContent: TeamImageView.Content?) {
        guard let teamImageViewContent else { return nil }
        switch teamImageViewContent {
        case .teamImage(let data):
            self = .data(data)
        case .teamName(let string):
            self = .text(string)
        }
    }
}
