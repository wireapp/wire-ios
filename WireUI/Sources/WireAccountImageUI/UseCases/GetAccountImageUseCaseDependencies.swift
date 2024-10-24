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

import Foundation

/// An abstraction of a user for the account image use cases.
public protocol GetAccountImageUseCaseUserProtocol: Sendable {
    associatedtype TeamMembership: GetAccountImageUseCaseTeamMembershipProtocol
    var membership: TeamMembership? { get async }
}

/// An abstraction of a user's team membership for the account image use cases.
public protocol GetAccountImageUseCaseTeamMembershipProtocol {
    associatedtype Team: GetAccountImageUseCaseTeamProtocol
    var team: Team? { get async }
}

/// An abstraction of a user's team for the account image use cases.
public protocol GetAccountImageUseCaseTeamProtocol {
    var name: String? { get async }
    var teamImageSource: AccountImageSource? { get async }
}

/// An abstraction of a user account for the account image use cases.
@MainActor
public protocol GetAccountImageUseCaseAccountProtocol: Sendable {
    var imageData: Data? { get }
    var userName: String { get }
    var teamName: String? { get }
    var teamImageSource: AccountImageSource? { get }
}

public protocol GetAccountImageUseCaseInitialsProvider {
    func initials(from fullName: String) async -> String
}
