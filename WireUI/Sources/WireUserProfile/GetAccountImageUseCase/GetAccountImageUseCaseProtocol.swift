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

import UIKit

/// Determines if the provided user is a personal user or a team member and retrieves its
/// account image. If no account image data is available, an image will be generated using
/// the initials of either the team name or the person's name.
public protocol GetAccountImageUseCaseProtocol {

    func invoke<User, Account>(user: User, account: Account) async -> UIImage
        where User: GetAccountImageUseCaseUserProtocol, Account: GetAccountImageUseCaseAccountProtocol
}

// MARK: - Dependencies

// The following protocols serve the purpose of decoupling the use case from the actual dependencies.

/// An abstraction of a user for the `GetAccountImageUseCase`.
public protocol GetAccountImageUseCaseUserProtocol {
    associatedtype TeamMembership: GetAccountImageUseCaseTeamMembershipProtocol
    var membership: TeamMembership? { get }
}

/// An abstraction of a user's team membership for the `GetAccountImageUseCase`.
public protocol GetAccountImageUseCaseTeamMembershipProtocol {
    associatedtype Team: GetAccountImageUseCaseTeamProtocol
    var team: Team? { get }
}

/// An abstraction of a user's team for the `GetAccountImageUseCase`.
public protocol GetAccountImageUseCaseTeamProtocol {
    var name: String? { get }
    var teamImageSource: AccountImageSource? { get }
}

/// An abstraction of a user account for the `GetAccountImageUseCase`.
public protocol GetAccountImageUseCaseAccountProtocol {
    var imageData: Data? { get }
    var userName: String { get }
    var teamName: String? { get }
    var teamImageSource: AccountImageSource? { get }
}
