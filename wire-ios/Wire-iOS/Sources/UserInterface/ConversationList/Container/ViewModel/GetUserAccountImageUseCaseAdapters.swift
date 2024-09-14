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

import WireAccountImage
import WireDataModel
import WireFoundation

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

extension GetUserAccountImageUseCaseProtocol {

    func invoke(account: Account) async throws -> UIImage {
        try await invoke(account: AccountAdapter(account: account))
    }
}

// MARK: -

private struct InitialsProviderAdapter: GetAccountImageUseCaseInitialsProvider {
    @MainActor
    func initials(from fullName: String) -> String {
        PersonName.person(withName: fullName, schemeTagger: nil).initials
    }
}

private struct UserTypeAdapter<User>: GetAccountImageUseCaseUserProtocol where User: UserType {
    private(set) var user: User
    var membership: TeamMembershipAdapter? {
        get async {
            if let user = user as? (NSManagedObject & UserType) {
                await user.managedObjectContext.perform {
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
            await teamMembership.managedObjectContext.perform {
                teamMembership.team.map(TeamAdapter.init(team:))
            }
        }
    }
}

private struct TeamAdapter: GetAccountImageUseCaseTeamProtocol {

    private(set) var team: Team

    var name: String? {
        get async {
            await team.managedObjectContext.perform {
                team.name
            }
        }
    }

    var teamImageSource: AccountImageSource? {
        get async {
            await team.managedObjectContext.perform {
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

// MARK: - Helper

// A little helper to make the code above compacter.
fileprivate extension Optional where Wrapped == NSManagedObjectContext {

    /// If the `managedObjectContext` is non-nil, the provided closure will be wrapped in a call to `.perform`.
    /// Otherwise the closure will be executed synchronously.
    func perform<T>(
        schedule: NSManagedObjectContext.ScheduledTaskType = .immediate,
        _ block: @escaping () throws -> T
    ) async rethrows -> T {

        if let context = self {
            try await context.perform {
                try block()
            }
        } else {
            try block()
        }
    }
}
