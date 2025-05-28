//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import XCTest

final class PersonalUsersTests: WireUITestCase {

    @MainActor
    func test_Register_asPersonalUser() async throws {
        let user = UserGenerator.generateUniqueUserInfo()

        let page = WelcomePage()
            .typeEmailOrSSO(user.email)
            .tapCreatePersonalAccountLink()
            .tapConfirmCreateAccount()
            .tapAcceptButton()

        let verificationCode = try await InbucketClient.getVerificationCode(email: user.email)

        let accountPage = page
            .enterVerificationCode(verificationCode)
            .setName(user.name)
            .setPassword(user.password)
            .acceptPopup()
            .setUsername(user.username)
            .openSettings()
            .openAccountSettings()

        XCTAssertTrue(accountPage.getAccountName().elementsEqual(user.name), "Account name didn't match \(user.name)")
        XCTAssertTrue(accountPage.getUsername().contains(user.username), "Username didn't contain \(user.username)")
        XCTAssertTrue(accountPage.getEmail().elementsEqual(user.email))

        accountPage.logout()
            .enterPassword(user.password)
    }
}
