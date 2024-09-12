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

import WireDataModel
import WireFoundation
import WireUserProfile

extension GetUserAccountImageUseCase<InitialsProviderAdapter, AccountImageGenerator> {

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

extension GetUserAccountImageUseCaseProtocol {

    func invoke(account: Account) async throws -> UIImage {
        try await invoke(account: AccountAdapter(account: account))
    }
}

private struct UserTypeAdapter<User>: GetAccountImageUseCaseUserProtocol where User: UserType {
    private(set) var user: User
    var membership: TeamMembershipAdapter? {
        get async {
            if let user = user as? (NSManagedObject & UserType), let context = user.managedObjectContext {
                await context.perform {
                    user.membership.map(TeamMembershipAdapter.init(teamMembership:))
                }
            } else {
                user.membership.map(TeamMembershipAdapter.init(teamMembership:))
            }
        }
    }
}

private struct TeamMembershipAdapter: GetAccountImageUseCaseTeamMembershipProtocol {
    private(set) var teamMembership: TeamMembership
    var team: TeamAdapter? {
        get async {
            if let context = teamMembership.managedObjectContext {
                await context.perform {
                    teamMembership.team.map(TeamAdapter.init(team:))
                }
            } else {
                teamMembership.team.map(TeamAdapter.init(team:))
            }
        }
    }
}

private struct TeamAdapter: GetAccountImageUseCaseTeamProtocol {

    private(set) var team: Team

    var name: String? {
        get async {
            if let context = team.managedObjectContext {
                await context.perform {
                    team.name
                }
            } else {
                team.name
            }
        }
    }

    var teamImageSource: AccountImageSource? {
        get async {
            if let context = team.managedObjectContext {
                await context.perform {
                    .init(team.teamImageViewContent)
                }
            } else {
                .init(team.teamImageViewContent)
            }
        }
    }
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
        case .teamName(let initials):
            self = .text(initials: initials)
        }
    }
}
