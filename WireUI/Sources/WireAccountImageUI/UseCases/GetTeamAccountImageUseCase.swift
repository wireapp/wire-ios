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

public struct GetTeamAccountImageUseCase: GetTeamAccountImageUseCaseProtocol {

    typealias Error = GetTeamAccountImageUseCaseError

    public init() {}

    public func invoke(
        user: some GetAccountImageUseCaseUserProtocol,
        account: some GetAccountImageUseCaseAccountProtocol
    ) async throws -> UIImage {
        var teamName = ""
        var teamImageSource = await user.membership?.team?.teamImageSource
        if teamImageSource == nil {
            teamImageSource = await account.teamImageSource
        }
        if let teamImageSource {
            // team image
            if case .data(let data) = teamImageSource, let accountImage = UIImage(data: data) {
                return accountImage
            }

            // team name initials
            if case .text(let value) = teamImageSource {
                teamName = value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // TODO: move into separate use case
//        var alternativeTeamName = await user.membership?.team?.name
//        if alternativeTeamName == nil {
//            alternativeTeamName = await account.teamName
//        }
//        if teamName.isEmpty, let alternativeTeamName {
//            teamName = alternativeTeamName.trimmingCharacters(in: .whitespacesAndNewlines)
//        }
//
//        if !teamName.isEmpty, let initials = teamName.trimmingCharacters(in: .whitespacesAndNewlines).first.map({ "\($0)" }), !initials.isEmpty {
//            return await accountImageGenerator.createImage(initials: initials)
//        }

        throw Error.invalidImageSource
    }
}

enum GetTeamAccountImageUseCaseError: Error {
    /// Neither valid image data nor a non-empty string has been provided for getting an account image.
    case invalidImageSource
}
