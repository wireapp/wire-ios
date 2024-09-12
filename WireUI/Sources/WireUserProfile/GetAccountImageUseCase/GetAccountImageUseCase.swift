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

public struct GetAccountImageUseCase<InitalsProvider, AccountImageGenerator>: GetAccountImageUseCaseProtocol
    where InitalsProvider: GetAccountImageUseCaseInitialsProvider, AccountImageGenerator: AccountImageGeneratorProtocol {

    var initalsProvider: InitalsProvider
    var accountImageGenerator: AccountImageGenerator

    public init(
        initalsProvider: InitalsProvider,
        accountImageGenerator: AccountImageGenerator
    ) {
        self.initalsProvider = initalsProvider
        self.accountImageGenerator = accountImageGenerator
    }

    public func invoke(user: some GetAccountImageUseCaseUserProtocol, account: some GetAccountImageUseCaseAccountProtocol) async -> UIImage {
        if let team = user.membership?.team, let teamImageSource = team.teamImageSource ?? account.teamImageSource {
            // team image
            if case .data(let data) = teamImageSource, let accountImage = UIImage(data: data) {
                return accountImage
            }

            // team name initials
            let teamName: String = if case .text(let value) = teamImageSource {
                value
            } else {
                team.name ?? account.teamName ?? ""
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

// The following protocol serves the purpose of decoupling the use case from the actual dependencies.

public protocol GetAccountImageUseCaseInitialsProvider {
    func initials(from fullName: String) -> String
}
