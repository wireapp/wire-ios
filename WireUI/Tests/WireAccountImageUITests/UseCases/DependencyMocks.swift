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

import WireAccountImageUI
import WireFoundation
import XCTest

final class MockUser: GetAccountImageUseCaseUserProtocol {
    var membership: MockTeamMembership? = .init()
}

struct MockTeamMembership: GetAccountImageUseCaseTeamMembershipProtocol {
    var team: MockTeam? = .init()
}

struct MockTeam: GetAccountImageUseCaseTeamProtocol {
    var name: String?
    var teamImageSource: AccountImageSource?
}

final class MockAccount: GetAccountImageUseCaseAccountProtocol {
    var imageData: Data?
    var userName = ""
    var teamName: String?
    var teamImageSource: AccountImageSource?
}

final class MockInitialsProvider: GetAccountImageUseCaseInitialsProvider {
    var initialsResult = ""
    func initials(from userName: String) -> String { initialsResult }
}

final class MockAccountImageGenerator: AccountImageGeneratorProtocol {
    var createImage_Invocations = [(initials: String, backgroundColor: UIColor)]()
    var resultImage = UIImage()
    func createImage(initials: String, backgroundColor: UIColor) async -> UIImage {
        createImage_Invocations += [(initials, backgroundColor)]
        return resultImage
    }
}
