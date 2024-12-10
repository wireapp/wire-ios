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

import CoreData
import UIKit
import WireFoundation

public struct GetTeamAccountImageSourceUseCase: GetTeamAccountImageSourceUseCaseProtocol {

    typealias Error = GetTeamAccountImageSourceUseCaseError

    public init() {}

    public func invoke(
        user: some UserType,
        userContext: NSManagedObjectContext?,
        account: Account
    ) async throws -> AccountImageSource {

        var (teamName, teamImageData) = await userContext?.perform {
            let team = user.membership?.team
            return (team?.name, team?.imageData)
        } ?? (nil, nil)

        // team image data stored in the user's team or the account
        teamImageData = teamImageData ?? account.teamImageData
        if let teamImageData, let image = UIImage(data: teamImageData) {
            return .image(image)
        }

        // initials based on team name stored in account
        if let teamName = account.teamName?.trimmingCharacters(in: .whitespacesAndNewlines),
           let initials = teamName.first.map({ "\($0)" }),
           !initials.isEmpty {
            return .text(initials)
        }

        // initials based on team name stored in the team
        if let teamName = teamName?.trimmingCharacters(in: .whitespacesAndNewlines),
           let initials = teamName.first.map({ "\($0)" }),
           !initials.isEmpty {
            return .text(initials)
        }

        throw Error.invalidImageSource
    }
}

enum GetTeamAccountImageSourceUseCaseError: Error {
    /// Neither valid image data nor a non-empty string has been provided for getting an account image source.
    case invalidImageSource
}
