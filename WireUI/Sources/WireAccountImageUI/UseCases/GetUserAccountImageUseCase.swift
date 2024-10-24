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

public struct GetUserAccountImageUseCase<InitalsProvider: GetAccountImageUseCaseInitialsProvider>: GetUserAccountImageUseCaseProtocol {

    // MARK: - Internal Properties

    var initalsProvider: InitalsProvider

    // MARK: - Life Cycle

    public init(initalsProvider: InitalsProvider) {
        self.initalsProvider = initalsProvider
    }

    // MARK: - Methods

    public func invoke(
        account: some GetAccountImageUseCaseAccountProtocol
    ) async throws -> UIImage? {
        // user's custom image
        if let data = await account.imageData, let accountImage = UIImage(data: data) {
            return accountImage
        }
        return nil

        // image base on user's initials
//        let initials = await initalsProvider.initials(from: account.userName)
//            .trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !initials.isEmpty else { throw Error.invalidImageSource }
//        return await accountImageGenerator.createImage(initials: initials)
    }
}
