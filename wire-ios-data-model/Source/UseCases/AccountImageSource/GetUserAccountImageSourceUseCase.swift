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

public struct GetUserAccountImageSourceUseCase: GetUserAccountImageSourceUseCaseProtocol {

    typealias Error = GetUserAccountImageUseCaseError

    public init() {}

    public func invoke(
        user: some UserType,
        userContext: NSManagedObjectContext?,
        account: Account
    ) async throws -> AccountImageSource {

        // user's custom image
        if let data = account.imageData, let accountImage = UIImage(data: data) {
            return .image(accountImage)
        }

        // initials base on value stored in user
        var initials = await userContext?.perform { user.initials } ?? ""
        initials = initials.trimmingCharacters(in: .whitespacesAndNewlines)
        if !initials.isEmpty {
            return .text(initials)
        }

        // initials base on the account name
        initials = PersonName.person(withName: account.userName, schemeTagger: nil).initials
        initials = initials.trimmingCharacters(in: .whitespacesAndNewlines)
        if !initials.isEmpty {
            return .text(initials)
        }

        throw Error.invalidImageSource
    }
}

enum GetUserAccountImageUseCaseError: Error {
    /// Neither valid image data nor a non-empty string has been provided for getting an account image source.
    case invalidImageSource
}
