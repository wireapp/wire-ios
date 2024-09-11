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
import WireFoundation

public struct GetAccountImageUseCase<User, Account, InitalsProvider, AccountImageGenerator>: GetAccountImageUseCaseProtocol
where User: GetAccountImageUseCaseUserProtocol, Account: GetAccountImageUseCaseAccountProtocol, InitalsProvider: GetAccountImageUseCaseInitialsProvider, AccountImageGenerator: AccountImageGeneratorProtocol {

    var user: User // TODO: move into invoke
    var account: Account // TODO: move into invoke
    var initalsProvider: InitalsProvider
    var accountImageGenerator: AccountImageGenerator

    public init(
        user: User,
        account: Account,
        initalsProvider: InitalsProvider,
        accountImageGenerator: AccountImageGenerator
    ) {
        self.user = user
        self.account = account
        self.initalsProvider = initalsProvider
        self.accountImageGenerator = accountImageGenerator
    }

    public func invoke() async -> UIImage {

        if let team = user.membership?.team, let teamImageSource = team.teamImageSource ?? account.teamImageSource {

            // team image
            if case .data(let data) = teamImageSource, let accountImage = UIImage(data: data) {
                return accountImage
            }

            // team name initials
            let teamName: String
            if case .text(let value) = teamImageSource {
                teamName = value
            } else {
                teamName = team.name ?? account.teamName ?? ""
            }
            let initials = teamName.trimmingCharacters(in: .whitespacesAndNewlines).first.map { "\($0)" } ?? ""
            let accountImage = await accountImageGenerator.createImage(initials: initials, backgroundColor: .white)
            return accountImage

        } else {

            // user's custom image
            if let data = account.imageData, let accountImage = UIImage(data: data) {
                return accountImage
            }

            // image base on user's initials
            let initials = initalsProvider.initials(from: account.userName)
            return await accountImageGenerator.createImage(initials: initials, backgroundColor: .white)
        }
    }
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
    var team: Team { get }
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

public protocol GetAccountImageUseCaseInitialsProvider {
    func initials(from fullName: String) -> String
}

/*
func getInitials(from fullName: String) -> String {
    // Split the full name by spaces into an array of words
    let words = fullName.split(separator: " ")

    // Map over each word, take the first character, convert to uppercase, and join them
    let initials = words.compactMap { $0.first?.uppercased() }.joined()

    return initials
}
*/
