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

public struct GetUserAccountImageUseCase<InitalsProvider, AccountImageGenerator>: GetUserAccountImageUseCaseProtocol
where InitalsProvider: GetAccountImageUseCaseInitialsProvider, AccountImageGenerator: AccountImageGeneratorProtocol {

    typealias Error = GetUserAccountImageUseCaseError

    var initalsProvider: InitalsProvider
    var accountImageGenerator: AccountImageGenerator

    public init(
        initalsProvider: InitalsProvider,
        accountImageGenerator: AccountImageGenerator
    ) {
        self.initalsProvider = initalsProvider
        self.accountImageGenerator = accountImageGenerator
    }

    public func invoke(account: some GetAccountImageUseCaseAccountProtocol) async throws -> UIImage {

        // user's custom image
        if let data = account.imageData, let accountImage = UIImage(data: data) {
            return accountImage
        }

        // image base on user's initials
        let initials = initalsProvider.initials(from: account.userName).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !initials.isEmpty else { throw Error.invalidImageSource }
        return await accountImageGenerator.createImage(initials: initials, backgroundColor: .white)
    }
}

enum GetUserAccountImageUseCaseError: Error {
    /// Neither valid image data nor a non-empty string has been provided for getting an account image.
    case invalidImageSource
}
